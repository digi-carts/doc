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

# ─── health-check ───────────────────────────────────────────────────────────
echo "→ Checking auth-service health..."
for i in 1 2 3 4 5; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:13001/health" 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ]; then break; fi
  echo "  waiting for proxy ($i/5)..."
  sleep 2
done
if [ "$STATUS" != "200" ]; then
  echo "ERROR: auth-service not reachable (status=$STATUS)"
  exit 1
fi

# ─── create super-admin ─────────────────────────────────────────────────────
echo "→ Creating super-admin..."
HTTP_CODE=$(curl -s -o /tmp/seed_response.json -w "%{http_code}" -X POST "http://localhost:13001/users" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${ADMIN_EMAIL}\",
    \"passwordHash\": \"${HASH}\",
    \"name\": \"${ADMIN_NAME}\",
    \"role\": \"superadmin\",
    \"provider\": \"credentials\"
  }")

if [ "$HTTP_CODE" = "201" ]; then
  RESPONSE=$(cat /tmp/seed_response.json)
elif [ "$HTTP_CODE" = "409" ] || (grep -qi "already exists\|duplicate\|unique" /tmp/seed_response.json 2>/dev/null); then
  echo "INFO: user ${ADMIN_EMAIL} already exists — updating role to superadmin..."
  USER_ID=$(curl -s "http://localhost:13001/users/email/${ADMIN_EMAIL}" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
  if [ -n "$USER_ID" ]; then
    curl -s -X PATCH "http://localhost:13001/users/${USER_ID}" \
      -H "Content-Type: application/json" \
      -d '{"role":"superadmin"}' > /dev/null
    RESPONSE="{\"email\":\"${ADMIN_EMAIL}\"}"
  else
    echo "ERROR: could not fetch existing user. Response:"
    cat /tmp/seed_response.json
    exit 1
  fi
else
  echo "ERROR: request failed (HTTP $HTTP_CODE). Response:"
  cat /tmp/seed_response.json
  exit 1
fi

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅  Super-admin created"
echo ""
echo "  Email : $ADMIN_EMAIL"
echo "  Env   : $ENV"
echo ""
echo "  Login at platform-ui to continue."
echo "══════════════════════════════════════════════════"
