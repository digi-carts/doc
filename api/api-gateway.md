# api-gateway HTTP API

Service-native routes from Spring controllers. Default port **3000**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/health` | `health` | HealthController.java |


## Gateway route table

From `src/main/resources/application.yml` (no `StripPrefix`; downstream must serve the same path). JWT is required except public paths in `JwtAuthFilter`.

| Route id | Predicate paths | Downstream env |
|----------|-----------------|----------------|
| auth-service | `/api/auth/**`, `/api/address/**` | `AUTH_SERVICE_URL` |
| platform-service | `/api/platform/**`, `/api/subscriptions/**`, `/api/admin/**`, `/api/templates/**`, `/api/support/**` | `PLATFORM_SERVICE_URL` |
| notification-service | `/api/notifications/**` | `NOTIFICATION_SERVICE_URL` |
| catalog-service | `/api/catalog/**`, `/api/products/**`, `/api/categories/**`, `/api/upload/**` | `CATALOG_SERVICE_URL` |
| order-service | `/api/orders/**`, `/api/cart/**`, `/api/returns/**` | `ORDER_SERVICE_URL` |
| payment-service | `/api/payments/**`, `/api/webhooks/**` | `PAYMENT_SERVICE_URL` |
| shipping-service | `/api/shipping/**` | `SHIPPING_SERVICE_URL` |
| store-service | `/api/stores/**`, `/api/domain/**`, `/api/pages/**` | `STORE_SERVICE_URL` |
| storefront-service | `/api/storefront/**` | `STOREFRONT_SERVICE_URL` |
| offer-service | `/api/offers/**` | `OFFER_SERVICE_URL` |
| billing-service | `/api/billing/**`, `/api/bills/**` | `BILLING_SERVICE_URL` |
| audit-log-service | `/api/audit/**` | `AUDIT_LOG_SERVICE_URL` |

Public (no JWT): `/api/auth/login`, `/api/auth/register`, `/api/auth/refresh`, `/api/storefront/**`, `/health`, `/api/health`, `/actuator/**`.
