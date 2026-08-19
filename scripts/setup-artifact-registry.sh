#!/bin/bash
# Sets up Google Artifact Registry for digi-carts in both dev and prod GCP projects.
# Run once with a GCP account that has roles/artifactregistry.admin on both projects.
#
# Usage:
#   chmod +x setup-artifact-registry.sh
#   ./setup-artifact-registry.sh

set -euo pipefail

DEV_PROJECT="digi-carts-dev"
PROD_PROJECT="digi-carts"
REGION="us-east1"
REPO="digi-cart"

SERVICES=(
  api-gateway
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
  merchant-ui
  platform-ui
  storefront
)

# ─── helpers ─────────────────────────────────────────────────────────────────

check_gcloud() {
  if ! command -v gcloud &>/dev/null; then
    echo "ERROR: gcloud CLI not found. Install from https://cloud.google.com/sdk/docs/install"
    exit 1
  fi
  echo "✓ gcloud found: $(gcloud version --format='value(Google Cloud SDK)')"
}

create_registry() {
  local PROJECT=$1
  local ENV=$2

  echo ""
  echo "══════════════════════════════════════════════════"
  echo "  Setting up Artifact Registry — $ENV ($PROJECT)"
  echo "══════════════════════════════════════════════════"

  gcloud config set project "$PROJECT" --quiet

  # Enable required APIs
  echo "→ Enabling APIs..."
  gcloud services enable \
    artifactregistry.googleapis.com \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    --project="$PROJECT" --quiet
  echo "  ✓ APIs enabled"

  # Create Artifact Registry repo (idempotent)
  if gcloud artifacts repositories describe "$REPO" \
      --project="$PROJECT" \
      --location="$REGION" &>/dev/null 2>&1; then
    echo "  ✓ Repository '$REPO' already exists — skipping"
  else
    echo "→ Creating repository '$REPO'..."
    gcloud artifacts repositories create "$REPO" \
      --repository-format=docker \
      --location="$REGION" \
      --description="digi-carts Docker images ($ENV)" \
      --project="$PROJECT"
    echo "  ✓ Repository created"
  fi

  # Create service account for GitHub Actions
  local SA_NAME="github-actions-sa"
  local SA_EMAIL="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"

  if gcloud iam service-accounts describe "$SA_EMAIL" \
      --project="$PROJECT" &>/dev/null 2>&1; then
    echo "  ✓ Service account '$SA_EMAIL' already exists — skipping"
  else
    echo "→ Creating service account for GitHub Actions..."
    gcloud iam service-accounts create "$SA_NAME" \
      --display-name="GitHub Actions CI/CD" \
      --project="$PROJECT"
    echo "  ✓ Service account created"
  fi

  # Grant roles
  echo "→ Granting IAM roles..."
  for ROLE in \
    roles/artifactregistry.writer \
    roles/run.developer \
    roles/iam.serviceAccountUser; do
    gcloud projects add-iam-policy-binding "$PROJECT" \
      --member="serviceAccount:${SA_EMAIL}" \
      --role="$ROLE" \
      --quiet
    echo "  ✓ Granted $ROLE"
  done

  # Create and download key for GitHub Actions
  local KEY_FILE="${PROJECT}-sa-key.json"
  echo "→ Creating service account key → $KEY_FILE"
  gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL" \
    --project="$PROJECT"
  echo "  ✓ Key saved to $KEY_FILE"
  echo ""
  echo "  ⚠️  Add this file's contents as a GitHub secret:"
  if [ "$ENV" = "dev" ]; then
    echo "     Secret name : GCP_DEV_SA_KEY"
    echo "     Command     : gh secret set GCP_DEV_SA_KEY \\"
  else
    echo "     Secret name : GCP_SA_KEY"
    echo "     Command     : gh secret set GCP_SA_KEY \\"
  fi
  echo "                     --org digi-carts \\"
  echo "                     --visibility all \\"
  echo "                     < $KEY_FILE"
  echo ""

  # Configure Docker auth
  echo "→ Configuring Docker auth for $REGION-docker.pkg.dev..."
  gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
  echo "  ✓ Docker auth configured"

  # Print image path reference
  echo ""
  echo "  Artifact Registry URL:"
  echo "  ${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/"
  echo ""
  echo "  Example image tags:"
  for SVC in "${SERVICES[@]}"; do
    if [ "$ENV" = "dev" ]; then
      echo "    ${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/digi-cart-${SVC}-dev:latest"
    else
      echo "    ${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/digi-cart-${SVC}:latest"
    fi
  done
}

set_github_secrets() {
  echo ""
  echo "══════════════════════════════════════════════════"
  echo "  Setting GitHub org-level secrets"
  echo "══════════════════════════════════════════════════"

  if ! command -v gh &>/dev/null; then
    echo "SKIP: gh CLI not found — set secrets manually in GitHub org settings"
    return
  fi

  if [ -f "${DEV_PROJECT}-sa-key.json" ]; then
    echo "→ Setting GCP_DEV_SA_KEY..."
    gh secret set GCP_DEV_SA_KEY \
      --org digi-carts \
      --visibility all \
      < "${DEV_PROJECT}-sa-key.json"
    echo "  ✓ GCP_DEV_SA_KEY set"
  else
    echo "  SKIP: ${DEV_PROJECT}-sa-key.json not found"
  fi

  if [ -f "${PROD_PROJECT}-sa-key.json" ]; then
    echo "→ Setting GCP_SA_KEY..."
    gh secret set GCP_SA_KEY \
      --org digi-carts \
      --visibility all \
      < "${PROD_PROJECT}-sa-key.json"
    echo "  ✓ GCP_SA_KEY set"
  else
    echo "  SKIP: ${PROD_PROJECT}-sa-key.json not found"
  fi
}

# ─── main ────────────────────────────────────────────────────────────────────

check_gcloud

create_registry "$DEV_PROJECT" "dev"
create_registry "$PROD_PROJECT" "prod"
set_github_secrets

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅  Artifact Registry setup complete"
echo ""
echo "  Next steps:"
echo "  1. Verify keys added to GitHub: https://github.com/organizations/digi-carts/settings/secrets/actions"
echo "  2. Run: ./setup-cloud-run.sh  (creates all 32 Cloud Run services)"
echo "  3. Push a commit to 'stage' on any repo to trigger the first CI/CD run"
echo "══════════════════════════════════════════════════"
