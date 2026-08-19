#!/bin/bash
# Provisions Cloud SQL PostgreSQL 15 instances for digi-carts dev and prod.
# Creates DB instances, databases, and a user. Outputs connection strings.
#
# Prerequisites: gcloud CLI authenticated, Cloud SQL Admin API enabled.
#
# Usage:
#   chmod +x setup-cloud-sql.sh
#   ./setup-cloud-sql.sh
#
# ⚠️  Cloud SQL instance creation takes 5-10 minutes per instance.

set -euo pipefail

DEV_PROJECT="digi-carts-dev"
PROD_PROJECT="digi-carts"
REGION="us-east1"
DB_VERSION="POSTGRES_15"
DB_USER="digicart"
DEV_INSTANCE="digi-carts-dev-db"
PROD_INSTANCE="digi-carts-db"
DEV_DB="digicarts_dev"
PROD_DB="digicarts"

# Prompt for DB password (never hardcode)
read -r -s -p "Enter DB password for user '$DB_USER' (same for dev + prod): " DB_PASSWORD
echo ""
if [ -z "$DB_PASSWORD" ]; then
  echo "ERROR: password cannot be empty"
  exit 1
fi

# ─── helpers ─────────────────────────────────────────────────────────────────

enable_api() {
  local PROJECT=$1
  echo "→ Enabling Cloud SQL API on $PROJECT..."
  gcloud services enable sqladmin.googleapis.com --project="$PROJECT" --quiet
  echo "  ✓ API enabled"
}

create_instance() {
  local PROJECT=$1
  local INSTANCE=$2
  local TIER=$3

  if gcloud sql instances describe "$INSTANCE" --project="$PROJECT" &>/dev/null 2>&1; then
    echo "  ✓ Instance '$INSTANCE' already exists — skipping"
    return
  fi

  echo "→ Creating Cloud SQL instance '$INSTANCE' (this takes ~5-10 min)..."
  gcloud sql instances create "$INSTANCE" \
    --database-version="$DB_VERSION" \
    --tier="$TIER" \
    --region="$REGION" \
    --storage-type=SSD \
    --storage-size=10GB \
    --storage-auto-increase \
    --project="$PROJECT" \
    --quiet
  echo "  ✓ Instance '$INSTANCE' created"
}

create_database() {
  local PROJECT=$1
  local INSTANCE=$2
  local DB=$3

  if gcloud sql databases describe "$DB" \
      --instance="$INSTANCE" \
      --project="$PROJECT" &>/dev/null 2>&1; then
    echo "  ✓ Database '$DB' already exists — skipping"
    return
  fi

  echo "→ Creating database '$DB'..."
  gcloud sql databases create "$DB" \
    --instance="$INSTANCE" \
    --project="$PROJECT" \
    --quiet
  echo "  ✓ Database '$DB' created"
}

create_user() {
  local PROJECT=$1
  local INSTANCE=$2

  if gcloud sql users list \
      --instance="$INSTANCE" \
      --project="$PROJECT" \
      --format="value(name)" | grep -q "^${DB_USER}$"; then
    echo "  ✓ User '$DB_USER' already exists — updating password"
    gcloud sql users set-password "$DB_USER" \
      --instance="$INSTANCE" \
      --password="$DB_PASSWORD" \
      --project="$PROJECT" \
      --quiet
  else
    echo "→ Creating user '$DB_USER'..."
    gcloud sql users create "$DB_USER" \
      --instance="$INSTANCE" \
      --password="$DB_PASSWORD" \
      --project="$PROJECT" \
      --quiet
    echo "  ✓ User created"
  fi
}

grant_cloud_run_access() {
  local PROJECT=$1
  local INSTANCE=$2

  echo "→ Granting Cloud SQL Client role to compute service account..."
  local SA="${PROJECT}-compute@developer.gserviceaccount.com"
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:${SA}" \
    --role="roles/cloudsql.client" \
    --quiet
  echo "  ✓ Granted roles/cloudsql.client to $SA"

  # Also grant to the github-actions SA so it can connect for migrations
  local GH_SA="github-actions-sa@${PROJECT}.iam.gserviceaccount.com"
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:${GH_SA}" \
    --role="roles/cloudsql.client" \
    --quiet
  echo "  ✓ Granted roles/cloudsql.client to $GH_SA"
}

print_connection_string() {
  local PROJECT=$1
  local INSTANCE=$2
  local DB=$3
  local ENV=$4

  local CONNECTION_NAME
  CONNECTION_NAME=$(gcloud sql instances describe "$INSTANCE" \
    --project="$PROJECT" \
    --format="value(connectionName)")

  echo ""
  echo "  ──────────────────────────────────────────────"
  echo "  $ENV connection info:"
  echo "  Cloud SQL Connection Name : $CONNECTION_NAME"
  echo ""
  echo "  DATABASE_URL (Cloud SQL Auth Proxy / Cloud Run direct VPC):"
  echo "  jdbc:postgresql:///$DB?cloudSqlInstance=${CONNECTION_NAME}&socketFactory=com.google.cloud.sql.postgres.SocketFactory&user=${DB_USER}&password=YOUR_PASSWORD"
  echo ""
  echo "  Set on Cloud Run services:"
  echo "  gcloud run services update SERVICE \\"
  echo "    --region $REGION --project $PROJECT \\"
  echo "    --add-cloudsql-instances=$CONNECTION_NAME \\"
  echo "    --set-env-vars=DATABASE_URL=jdbc:postgresql:///$DB?cloudSqlInstance=${CONNECTION_NAME}&socketFactory=com.google.cloud.sql.postgres.SocketFactory&user=${DB_USER}&password=REPLACE"
  echo "  ──────────────────────────────────────────────"
}

setup_env() {
  local ENV=$1
  local PROJECT=$2
  local INSTANCE=$3
  local DB=$4
  local TIER=$5

  echo ""
  echo "══════════════════════════════════════════════════"
  echo "  Provisioning Cloud SQL — $ENV ($PROJECT)"
  echo "══════════════════════════════════════════════════"

  gcloud config set project "$PROJECT" --quiet
  enable_api "$PROJECT"
  create_instance "$PROJECT" "$INSTANCE" "$TIER"
  create_database "$PROJECT" "$INSTANCE" "$DB"
  create_user "$PROJECT" "$INSTANCE"
  grant_cloud_run_access "$PROJECT" "$INSTANCE"
  print_connection_string "$PROJECT" "$INSTANCE" "$DB" "$ENV"
}

# ─── main ────────────────────────────────────────────────────────────────────

if ! command -v gcloud &>/dev/null; then
  echo "ERROR: gcloud CLI not found."
  exit 1
fi

# Dev: db-f1-micro (free tier eligible, good for dev)
setup_env "dev"  "$DEV_PROJECT"  "$DEV_INSTANCE"  "$DEV_DB"  "db-f1-micro"

# Prod: db-g1-small (1 vCPU, 1.7GB RAM — suitable for initial prod)
setup_env "prod" "$PROD_PROJECT" "$PROD_INSTANCE" "$PROD_DB" "db-g1-small"

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅  Cloud SQL setup complete"
echo ""
echo "  Next: run update-service-urls.sh to wire all"
echo "  Cloud Run services with DB URLs + JWT secret"
echo "══════════════════════════════════════════════════"
