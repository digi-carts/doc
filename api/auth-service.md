# auth-service HTTP API

Service-native routes from Spring controllers. Default port **3001**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/addresses` | `findAll` | AddressController.java |
| POST | `/addresses` | `create` | AddressController.java |
| GET | `/addresses/user/{userId}` | `findByUserId` | AddressController.java |
| DELETE | `/addresses/{id}` | `delete` | AddressController.java |
| GET | `/addresses/{id}` | `findById` | AddressController.java |
| PATCH | `/addresses/{id}` | `update` | AddressController.java |
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/health` | `health` | HealthController.java |
| POST | `/password-reset-tokens` | `create` | PasswordResetTokenController.java |
| DELETE | `/password-reset-tokens/email/{email}` | `deleteByEmail` | PasswordResetTokenController.java |
| GET | `/password-reset-tokens/token/{token}` | `findByToken` | PasswordResetTokenController.java |
| DELETE | `/password-reset-tokens/{id}` | `delete` | PasswordResetTokenController.java |
| GET | `/password-reset-tokens/{id}` | `findById` | PasswordResetTokenController.java |
| GET | `/users` | `findAll` | UserController.java |
| POST | `/users` | `create` | UserController.java |
| GET | `/users/email/{email}` | `findByEmail` | UserController.java |
| DELETE | `/users/{id}` | `delete` | UserController.java |
| GET | `/users/{id}` | `findById` | UserController.java |
| PATCH | `/users/{id}` | `update` | UserController.java |
