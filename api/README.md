# Platform HTTP API

Generated from Spring `@RestController` mappings. Paths are **service-native** (no gateway prefix rewrite).

| Service | Port | API |
|---------|------|-----|
| api-gateway | 3000 | [api-gateway.md](api-gateway.md) |
| audit-log-service | 3012 | [audit-log-service.md](audit-log-service.md) |
| auth-service | 3001 | [auth-service.md](auth-service.md) |
| billing-service | 3011 | [billing-service.md](billing-service.md) |
| catalog-service | 3004 | [catalog-service.md](catalog-service.md) |
| notification-service | 3003 | [notification-service.md](notification-service.md) |
| offer-service | 3010 | [offer-service.md](offer-service.md) |
| order-service | 3005 | [order-service.md](order-service.md) |
| payment-service | 3006 | [payment-service.md](payment-service.md) |
| platform-service | 3002 | [platform-service.md](platform-service.md) |
| shipping-service | 3007 | [shipping-service.md](shipping-service.md) |
| store-service | 3008 | [store-service.md](store-service.md) |
| storefront-service | 3009 | [storefront-service.md](storefront-service.md) |

HTML JavaDoc for each service: `mvn -f <service>/pom.xml javadoc:javadoc` → `target/site/apidocs`.
