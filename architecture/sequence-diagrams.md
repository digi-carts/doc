# Sequence diagrams

Companion to [system-design.md](system-design.md).

## JWT on a protected API

```mermaid
sequenceDiagram
  participant UI as merchant-ui / platform-ui / storefront
  participant GW as api-gateway JwtAuthFilter
  participant Svc as e.g. order-service
  UI->>GW: GET /api/orders Authorization Bearer
  GW->>GW: parse HS256 claims
  alt invalid
    GW-->>UI: 401
  else valid
    GW->>Svc: GET forwarded path X-User-Id X-User-Role
    Svc-->>GW: 200 body
    GW-->>UI: 200 body
  end
```

## Token refresh (frontend)

```mermaid
sequenceDiagram
  participant UI as axios interceptor
  participant GW as api-gateway
  participant Auth as auth-service intended
  UI->>GW: API call Bearer access
  GW-->>UI: 401
  UI->>GW: POST /api/auth/refresh refreshToken
  Note over Auth: login/refresh controllers not implemented yet
  GW-->>UI: accessToken refreshToken
  UI->>GW: retry original with new Bearer
```

## Storefront custom domain

```mermaid
sequenceDiagram
  participant B as Browser
  participant MW as storefront middleware
  participant Page as /s/[store]/...
  participant GW as api-gateway
  participant SF as storefront-service
  B->>MW: Host shop.example.com GET /products
  MW->>MW: canonicalStoreSlug
  MW->>Page: rewrite /s/{slug}/products
  Page->>GW: GET storefront / catalog public or JWT
  GW->>SF: resolve store
  SF-->>Page: store record
```

## Return / reverse logistics

```mermaid
sequenceDiagram
  participant M as merchant-ui
  participant O as order-service
  participant SH as shipping-service
  M->>O: POST /returns
  M->>SH: POST /api/return-shipments
  O-->>M: Return + ReturnItems
```

See also checkout and onboarding in the system design document.
