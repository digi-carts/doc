# platform-service HTTP API

Service-native routes from Spring controllers. Default port **3002**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/admin-users` | `findAll` | AdminUserController.java |
| POST | `/admin-users` | `create` | AdminUserController.java |
| GET | `/admin-users/by-email/{email}` | `findByEmail` | AdminUserController.java |
| DELETE | `/admin-users/{id}` | `delete` | AdminUserController.java |
| GET | `/admin-users/{id}` | `findById` | AdminUserController.java |
| PUT | `/admin-users/{id}` | `update` | AdminUserController.java |
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/health` | `health` | HealthController.java |
| GET | `/platform-config` | `get` | PlatformConfigController.java |
| PUT | `/platform-config` | `update` | PlatformConfigController.java |
| GET | `/subscriptions` | `findAll` | SubscriptionController.java |
| POST | `/subscriptions` | `create` | SubscriptionController.java |
| DELETE | `/subscriptions/{id}` | `delete` | SubscriptionController.java |
| GET | `/subscriptions/{id}` | `findById` | SubscriptionController.java |
| PUT | `/subscriptions/{id}` | `update` | SubscriptionController.java |
| GET | `/support-tickets` | `findAll` | SupportTicketController.java |
| POST | `/support-tickets` | `create` | SupportTicketController.java |
| DELETE | `/support-tickets/{id}` | `delete` | SupportTicketController.java |
| GET | `/support-tickets/{id}` | `findById` | SupportTicketController.java |
| PUT | `/support-tickets/{id}` | `update` | SupportTicketController.java |
| GET | `/ticket-comments` | `findByTicketId` | TicketCommentController.java |
| POST | `/ticket-comments` | `create` | TicketCommentController.java |
| DELETE | `/ticket-comments/{id}` | `delete` | TicketCommentController.java |
| GET | `/ticket-comments/{id}` | `findById` | TicketCommentController.java |
