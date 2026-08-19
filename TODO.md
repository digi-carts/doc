# digi-carts Platform — TODO Tracker

---

## ✅ DONE

### Repository Migration (dcart-app → digi-carts)
- [x] All 16 repos created in `digi-carts` org
- [x] `e2e-tests` excluded (skipped by design)
- [x] All backend services converted **TypeScript → Java Spring Boot 3.3.0 / Java 21**
- [x] All frontend repos migrated as-is (Next.js / TypeScript)
- [x] Name references updated: `dcart` / `ecom` / `dig-cart` → `digi-carts`
- [x] Domain references updated: `tara-cloud.org` → `digi-carts.com`
- [x] Old GCP project (`e-com-504518`) references removed

### Branch Strategy
- [x] `stage` branch created (default) on all repos — dev deployments
- [x] `main` branch created on all repos — production deployments
- [x] Both branches pushed to GitHub for all 16 repos

### CI/CD Workflows
- [x] `deploy-dev.yml` on all repos: push to `stage` → build + deploy to Cloud Run **dev**
- [x] `deploy-prod.yml` on all repos: push to `main` → auto-tag semver + GitHub Release + deploy Cloud Run **prod**
- [x] GCP projects separated: `digi-carts-dev` (dev) and `digi-carts` (prod)
- [x] Auth secrets separated: `GCP_DEV_SA_KEY` (dev) and `GCP_SA_KEY` (prod)
- [x] Docker images use Artifact Registry: `us-east1-docker.pkg.dev/{project}/digi-cart/digi-cart-{service}`

### Backend Services (Java Spring Boot)
- [x] `api-gateway` — Spring Cloud Gateway, JWT filter, 12 service routes, CORS
- [x] `auth-service` — User/Address/PasswordResetToken entities, JWT, Spring Security
- [x] `notification-service` — NotificationConfig + NotificationLog, email/WhatsApp channels
- [x] `order-service` — Order/OrderItem/Return/ReturnItem entities, full CRUD
- [x] `payment-service` — PlatformPaymentConfig/StorePaymentConfig/PaymentOrder/ProcessedWebhook
- [x] `platform-service` — AdminUser/Subscription/PlatformConfig/SupportTicket
- [x] `shipping-service` — ShipperConfig/ShippingProviderConfig/Shipment/ReturnShipment/PincodeFallback
- [x] `store-service` — Store/StorePage entities
- [x] `storefront-service` — Store read-only resolver
- [x] `offer-service` — Offer entity (discount codes)
- [x] `billing-service` — Bill/BillTemplate entities
- [x] `audit-log-service` — AuditLog/AuditSettings entities
- [x] `catalog-service` — pre-existing Java service (Product/Category)

### Database
- [x] Liquibase migrations for all backend services (creates schema + all tables)
- [x] Hibernate set to `validate` (Liquibase owns schema, not Hibernate DDL)
- [x] Per-service schemas: `auth_svc`, `catalog_svc`, `order_svc`, etc.

### Frontends
- [x] `merchant-ui` — migrated, stage + main branches
- [x] `platform-ui` — migrated, stage + main branches
- [x] `storefront` — migrated, stage + main branches

### Documentation
- [x] `doc` repo created
- [x] `README.md` — full platform overview, architecture, repo table, CI/CD, GCP setup, local dev guide
- [x] `TODO.md` — this file
- [x] `scripts/setup-artifact-registry.sh` — GCP Artifact Registry + service account + IAM setup script
- [x] `scripts/setup-cloud-run.sh` — creates all 32 Cloud Run services (16 dev + 16 prod)
- [x] Per-repo `doc/README.md` on all 16 app repos (PRs to `stage`)
- [x] Platform architecture pack: `architecture/system-design.md`, `sequence-diagrams.md`, `c4-containers.md`, `data-model.md`, `service-catalog.md`

### JavaDoc, health checks, tests
- [x] JavaDoc (+ `package-info.java`, javadoc plugin) on all 13 Java services
- [x] Liveness endpoints `GET /health` and `GET /api/health` on all 12 domain services and `api-gateway` (JWT public paths include both)
- [x] JUnit 5 unit tests + Cucumber component suites on all Java services (Cucumber excluded from Surefire JaCoCo gate)
- [x] Cucumber JS component tests on `merchant-ui`, `platform-ui`, `storefront` (`npm run test:component`)
- [x] JaCoCo **line + branch COVEREDRATIO 1.00** enforced on `mvn test` for all 13 Java services
- [x] GitHub Actions **PR tests** (`pr-tests.yml`): `pull_request` to `stage`/`main` runs `mvn -B test` (Java) or `npm run test:component` (UIs); deploy-dev waits on the same test job
- [ ] Require the `PR tests / test` status check in branch protection (GitHub Team)

---

## ❌ PENDING

### GitHub Org Setup
- [ ] **Add org-level secrets** (`digi-carts` org → Settings → Secrets):
  - `GCP_DEV_SA_KEY` — GCP service account JSON for `digi-carts-dev`
  - `GCP_SA_KEY` — GCP service account JSON for `digi-carts`
- [ ] **Enable branch protection** on all repos (requires GitHub Pro / Team plan):
  - `main`: require 1 PR review, block force-push, block deletion
  - `stage`: block force-push and deletion

### GCP Infrastructure — Dev (`digi-carts-dev`)

- [x] Artifact Registry setup script ready → run `doc/scripts/setup-artifact-registry.sh`
- [ ] **Run** `setup-artifact-registry.sh` (creates `digi-cart` repo, service account, IAM roles, downloads SA key)
- [x] Cloud Run setup script ready → run `doc/scripts/setup-cloud-run.sh`
- [ ] **Run** `setup-cloud-run.sh` (creates all 16 dev services with placeholder image)
- [ ] Provision PostgreSQL (Cloud SQL) for dev
- [ ] Update `DATABASE_URL` env var on all 12 backend services
- [ ] Update `JWT_SECRET` on `api-gateway` + `auth-service`
- [ ] Update `*_SERVICE_URL` env vars on `api-gateway` with real Cloud Run URLs

### GCP Infrastructure — Prod (`digi-carts`)

- [x] Cloud Run setup script ready → run `doc/scripts/setup-cloud-run.sh` (handles both dev + prod)
- [ ] **Run** `setup-cloud-run.sh` (creates all 16 prod services with placeholder image)
- [ ] Provision PostgreSQL (Cloud SQL) for prod — high availability recommended
- [ ] Update `DATABASE_URL`, `JWT_SECRET`, `*_SERVICE_URL` env vars on all services
- [ ] Set up Cloud Armor / Load Balancer for custom domain `digi-carts.com`

### Environment Variables per Cloud Run Service

#### All backend services
| Var | Value |
|-----|-------|
| `DATABASE_URL` | `jdbc:postgresql://{host}/{db}?currentSchema={schema}` |

#### `api-gateway`
| Var | Value |
|-----|-------|
| `JWT_SECRET` | strong random secret (same as auth-service) |
| `AUTH_SERVICE_URL` | internal Cloud Run URL |
| `CATALOG_SERVICE_URL` | internal Cloud Run URL |
| `ORDER_SERVICE_URL` | internal Cloud Run URL |
| `PAYMENT_SERVICE_URL` | internal Cloud Run URL |
| `PLATFORM_SERVICE_URL` | internal Cloud Run URL |
| `NOTIFICATION_SERVICE_URL` | internal Cloud Run URL |
| `SHIPPING_SERVICE_URL` | internal Cloud Run URL |
| `STORE_SERVICE_URL` | internal Cloud Run URL |
| `STOREFRONT_SERVICE_URL` | internal Cloud Run URL |
| `OFFER_SERVICE_URL` | internal Cloud Run URL |
| `BILLING_SERVICE_URL` | internal Cloud Run URL |
| `AUDIT_LOG_SERVICE_URL` | internal Cloud Run URL |

#### `auth-service`
| Var | Value |
|-----|-------|
| `JWT_SECRET` | same strong random secret as api-gateway |

#### `payment-service`
| Var | Value |
|-----|-------|
| `RAZORPAY_KEY_ID` | Razorpay API key |
| `RAZORPAY_KEY_SECRET` | Razorpay secret |

#### `notification-service`
| Var | Value |
|-----|-------|
| Configured at runtime via `/api/notification-config` endpoint | |

#### `shipping-service`
| Var | Value |
|-----|-------|
| Configured at runtime via store shipping config | |

#### `catalog-service`
| Var | Value |
|-----|-------|
| `GCS_BUCKET` | GCS bucket name for product image uploads |

#### `merchant-ui` / `platform-ui` / `storefront`
| Var | Value |
|-----|-------|
| `NEXT_PUBLIC_API_URL` | api-gateway Cloud Run URL |
| `NEXTAUTH_SECRET` | NextAuth secret |
| `NEXTAUTH_URL` | App URL |

### Domain & Networking
- [ ] Set up custom domain `digi-carts.com` → `storefront` Cloud Run service
- [ ] Set up `app.digi-carts.com` → `merchant-ui` Cloud Run service
- [ ] Set up `admin.digi-carts.com` → `platform-ui` Cloud Run service
- [ ] Set up `api.digi-carts.com` → `api-gateway` Cloud Run service
- [ ] Configure SSL certificates (Google-managed or Let's Encrypt)
- [ ] Set up store subdomains: `{store}.digi-carts.com` → `storefront` Cloud Run

### Initial Data / Seed
- [ ] Create default platform subscription plans (via `platform-service`)
- [ ] Create super-admin user (via `auth-service`)
- [ ] Create default store template entries

### Post-Migration Verification
- [x] Health endpoints implemented on all 13 Java backends (`GET /health`, `GET /api/health`) — **deployed** Cloud Run smoke still pending
- [ ] Hit live Cloud Run `/health` on all 13 backends after first deploy
- [ ] Verify Liquibase runs successfully (all schemas and tables created)
- [ ] Test auth flow: register → login → JWT → api-gateway proxy
- [ ] Test catalog CRUD via api-gateway
- [ ] Test order creation flow end-to-end
- [ ] Verify CI/CD: push to stage → dev deploys; merge to main → release + prod deploys
- [ ] Verify GitHub Release is auto-created on first merge to main

---

## 📋 Summary

| Category | Done | Pending |
|----------|------|---------|
| Repos created | 16 / 16 | 0 |
| Backend Java services | 13 / 13 | 0 |
| Frontend repos | 3 / 3 | 0 |
| CI/CD workflows | 16 / 16 | 0 |
| Branch setup | 16 / 16 | 0 |
| Per-repo + platform docs | 17 / 17 | 0 |
| JavaDoc (Java services) | 13 / 13 | 0 |
| Health endpoints in code | 13 / 13 | live Cloud Run smoke |
| JUnit + JaCoCo 100% | 13 / 13 | 0 |
| UI Cucumber component tests | 3 / 3 | 0 |
| PR test workflow | 16 / 16 | require status check |
| PR test workflow | 16 / 16 | require status check |
| Branch protection | 0 / 16 | 16 (needs GitHub Pro) |
| GCP Artifact Registry | 1 / 2 (script ready) | run script |
| Cloud Run services | 0 / 32 (script ready) | run script |
| PostgreSQL provisioned | 0 / 2 | 2 |
| GitHub org secrets | 0 / 2 | 2 |
| Env vars configured | 0 / 16 | 16 |
| Custom domain setup | 0 / 4 | 4 |
| Initial seed data | 0 / 1 | 1 |
