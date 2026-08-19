# payment-service HTTP API

Service-native routes from Spring controllers. Default port **3006**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/api/payment-orders` | `findAll` | PaymentOrderController.java |
| POST | `/api/payment-orders` | `create` | PaymentOrderController.java |
| GET | `/api/payment-orders/razorpay/{razorpayOrderId}` | `findByRazorpayOrderId` | PaymentOrderController.java |
| GET | `/api/payment-orders/store/{storeId}` | `findByStoreId` | PaymentOrderController.java |
| GET | `/api/payment-orders/user/{userId}` | `findByUserId` | PaymentOrderController.java |
| DELETE | `/api/payment-orders/{id}` | `delete` | PaymentOrderController.java |
| GET | `/api/payment-orders/{id}` | `findById` | PaymentOrderController.java |
| PUT | `/api/payment-orders/{id}` | `update` | PaymentOrderController.java |
| GET | `/api/platform-payment-config` | `findAll` | PlatformPaymentConfigController.java |
| POST | `/api/platform-payment-config` | `create` | PlatformPaymentConfigController.java |
| GET | `/api/platform-payment-config/global` | `getGlobal` | PlatformPaymentConfigController.java |
| DELETE | `/api/platform-payment-config/{id}` | `delete` | PlatformPaymentConfigController.java |
| GET | `/api/platform-payment-config/{id}` | `findById` | PlatformPaymentConfigController.java |
| PUT | `/api/platform-payment-config/{id}` | `update` | PlatformPaymentConfigController.java |
| GET | `/api/processed-webhooks` | `findAll` | ProcessedWebhookController.java |
| POST | `/api/processed-webhooks` | `create` | ProcessedWebhookController.java |
| DELETE | `/api/processed-webhooks/{id}` | `delete` | ProcessedWebhookController.java |
| GET | `/api/processed-webhooks/{id}` | `findById` | ProcessedWebhookController.java |
| GET | `/api/processed-webhooks/{id}/exists` | `existsById` | ProcessedWebhookController.java |
| GET | `/api/store-payment-config` | `findAll` | StorePaymentConfigController.java |
| POST | `/api/store-payment-config` | `create` | StorePaymentConfigController.java |
| GET | `/api/store-payment-config/store/{storeId}` | `findByStoreId` | StorePaymentConfigController.java |
| DELETE | `/api/store-payment-config/{id}` | `delete` | StorePaymentConfigController.java |
| GET | `/api/store-payment-config/{id}` | `findById` | StorePaymentConfigController.java |
| PUT | `/api/store-payment-config/{id}` | `update` | StorePaymentConfigController.java |
| GET | `/health` | `health` | HealthController.java |
