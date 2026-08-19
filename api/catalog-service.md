# catalog-service HTTP API

Service-native routes from Spring controllers. Default port **3004**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/categories` | `list` | CategoryController.java |
| POST | `/categories` | `create` | CategoryController.java |
| DELETE | `/categories/{id}` | `delete` | CategoryController.java |
| GET | `/health` | `health` | HealthController.java |
| GET | `/products` | `list` | ProductController.java |
| POST | `/products` | `create` | ProductController.java |
| POST | `/products/deduct-stock` | `deductStock` | ProductController.java |
| GET | `/products/stock-summary` | `stockSummary` | ProductController.java |
| GET | `/products/tags` | `tags` | ProductController.java |
| DELETE | `/products/{id}` | `delete` | ProductController.java |
| GET | `/products/{id}` | `getOne` | ProductController.java |
| PATCH | `/products/{id}` | `update` | ProductController.java |
| POST | `/products/{id}/images-url` | `addImageUrl` | ProductController.java |
