#!/bin/bash
# Sets GCP_DEV_SA_KEY and GCP_SA_KEY on all 16 digi-carts repos.
#
# Usage:
#   chmod +x set-repo-secrets.sh
#   ./set-repo-secrets.sh

set -euo pipefail

DEV_KEY="/Users/I757692/Documents/workspace/digi-carts/doc/scripts/digi-carts-dev-sa-key.json"
PROD_KEY="/Users/I757692/Documents/workspace/digi-carts/doc/scripts/digi-carts-sa-key.json"

REPOS=(
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

if [ ! -f "$DEV_KEY" ]; then
  echo "ERROR: $DEV_KEY not found"
  exit 1
fi

DEV_KEY_CONTENT=$(cat "$DEV_KEY")
PROD_KEY_CONTENT=""
if [ -f "$PROD_KEY" ]; then
  PROD_KEY_CONTENT=$(cat "$PROD_KEY")
else
  echo "⚠️  Prod key not found — skipping GCP_SA_KEY"
fi

for REPO in "${REPOS[@]}"; do
  echo "→ digi-carts/$REPO"
  gh secret set GCP_DEV_SA_KEY \
    -R "digi-carts/$REPO" \
    --body "$DEV_KEY_CONTENT"
  echo "  ✓ GCP_DEV_SA_KEY set"

  if [ -n "$PROD_KEY_CONTENT" ]; then
    gh secret set GCP_SA_KEY \
      -R "digi-carts/$REPO" \
      --body "$PROD_KEY_CONTENT"
    echo "  ✓ GCP_SA_KEY set"
  fi
done

echo ""
echo "✅ Secrets set on all ${#REPOS[@]} repos"
