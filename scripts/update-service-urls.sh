#!/bin/bash
# Reads real Cloud Run URLs and updates all env vars on every service.
# Run this AFTER setup-cloud-sql.sh has provisioned the DB instances.
#
# What it does:
#   1. Fetches real Cloud Run URLs for all 16 services in each project
#   2. Updates api-gateway *_SERVICE_URL env vars
#   3. Updates NEXT_PUBLIC_API_URL on the three frontends
#   4. Sets DATABASE_URL on all 12 backend services
#   5. Sets JWT_SECRET on api-gateway + auth-service
#
# Usage:
#   chmod +x update-service-urls.sh
#   ./update-service-urls.sh

set -euo pipefail

DEV_PROJECT="digi-carts-dev"
PROD_PROJECT="digi-carts"
REGION="us-east1"

BACKEND_SERVICES=(
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

FRONTEND_SERVICES=(merchant-ui platform-ui storefront)

GATEWAY_ROUTES=(
  auth-service
  catalog-service
  order-service
  payment-service
  platform-service
  notification-service
  shipping-service
  store-service
  storefront-service
  offer-service
  billing-service
  audit-log-service
)

# ─── prompt for secrets ───────────────────────────────────────────────────────

read -r -s -p "Enter JWT_SECRET (strong random string, same for api-gateway + auth-service): " JWT_SECRET
echo ""
if [ -z "$JWT_SECRET" ]; then
  echo "ERROR: JWT_SECRET cannot be empty"
  exit 1
fi

read -r -s -p "Enter DB password (same as used in setup-cloud-sql.sh): " DB_PASSWORD
echo ""
if [ -z "$DB_PASSWORD" ]; then
  echo "ERROR: DB password cannot be empty"
  exit 1
fi

# ─── helpers ─────────────────────────────────────────────────────────────────

get_url() {
  local PROJECT=$1
  local SERVICE=$2
  gcloud run services describe "$SERVICE" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="value(status.url)" 2>/dev/null || echo ""
}

get_connection_name() {
  local PROJECT=$1
  local INSTANCE=$2
  gcloud sql instances describe "$INSTANCE" \
    --project="$PROJECT" \
    --format="value(connectionName)" 2>/dev/null || echo ""
}

db_url() {
  local CONN_NAME=$1
  local DB=$2
  local SCHEMA=$3
  echo "jdbc:postgresql:///${DB}?cloudSqlInstance=${CONN_NAME}&socketFactory=com.google.cloud.sql.postgres.SocketFactory&user=digicart&password=${DB_PASSWORD}&currentSchema=${SCHEMA}"
}

schema_for() {
  case "$1" in
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
  esac
}

update_env() {
  local ENV=$1
  local PROJECT=$2
  local SUFFIX=$3
  local DB_INSTANCE=$4
  local DB_NAME=$5

  echo ""
  echo "══════════════════════════════════════════════════"
  echo "  Updating Cloud Run env vars — $ENV ($PROJECT)"
  echo "══════════════════════════════════════════════════"

  gcloud config set project "$PROJECT" --quiet

  # Fetch all URLs into a temp file: "service-name URL"
  local URL_FILE
  URL_FILE=$(mktemp)
  echo "→ Fetching service URLs..."
  for SVC in api-gateway "${BACKEND_SERVICES[@]}" "${FRONTEND_SERVICES[@]}"; do
    NAME="digi-cart-${SVC}${SUFFIX}"
    URL=$(get_url "$PROJECT" "$NAME")
    echo "${SVC} ${URL}" >> "$URL_FILE"
    echo "  $NAME → ${URL:-NOT FOUND}"
  done

  # Helper: look up a URL from the temp file
  svc_url() { grep "^$1 " "$URL_FILE" | awk '{print $2}'; }

  # Get Cloud SQL connection name
  local CONN_NAME
  CONN_NAME=$(get_connection_name "$PROJECT" "$DB_INSTANCE")
  echo "  Cloud SQL : $CONN_NAME"

  # ── api-gateway: JWT + all service URLs ──────────────────────────────────
  echo ""
  echo "→ Updating api-gateway..."
  local GW_VARS="JWT_SECRET=${JWT_SECRET}"
  for ROUTE in "${GATEWAY_ROUTES[@]}"; do
    local KEY
    KEY=$(echo "${ROUTE}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    GW_VARS="${GW_VARS},${KEY}_URL=$(svc_url "$ROUTE")"
  done
  gcloud run services update "digi-cart-api-gateway${SUFFIX}" \
    --region="$REGION" --project="$PROJECT" \
    --set-env-vars="$GW_VARS" \
    --quiet
  echo "  ✓ api-gateway updated"

  # ── auth-service: JWT + DB ────────────────────────────────────────────────
  echo "→ Updating auth-service..."
  gcloud run services update "digi-cart-auth-service${SUFFIX}" \
    --region="$REGION" --project="$PROJECT" \
    --add-cloudsql-instances="$CONN_NAME" \
    --set-env-vars="JWT_SECRET=${JWT_SECRET},DATABASE_URL=$(db_url "$CONN_NAME" "$DB_NAME" "auth_svc")" \
    --quiet
  echo "  ✓ auth-service updated"

  # ── remaining backend services: DB only ──────────────────────────────────
  for SVC in "${BACKEND_SERVICES[@]}"; do
    [ "$SVC" = "auth-service" ] && continue
    local SCHEMA
    SCHEMA=$(schema_for "$SVC")
    echo "→ Updating ${SVC}..."
    gcloud run services update "digi-cart-${SVC}${SUFFIX}" \
      --region="$REGION" --project="$PROJECT" \
      --add-cloudsql-instances="$CONN_NAME" \
      --set-env-vars="DATABASE_URL=$(db_url "$CONN_NAME" "$DB_NAME" "$SCHEMA")" \
      --quiet
    echo "  ✓ ${SVC} updated"
  done

  # ── frontends: NEXT_PUBLIC_API_URL ────────────────────────────────────────
  local GW_URL
  GW_URL=$(svc_url "api-gateway")
  for SVC in "${FRONTEND_SERVICES[@]}"; do
    echo "→ Updating ${SVC}..."
    local SVC_URL
    SVC_URL=$(svc_url "$SVC")
    gcloud run services update "digi-cart-${SVC}${SUFFIX}" \
      --region="$REGION" --project="$PROJECT" \
      --set-env-vars="NEXT_PUBLIC_API_URL=${GW_URL},NEXTAUTH_SECRET=${JWT_SECRET},NEXTAUTH_URL=${SVC_URL}" \
      --quiet
    echo "  ✓ ${SVC} updated"
  done

  rm -f "$URL_FILE"
  echo ""
  echo "  ✅ $ENV env vars updated"
}

# ─── main ────────────────────────────────────────────────────────────────────

if ! command -v gcloud &>/dev/null; then
  echo "ERROR: gcloud CLI not found."
  exit 1
fi

update_env "dev"  "$DEV_PROJECT"  "-dev" "digi-carts-dev-db" "digicarts_dev"
update_env "prod" "$PROD_PROJECT" ""     "digi-carts-db"     "digicarts"

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅  All services configured"
echo ""
echo "  Next: push a commit to 'stage' on any repo to"
echo "  trigger the first CI build and deploy real images"
echo "══════════════════════════════════════════════════"
