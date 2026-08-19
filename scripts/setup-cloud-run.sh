#!/bin/bash
# Creates all 32 Cloud Run services (16 dev + 16 prod) with placeholder images.
# CI/CD will replace the placeholder with real images after the first push.
#
# Prerequisites: setup-artifact-registry.sh must have been run first.
#
# Usage:
#   chmod +x setup-cloud-run.sh
#   ./setup-cloud-run.sh

set -euo pipefail

DEV_PROJECT="digi-carts-dev"
PROD_PROJECT="digi-carts"
REGION="us-east1"
PLACEHOLDER="us-docker.pkg.dev/cloudrun/container/hello"

# Java backend services — 768Mi RAM (Spring Boot overhead)
JAVA_SERVICES=(
  auth-service
  platform-service
  notification-service
  catalog-service
  order-service
  payment-service
  shipping-service
  store-service
  storefront-service
  offer-service
  billing-service
  audit-log-service
)

# Spring Cloud Gateway — lighter than full Spring Boot
GATEWAY_SERVICE="api-gateway"

# Next.js frontends — 256Mi RAM
FRONTEND_SERVICES=(merchant-ui platform-ui storefront)

# ─── helpers ─────────────────────────────────────────────────────────────────

service_port() {
  local SVC=$1
  case "$SVC" in
    api-gateway)       echo 3000 ;;
    auth-service)      echo 3001 ;;
    catalog-service)   echo 3002 ;;
    order-service)     echo 3003 ;;
    payment-service)   echo 3004 ;;
    platform-service)  echo 3005 ;;
    notification-service) echo 3006 ;;
    shipping-service)  echo 3007 ;;
    store-service)     echo 3008 ;;
    storefront-service) echo 3009 ;;
    offer-service)     echo 3010 ;;
    billing-service)   echo 3011 ;;
    audit-log-service) echo 3012 ;;
    merchant-ui)       echo 3000 ;;
    platform-ui)       echo 3000 ;;
    storefront)        echo 3000 ;;
    *)                 echo 8080 ;;
  esac
}

is_public() {
  # api-gateway and all frontends accept unauthenticated requests
  case "$1" in
    api-gateway|merchant-ui|platform-ui|storefront) return 0 ;;
    *) return 1 ;;
  esac
}

create_service() {
  local SVC=$1
  local NAME=$2
  local PROJECT=$3
  local ENV=$4
  local MEMORY=$5
  local DB_SCHEMA=$6

  local PORT
  PORT=$(service_port "$SVC")

  local AUTH_FLAG="--no-allow-unauthenticated"
  is_public "$SVC" && AUTH_FLAG="--allow-unauthenticated"

  # Base env vars (placeholders — update after provisioning DB/secrets)
  # Note: PORT is set automatically by Cloud Run — do not include it here
  local -a ENV_PARTS=()
  if [[ "$DB_SCHEMA" != "none" ]]; then
    if [ "$ENV" = "dev" ]; then
      ENV_PARTS+=("DATABASE_URL=jdbc:postgresql://REPLACE_DB_HOST/digicarts_dev?currentSchema=${DB_SCHEMA}")
    else
      ENV_PARTS+=("DATABASE_URL=jdbc:postgresql://REPLACE_DB_HOST/digicarts?currentSchema=${DB_SCHEMA}")
    fi
  fi
  if [[ "$SVC" == "api-gateway" || "$SVC" == "auth-service" ]]; then
    ENV_PARTS+=("JWT_SECRET=REPLACE_JWT_SECRET")
  fi
  if [[ "$SVC" == "api-gateway" ]]; then
    local BASE_URL
    if [ "$ENV" = "dev" ]; then
      BASE_URL="https://digi-cart-SVC-dev-REPLACE.a.run.app"
    else
      BASE_URL="https://digi-cart-SVC-REPLACE.a.run.app"
    fi
    ENV_PARTS+=("AUTH_SERVICE_URL=${BASE_URL/SVC/auth-service}")
    ENV_PARTS+=("CATALOG_SERVICE_URL=${BASE_URL/SVC/catalog-service}")
    ENV_PARTS+=("ORDER_SERVICE_URL=${BASE_URL/SVC/order-service}")
    ENV_PARTS+=("PAYMENT_SERVICE_URL=${BASE_URL/SVC/payment-service}")
    ENV_PARTS+=("PLATFORM_SERVICE_URL=${BASE_URL/SVC/platform-service}")
    ENV_PARTS+=("NOTIFICATION_SERVICE_URL=${BASE_URL/SVC/notification-service}")
    ENV_PARTS+=("SHIPPING_SERVICE_URL=${BASE_URL/SVC/shipping-service}")
    ENV_PARTS+=("STORE_SERVICE_URL=${BASE_URL/SVC/store-service}")
    ENV_PARTS+=("STOREFRONT_SERVICE_URL=${BASE_URL/SVC/storefront-service}")
    ENV_PARTS+=("OFFER_SERVICE_URL=${BASE_URL/SVC/offer-service}")
    ENV_PARTS+=("BILLING_SERVICE_URL=${BASE_URL/SVC/billing-service}")
    ENV_PARTS+=("AUDIT_LOG_SERVICE_URL=${BASE_URL/SVC/audit-log-service}")
  fi
  if [[ "$SVC" == "merchant-ui" || "$SVC" == "platform-ui" || "$SVC" == "storefront" ]]; then
    if [ "$ENV" = "dev" ]; then
      ENV_PARTS+=("NEXT_PUBLIC_API_URL=https://digi-cart-api-gateway-dev-REPLACE.a.run.app")
    else
      ENV_PARTS+=("NEXT_PUBLIC_API_URL=https://digi-cart-api-gateway-REPLACE.a.run.app")
    fi
    ENV_PARTS+=("NEXTAUTH_SECRET=REPLACE_NEXTAUTH_SECRET")
    ENV_PARTS+=("NEXTAUTH_URL=https://REPLACE.a.run.app")
  fi

  local ENV_VARS
  ENV_VARS=$(IFS=','; echo "${ENV_PARTS[*]}")

  echo "  → $NAME ($MEMORY, port $PORT)"

  local SET_ENV_FLAG=()
  [ -n "$ENV_VARS" ] && SET_ENV_FLAG=("--set-env-vars=$ENV_VARS")

  gcloud run deploy "$NAME" \
    --image="$PLACEHOLDER" \
    --region="$REGION" \
    --project="$PROJECT" \
    --port="$PORT" \
    --memory="$MEMORY" \
    --cpu=1 \
    --min-instances=0 \
    --max-instances=3 \
    "${SET_ENV_FLAG[@]}" \
    $AUTH_FLAG \
    --quiet
}

schema_for() {
  local SVC=$1
  case "$SVC" in
    auth-service)         echo "auth_svc" ;;
    catalog-service)      echo "catalog_svc" ;;
    order-service)        echo "order_svc" ;;
    payment-service)      echo "payment_svc" ;;
    platform-service)     echo "platform_svc" ;;
    notification-service) echo "notification_svc" ;;
    shipping-service)     echo "shipping_svc" ;;
    store-service)        echo "store_svc" ;;
    storefront-service)   echo "storefront_svc" ;;
    offer-service)        echo "offer_svc" ;;
    billing-service)      echo "billing_svc" ;;
    audit-log-service)    echo "audit_log_svc" ;;
    *)                    echo "none" ;;
  esac
}

deploy_env() {
  local ENV=$1
  local PROJECT=$2
  local SUFFIX=$3

  echo ""
  echo "══════════════════════════════════════════════════"
  echo "  Creating Cloud Run services — $ENV ($PROJECT)"
  echo "══════════════════════════════════════════════════"

  gcloud config set project "$PROJECT" --quiet

  # api-gateway
  create_service "api-gateway" "digi-cart-api-gateway${SUFFIX}" "$PROJECT" "$ENV" "512Mi" "none"

  # Java backend services
  for SVC in "${JAVA_SERVICES[@]}"; do
    SCHEMA=$(schema_for "$SVC")
    create_service "$SVC" "digi-cart-${SVC}${SUFFIX}" "$PROJECT" "$ENV" "768Mi" "$SCHEMA"
  done

  # Frontend services
  for SVC in "${FRONTEND_SERVICES[@]}"; do
    create_service "$SVC" "digi-cart-${SVC}${SUFFIX}" "$PROJECT" "$ENV" "256Mi" "none"
  done

  echo ""
  echo "  ✅ $ENV services created"
  echo ""
  echo "  ⚠️  NEXT: Update placeholder env vars via Cloud Console or:"
  echo "     gcloud run services update SERVICE --region $REGION --project $PROJECT \\"
  echo "       --set-env-vars KEY=VALUE"
  echo ""
  echo "  Service URLs (run after creation to get real URLs):"
  gcloud run services list \
    --project="$PROJECT" \
    --region="$REGION" \
    --format="table(SERVICE,URL)" 2>/dev/null || true
}

print_summary() {
  echo ""
  echo "══════════════════════════════════════════════════"
  echo "  ✅  All 32 Cloud Run services created"
  echo ""
  echo "  ⚠️  Required follow-up steps:"
  echo ""
  echo "  1. Provision Cloud SQL PostgreSQL instances:"
  echo "     Dev  project: digi-carts-dev  → DB name: digicarts_dev"
  echo "     Prod project: digi-carts       → DB name: digicarts"
  echo ""
  echo "  2. Update DATABASE_URL on all backend services with real DB host"
  echo "     (use Cloud SQL Auth Proxy connection string or private IP)"
  echo ""
  echo "  3. Set JWT_SECRET on api-gateway and auth-service (same value)"
  echo ""
  echo "  4. Update *_SERVICE_URL env vars on api-gateway with real Cloud Run URLs"
  echo "     (run: gcloud run services describe SERVICE --region $REGION --format='value(status.url)')"
  echo ""
  echo "  5. Update NEXT_PUBLIC_API_URL on merchant-ui, platform-ui, storefront"
  echo ""
  echo "  6. Push a commit to 'stage' on any repo to trigger first CI build"
  echo ""
  echo "  Run script: doc/scripts/update-service-urls.sh  (coming next)"
  echo "══════════════════════════════════════════════════"
}

# ─── main ────────────────────────────────────────────────────────────────────

if ! command -v gcloud &>/dev/null; then
  echo "ERROR: gcloud CLI not found."
  exit 1
fi

deploy_env "dev"  "$DEV_PROJECT"  "-dev"
deploy_env "prod" "$PROD_PROJECT" ""

print_summary
