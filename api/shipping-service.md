# shipping-service HTTP API

Service-native routes from Spring controllers. Default port **3007**.
The API gateway does **not** strip prefixes. Callers usually enter via **api-gateway :3000**.
Protected routes expect `Authorization: Bearer <jwt>`. Services also read `X-User-Id` / `X-User-Role`.

JavaDoc: every class and public method in `src/main/java`. HTML: `mvn javadoc:javadoc`.

| Method | Path | Handler | Controller |
|--------|------|---------|------------|
| GET | `/api/health` | `health` | HealthController.java |
| GET | `/api/pincode-fallback` | `findAll` | PincodeFallbackController.java |
| POST | `/api/pincode-fallback` | `create` | PincodeFallbackController.java |
| GET | `/api/pincode-fallback/store/{storeId}` | `findByStoreId` | PincodeFallbackController.java |
| DELETE | `/api/pincode-fallback/{id}` | `delete` | PincodeFallbackController.java |
| GET | `/api/pincode-fallback/{id}` | `findById` | PincodeFallbackController.java |
| PUT | `/api/pincode-fallback/{id}` | `update` | PincodeFallbackController.java |
| GET | `/api/provider-config` | `findAll` | ShippingProviderConfigController.java |
| POST | `/api/provider-config` | `create` | ShippingProviderConfigController.java |
| GET | `/api/provider-config/store/{storeId}` | `findByStoreId` | ShippingProviderConfigController.java |
| DELETE | `/api/provider-config/{id}` | `delete` | ShippingProviderConfigController.java |
| GET | `/api/provider-config/{id}` | `findById` | ShippingProviderConfigController.java |
| PUT | `/api/provider-config/{id}` | `update` | ShippingProviderConfigController.java |
| GET | `/api/return-shipments` | `findAll` | ReturnShipmentController.java |
| POST | `/api/return-shipments` | `create` | ReturnShipmentController.java |
| GET | `/api/return-shipments/order/{orderId}` | `findByOrderId` | ReturnShipmentController.java |
| GET | `/api/return-shipments/store/{storeId}` | `findByStoreId` | ReturnShipmentController.java |
| DELETE | `/api/return-shipments/{id}` | `delete` | ReturnShipmentController.java |
| GET | `/api/return-shipments/{id}` | `findById` | ReturnShipmentController.java |
| PUT | `/api/return-shipments/{id}` | `update` | ReturnShipmentController.java |
| GET | `/api/shipments` | `findAll` | ShipmentController.java |
| POST | `/api/shipments` | `create` | ShipmentController.java |
| GET | `/api/shipments/order/{orderId}` | `findByOrderId` | ShipmentController.java |
| GET | `/api/shipments/store/{storeId}` | `findByStoreId` | ShipmentController.java |
| DELETE | `/api/shipments/{id}` | `delete` | ShipmentController.java |
| GET | `/api/shipments/{id}` | `findById` | ShipmentController.java |
| PUT | `/api/shipments/{id}` | `update` | ShipmentController.java |
| GET | `/api/shipper-config` | `findAll` | ShipperConfigController.java |
| POST | `/api/shipper-config` | `create` | ShipperConfigController.java |
| GET | `/api/shipper-config/store/{storeId}` | `findByStoreId` | ShipperConfigController.java |
| DELETE | `/api/shipper-config/{id}` | `delete` | ShipperConfigController.java |
| GET | `/api/shipper-config/{id}` | `findById` | ShipperConfigController.java |
| PUT | `/api/shipper-config/{id}` | `update` | ShipperConfigController.java |
| GET | `/health` | `health` | HealthController.java |
