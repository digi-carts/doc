# C4 container view

See [system design](./system-design.md) for context.

```mermaid
C4Container
  title digi-carts containers
  Person(shopper, "Shopper")
  Person(merchant, "Merchant")
  Person(admin, "Superadmin")

  System_Boundary(dc, "digi-carts") {
    Container(sf, "storefront", "Next.js 16", "Public shop + custom domains")
    Container(mui, "merchant-ui", "Next.js 16", "Store admin")
    Container(pui, "platform-ui", "Next.js 16", "SaaS admin")
    Container(gw, "api-gateway", "Spring Cloud Gateway", "JWT + routing")
    Container(auth, "auth-service", "Spring Boot", "Users, addresses")
    Container(cat, "catalog-service", "Spring Boot", "Products, stock")
    Container(ord, "order-service", "Spring Boot", "Orders, returns")
    ContainerDb(pg, "PostgreSQL", "Cloud SQL", "Schemas per service")
  }

  Rel(shopper, sf, "HTTPS")
  Rel(merchant, mui, "HTTPS")
  Rel(admin, pui, "HTTPS")
  Rel(sf, gw, "REST + JWT")
  Rel(mui, gw, "REST + JWT")
  Rel(pui, gw, "REST + JWT")
  Rel(gw, auth, "HTTP")
  Rel(gw, cat, "HTTP")
  Rel(gw, ord, "HTTP")
  Rel(auth, pg, "JDBC")
  Rel(cat, pg, "JDBC")
  Rel(ord, pg, "JDBC")
```

Remaining Java containers (platform, notification, payment, shipping, store, storefront-service, offer, billing, audit) sit behind the same gateway and the same Cloud SQL instance with isolated schemas.

## Technology choices

| Layer | Choice | Why |
|-------|--------|-----|
| Edge | Spring Cloud Gateway | Reactive routing, global JWT filter |
| Domain | Spring Boot 3.3 / Java 21 | Org-wide backend after TS → Java migration |
| UI | Next.js 16 App Router | SSR/rewrites for multi-tenant hosts |
| DB | PostgreSQL + Liquibase | Strong migrations, jsonb for branding/specs |
| Runtime | Cloud Run | Scale-to-zero, per-repo CI |
