# notification-service HTTP API

Service-native routes from Spring controllers. Default port **3003**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/api/notification-config` | `get` | NotificationConfigController.java |
| PUT | `/api/notification-config` | `upsert` | NotificationConfigController.java |
| GET | `/api/notification-logs` | `getAll` | NotificationLogController.java |
| POST | `/api/notification-logs` | `create` | NotificationLogController.java |
| DELETE | `/api/notification-logs/{id}` | `delete` | NotificationLogController.java |
| GET | `/api/notification-logs/{id}` | `getById` | NotificationLogController.java |
| PATCH | `/api/notification-logs/{id}/status` | `updateStatus` | NotificationLogController.java |
| GET | `/health` | `health` | HealthController.java |
