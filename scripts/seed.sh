#!/bin/bash
# Creates the first super-admin user and subscription plans in a digi-carts environment.
# Connects directly to auth-service and platform-service via Cloud Run proxy.
#
# Usage:
#   chmod +x seed-dev.sh
#   ./seed-dev.sh            # seeds dev (default)
#   ./seed-dev.sh prod       # seeds prod
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
echo "  digi-carts seed data — $ENV ($PROJECT)"
echo "══════════════════════════════════════════════════"
echo ""

# ─── collect credentials ────────────────────────────────────────────────────
read -r -p "Super-admin email [admin@digicarts.com]: " ADMIN_EMAIL
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@digicarts.com}"

read -r -s -p "Super-admin password: " ADMIN_PASSWORD
echo ""
if [ -z "$ADMIN_PASSWORD" ]; then
  echo "ERROR: password cannot be empty"
  exit 1
fi

read -r -s -p "Confirm password: " ADMIN_PASSWORD2
echo ""
if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD2" ]; then
  echo "ERROR: passwords do not match"
  exit 1
fi

read -r -p "Super-admin name [Super Admin]: " ADMIN_NAME
ADMIN_NAME="${ADMIN_NAME:-Super Admin}"

# ─── hash password ──────────────────────────────────────────────────────────
echo ""
echo "→ Hashing password..."
HASH=$(htpasswd -nbBC 10 "" "$ADMIN_PASSWORD" | sed 's/^://' | tr -d '\n')
if [ -z "$HASH" ]; then
  echo "ERROR: htpasswd not found. Install with: brew install httpd"
  exit 1
fi

# ─── proxy helper ───────────────────────────────────────────────────────────
start_proxy() {
  local SVC="$1"
  local PORT="$2"
  gcloud run services proxy "digi-cart-${SVC}${SUFFIX}" \
    --region="$REGION" --project="$PROJECT" --port="$PORT" &>/dev/null &
  echo $!
}

wait_for_port() {
  local PORT="$1"
  local N=0
  until curl -sf "http://localhost:${PORT}/actuator/health" &>/dev/null || \
        curl -sf "http://localhost:${PORT}/health" &>/dev/null; do
    sleep 1
    N=$((N+1))
    if [ $N -ge 15 ]; then
      echo "  ERROR: service did not respond on port $PORT after 15s"
      return 1
    fi
  done
}

# ─── create super-admin ─────────────────────────────────────────────────────
echo "→ Starting proxy to auth-service..."
AUTH_PROXY_PID=$(start_proxy "auth-service" 13001)
sleep 3

echo "→ Creating super-admin user..."
RESPONSE=$(curl -sf -X POST "http://localhost:13001/users" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${ADMIN_EMAIL}\",
    \"passwordHash\": \"${HASH}\",
    \"name\": \"${ADMIN_NAME}\",
    \"role\": \"superadmin\",
    \"provider\": \"credentials\"
  }" 2>&1) || {
  echo "  ERROR: failed to create super-admin: $RESPONSE"
  kill "$AUTH_PROXY_PID" 2>/dev/null || true
  exit 1
}
kill "$AUTH_PROXY_PID" 2>/dev/null || true
echo "  ✓ Super-admin created: $ADMIN_EMAIL"

# ─── create subscription plans ──────────────────────────────────────────────
echo "→ Starting proxy to platform-service..."
PLATFORM_PROXY_PID=$(start_proxy "platform-service" 13002)
sleep 3

create_plan() {
  local BODY="$1"
  curl -sf -X POST "http://localhost:13002/subscriptions" \
    -H "Content-Type: application/json" \
    -d "$BODY" > /dev/null || echo "  WARNING: plan creation may have failed (possibly already exists)"
}

echo "→ Creating subscription plans..."

create_plan '{
  "name": "Free",
  "maxProducts": 10,
  "price": 0.0,
  "currency": "INR",
  "billingPeriod": "MONTHLY",
  "details": "Get started with up to 10 products. No credit card required.",
  "features": "{\"customDomain\":false,\"analytics\":false,\"support\":\"community\"}"
}'
echo "  ✓ Free plan"

create_plan '{
  "name": "Starter",
  "maxProducts": 100,
  "price": 499.0,
  "currency": "INR",
  "billingPeriod": "MONTHLY",
  "details": "Perfect for small stores with up to 100 products.",
  "features": "{\"customDomain\":true,\"analytics\":false,\"support\":\"email\"}"
}'
echo "  ✓ Starter plan"

create_plan '{
  "name": "Pro",
  "maxProducts": 1000,
  "price": 1499.0,
  "currency": "INR",
  "billingPeriod": "MONTHLY",
  "details": "Full-featured plan for growing businesses with up to 1000 products.",
  "features": "{\"customDomain\":true,\"analytics\":true,\"support\":\"priority\"}"
}'
echo "  ✓ Pro plan"

kill "$PLATFORM_PROXY_PID" 2>/dev/null || true

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✅  Seed data created for $ENV"
echo ""
echo "  Super-admin : $ADMIN_EMAIL"
echo "  Plans       : Free / Starter / Pro"
echo ""
echo "  Login at the platform-ui to verify."
echo "══════════════════════════════════════════════════"
