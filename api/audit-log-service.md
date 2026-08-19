# audit-log-service HTTP API

Service-native routes from Spring controllers. Default port **3012**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/audit-logs` | `findAll` | AuditLogController.java |
| POST | `/audit-logs` | `create` | AuditLogController.java |
| POST | `/audit-logs/purge` | `purge` | AuditLogController.java |
| DELETE | `/audit-logs/{id}` | `delete` | AuditLogController.java |
| GET | `/audit-logs/{id}` | `findById` | AuditLogController.java |
| GET | `/audit-settings` | `getSettings` | AuditSettingsController.java |
| PUT | `/audit-settings` | `update` | AuditSettingsController.java |
| GET | `/health` | `health` | HealthController.java |
