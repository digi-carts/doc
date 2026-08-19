# order-service HTTP API

Service-native routes from Spring controllers. Default port **3005**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/health` | `health` | HealthController.java |
| GET | `/orders` | `getAll` | OrderController.java |
| POST | `/orders` | `create` | OrderController.java |
| DELETE | `/orders/{id}` | `delete` | OrderController.java |
| GET | `/orders/{id}` | `getById` | OrderController.java |
| PUT | `/orders/{id}` | `update` | OrderController.java |
| GET | `/returns` | `getAll` | ReturnController.java |
| POST | `/returns` | `create` | ReturnController.java |
| DELETE | `/returns/{id}` | `delete` | ReturnController.java |
| GET | `/returns/{id}` | `getById` | ReturnController.java |
| PUT | `/returns/{id}` | `update` | ReturnController.java |
