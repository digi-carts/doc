# digi-carts Platform

A multi-tenant e-commerce platform built with Java Spring Boot microservices, Next.js frontends, and deployed on Google Cloud Run.

## Repositories

### Backend Services (Java Spring Boot 3.3.0 / Java 21)

| Repo | Port | DB Schema | Description |
|------|------|-----------|-------------|
| [api-gateway](https://github.com/digi-carts/api-gateway) | 3000 | — | Spring Cloud Gateway — JWT auth, routing |
| [auth-service](https://github.com/digi-carts/auth-service) | 3001 | `auth_svc` | Users, addresses, JWT, social login |
| [platform-service](https://github.com/digi-carts/platform-service) | 3002 | `platform_svc` | Subscriptions, admin users, support tickets |
| [notification-service](https://github.com/digi-carts/notification-service) | 3003 | `notif_svc` | Email (SMTP) + WhatsApp notifications |
| [catalog-service](https://github.com/digi-carts/catalog-service) | 3004 | `catalog_svc` | Products, categories, inventory |
| [order-service](https://github.com/digi-carts/order-service) | 3005 | `order_svc` | Orders, cart, returns |
| [payment-service](https://github.com/digi-carts/payment-service) | 3006 | `payment_svc` | Razorpay integration, webhooks |
| [shipping-service](https://github.com/digi-carts/shipping-service) | 3007 | `shipping_svc` | Multi-provider shipping (Shiprocket, Delhivery, etc.) |
| [store-service](https://github.com/digi-carts/store-service) | 3008 | `store_svc` | Store management, domains, pages |
| [storefront-service](https://github.com/digi-carts/storefront-service) | 3009 | `store_svc` | Storefront domain resolution (read-only) |
| [offer-service](https://github.com/digi-carts/offer-service) | 3010 | `offer_svc` | Discount codes, coupons |
| [billing-service](https://github.com/digi-carts/billing-service) | 3011 | `billing_svc` | Bills, invoices, PDF generation |
| [audit-log-service](https://github.com/digi-carts/audit-log-service) | 3012 | `audit_log_svc` | Platform audit logs |

### Frontend (Next.js / TypeScript)

| Repo | Description |
|------|-------------|
| [merchant-ui](https://github.com/digi-carts/merchant-ui) | Merchant dashboard (store admin) |
| [platform-ui](https://github.com/digi-carts/platform-ui) | Super-admin dashboard |
| [storefront](https://github.com/digi-carts/storefront) | Customer-facing storefront |

---

## Branch Strategy

```
feature/* ──► stage ──► main
                │          │
                ▼          ▼
           Deploy Dev   Release + Deploy Prod
         (digi-carts-dev)  (digi-carts)
```

| Branch | Purpose | Protection |
|--------|---------|------------|
| `stage` | Development / staging | No force-push, no deletion |
| `main` | Production | Requires 1 PR review, no force-push |

- **Push to `stage`** → CI builds Docker image, deploys to Google Cloud Run **dev** (`digi-carts-dev`)
- **Merge `stage` → `main`** → CI creates GitHub Release (auto-tagged semver), deploys to Cloud Run **prod** (`digi-carts`)

---

## Architecture

```
                        ┌─────────────┐
  Browser/App  ────────►│  api-gateway │ :3000
                        │  (JWT Auth) │
                        └──────┬──────┘
                               │ routes by path
         ┌─────────────────────┼───────────────────────────┐
         │                     │                           │
    /api/auth            /api/catalog            /api/orders
         │                     │                           │
  ┌──────▼──────┐   ┌──────────▼─────────┐   ┌────────────▼──────────┐
  │auth-service │   │  catalog-service   │   │    order-service      │
  │   :3001     │   │     :3004          │   │      :3005            │
  └─────────────┘   └────────────────────┘   └───────────────────────┘
         │                PostgreSQL                PostgreSQL
    auth_svc schema                          order_svc schema
```

All services connect to PostgreSQL with **Liquibase** managing schema migrations. Each service owns its own schema (`auth_svc`, `catalog_svc`, etc.) within a shared database.

---

## CI/CD

### GitHub Actions Secrets Required

Set these at **org level** (`digi-carts` org → Settings → Secrets) or per repo:

| Secret | Description |
|--------|-------------|
| `GCP_DEV_SA_KEY` | Google Cloud service account JSON key for `digi-carts-dev` project |
| `GCP_SA_KEY` | Google Cloud service account JSON key for `digi-carts` project |

### Workflows

#### `deploy-dev.yml` — triggers on push to `stage`
1. Authenticates to GCP project `digi-carts-dev`
2. Builds Docker image and pushes to Artifact Registry: `us-east1-docker.pkg.dev/digi-carts-dev/digi-cart/digi-cart-{service}-dev:latest`
3. Updates Cloud Run service `digi-cart-{service}-dev`

#### `deploy-prod.yml` — triggers on push to `main`
1. **Release job**: auto-increments semver patch tag (`v0.0.1` → `v0.0.2`), creates GitHub Release with auto-generated notes
2. **Deploy job**: authenticates to GCP project `digi-carts`, builds and tags Docker image (`:{version}` + `:latest`), updates Cloud Run service `digi-cart-{service}`

---

## GCP Infrastructure

| Resource | Dev (`digi-carts-dev`) | Prod (`digi-carts`) |
|----------|----------------------|---------------------|
| Artifact Registry | `us-east1-docker.pkg.dev/digi-carts-dev/digi-cart/` | `us-east1-docker.pkg.dev/digi-carts/digi-cart/` |
| Cloud Run region | `us-east1` | `us-east1` |
| Service naming | `digi-cart-{service}-dev` | `digi-cart-{service}` |

### Cloud Run Services to Create

**Dev:**
`digi-cart-api-gateway-dev`, `digi-cart-auth-service-dev`, `digi-cart-platform-service-dev`, `digi-cart-notification-service-dev`, `digi-cart-catalog-service-dev`, `digi-cart-order-service-dev`, `digi-cart-payment-service-dev`, `digi-cart-shipping-service-dev`, `digi-cart-store-service-dev`, `digi-cart-storefront-service-dev`, `digi-cart-offer-service-dev`, `digi-cart-billing-service-dev`, `digi-cart-audit-log-service-dev`, `digi-cart-merchant-ui-dev`, `digi-cart-platform-ui-dev`, `digi-cart-storefront-dev`

**Prod** (same names without `-dev` suffix).

---

## Database

Each service uses its own PostgreSQL schema. Run Liquibase migrations on startup — no manual schema setup needed.

### Required env vars per service

| Var | Description |
|-----|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `PORT` | Port override (defaults to service port) |

#### auth-service extras
| Var | Description |
|-----|-------------|
| `JWT_SECRET` | HMAC-SHA256 signing key |

#### api-gateway extras
| Var | Description |
|-----|-------------|
| `JWT_SECRET` | Same key as auth-service |
| `AUTH_SERVICE_URL` | Internal URL of auth-service |
| _(all service URLs)_ | `CATALOG_SERVICE_URL`, `ORDER_SERVICE_URL`, etc. |

---

## Local Development

### Prerequisites
- Java 21
- Maven 3.9+
- PostgreSQL 15+
- Docker (optional)

### Run a service locally

```bash
cd auth-service
export DATABASE_URL="jdbc:postgresql://localhost:5432/digicarts?currentSchema=auth_svc"
export JWT_SECRET="your-local-secret"
mvn spring-boot:run
```

### Run with Docker

```bash
cd auth-service
docker build -t auth-service .
docker run -p 3001:3001 \
  -e DATABASE_URL="jdbc:postgresql://host.docker.internal:5432/digicarts" \
  -e JWT_SECRET="your-local-secret" \
  auth-service
```

---

## Service Authentication Flow

```
Client → api-gateway (validates JWT) → X-User-Id + X-User-Role headers → downstream service
```

- `api-gateway` validates the JWT and injects `X-User-Id` and `X-User-Role` headers
- Downstream services read these headers — no independent JWT parsing needed
- Public paths (login, register, storefront) bypass JWT validation

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | Java 21, Spring Boot 3.3.0, Spring Data JPA |
| Database Migrations | Liquibase |
| Gateway | Spring Cloud Gateway 2023.0.3 |
| Auth | JJWT 0.12.6 (HMAC-SHA256) |
| Database | PostgreSQL |
| Frontend | Next.js 14, TypeScript, Tailwind CSS |
| Container | Docker (multi-stage Maven build) |
| Registry | Google Artifact Registry |
| Runtime | Google Cloud Run |
| CI/CD | GitHub Actions |

---

## Migration from dcart-app

This platform was migrated from `dcart-app` org:
- All backend services converted from **TypeScript/Node.js → Java Spring Boot**
- Domain references updated: `dcart` / `ecom` → `digi-carts`, `tara-cloud.org` → `digi-carts.com`
- Branch model changed: single `main` → `stage` (dev) + `main` (prod)
- GCP projects split: `digi-carts-dev` (dev) + `digi-carts` (prod)
- CI/CD rebuilt: push-to-stage deploys dev, merge-to-main creates release + deploys prod
