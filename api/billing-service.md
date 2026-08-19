# billing-service HTTP API

Service-native routes from Spring controllers. Default port **3011**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/bill-templates` | `getAll` | BillTemplateController.java |
| POST | `/bill-templates` | `create` | BillTemplateController.java |
| GET | `/bill-templates/store/{storeId}` | `getByStoreId` | BillTemplateController.java |
| DELETE | `/bill-templates/{id}` | `delete` | BillTemplateController.java |
| GET | `/bill-templates/{id}` | `getById` | BillTemplateController.java |
| PUT | `/bill-templates/{id}` | `update` | BillTemplateController.java |
| GET | `/bills` | `getAll` | BillController.java |
| POST | `/bills` | `create` | BillController.java |
| GET | `/bills/order/{orderId}` | `getByOrderId` | BillController.java |
| DELETE | `/bills/{id}` | `delete` | BillController.java |
| GET | `/bills/{id}` | `getById` | BillController.java |
| PUT | `/bills/{id}` | `update` | BillController.java |
| GET | `/health` | `health` | HealthController.java |
