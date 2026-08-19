# storefront-service HTTP API

Service-native routes from Spring controllers. Default port **3009**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/health` | `health` | HealthController.java |
| GET | `/stores` | `findAll` | StoreController.java |
| POST | `/stores` | `create` | StoreController.java |
| GET | `/stores/admin/{adminId}` | `findByAdminId` | StoreController.java |
| GET | `/stores/subdomain/{subdomain}` | `findBySubdomain` | StoreController.java |
| DELETE | `/stores/{id}` | `delete` | StoreController.java |
| GET | `/stores/{id}` | `findById` | StoreController.java |
| PUT | `/stores/{id}` | `update` | StoreController.java |
