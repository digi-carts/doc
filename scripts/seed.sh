#!/bin/bash
# Creates the first super-admin user in a digi-carts environment.
# Connects directly to auth-service via Cloud Run proxy (bypasses gateway — no JWT needed).
#
# Usage:
#   chmod +x seed.sh
#   ./seed.sh            # seeds dev (default)
#   ./seed.sh prod       # seeds prod
#
# Requirements: gcloud CLI with Cloud Run access, htpasswd (macOS: brew install httpd)

set -euo pipefail

ENV="${1:-dev}"
REGION="us-east1"

if [ "$ENV" = "prod" ]; then
  PROJECT="digi-carts"
  SUFFIX=""
else
  PROJECT="digi-carts-dev"
  SUFFIX="-dev"
fi

echo ""
echo "══════════════════════════════════════════════════"
echo "  digi-carts seed — super-admin ($ENV)"
echo "══════════════════════════════════════════════════"
echo ""

# ─── collect credentials ────────────────────────────────────────────────────
read -r -p "Super-admin email [admin@digicarts.com]: " ADMIN_EMAIL
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@digicarts.com}"

read -r -s -p "Password: " ADMIN_PASSWORD; echo ""
if [ -z "$ADMIN_PASSWORD" ]; then echo "ERROR: password cannot be empty"; exit 1; fi

read -r -s -p "Confirm password: " ADMIN_PASSWORD2; echo ""
if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD2" ]; then echo "ERROR: passwords do not match"; exit 1; fi

read -r -p "Name [Super Admin]: " ADMIN_NAME
ADMIN_NAME="${ADMIN_NAME:-Super Admin}"

# ─── hash password ──────────────────────────────────────────────────────────
echo "→ Hashing password..."
HASH=$(htpasswd -nbBC 10 "" "$ADMIN_PASSWORD" 2>/dev/null | sed 's/^://' | tr -d '\n')
if [ -z "$HASH" ]; then
  echo "ERROR: htpasswd not found. Install with: brew install httpd"
  exit 1
fi

# ─── proxy to auth-service ──────────────────────────────────────────────────
echo "→ Starting proxy to auth-service..."
gcloud run services proxy "digi-cart-auth-service${SUFFIX}" \
  --region="$REGION" --project="$PROJECT" --port=13001 &>/dev/null &
PROXY_PID=$!
trap 'kill "$PROXY_PID" 2>/dev/null || true' EXIT

sleep 4

# ─── create super-admin ─────────────────────────────────────────────────────
echo "→ Creating super-admin..."
RESPONSE=$(curl -sf -X POST "http://localhost:13001/users" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${ADMIN_EMAIL}\",
    \"passwordHash\": \"${HASH}\",
    \"name\": \"${ADMIN_NAME}\",
    \"role\": \"superadmin\",
    \"provider\": \"credentials\"
  }") || {
  echo "ERROR: request failed — is auth-service healthy?"
  exit 1
}

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅  Super-admin created"
echo ""
echo "  Email : $ADMIN_EMAIL"
echo "  Env   : $ENV"
echo ""
echo "  Login at platform-ui to continue."
echo "══════════════════════════════════════════════════"
