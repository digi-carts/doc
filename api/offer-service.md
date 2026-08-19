# offer-service HTTP API

Service-native routes from Spring controllers. Default port **3010**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/api/offers` | `getAll` | OfferController.java |
| POST | `/api/offers` | `create` | OfferController.java |
| GET | `/api/offers/code/{code}` | `getByCode` | OfferController.java |
| DELETE | `/api/offers/{id}` | `delete` | OfferController.java |
| GET | `/api/offers/{id}` | `getById` | OfferController.java |
| PUT | `/api/offers/{id}` | `update` | OfferController.java |
| POST | `/api/offers/{id}/use` | `incrementUsage` | OfferController.java |
| GET | `/health` | `health` | HealthController.java |
