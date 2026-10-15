# Campus Delivery API - courier section (DRAFT)

> **Status:** draft written from the courier app's `CourierService`
> (`lib/services/courier_service.dart`) so Person 3 has a contract to build
> against (B-02, B-05 to B-11). Person 3 owns this file - change anything
> that doesn't work for the server, and tell Person 2 so the app matches.
> The customer section (Person 1) still needs to be added.

## Conventions

- Base URL: `http://localhost:3000` in development (`server/src/config.js`).
- JSON everywhere, `Content-Type: application/json`.
- **Money is in whole cents** (`350` = $3.50). Never floats.
- **Times** are ISO 8601 strings in UTC, e.g. `"2026-10-14T20:05:00Z"`.
- **Status** values are exactly: `requested`, `accepted`, `pickedUp`,
  `delivered`, `cancelled`.
- The server works out `deliveryFeeCents` from the distance (B-06), so the
  app never sends a fee: $2.00 + $0.50 per started 0.25 mi from the Union,
  capped at $6.00.
- The Flutter web app calls the API from the browser, so **CORS must be
  enabled** (B-13).

## Order

```json
{
  "id": "order-1",
  "customerId": "customer-1",
  "courierId": null,
  "pickupLocation": "Student Union · Grill",
  "dropoffLocation": "Library · Main entrance",
  "distanceMiles": 0.4,
  "deliveryFeeCents": 300,
  "tipCents": 100,
  "status": "requested",
  "pawPointsOrderNumber": "PP-4810",
  "createdAt": "2026-10-14T20:05:00Z",
  "updatedAt": "2026-10-14T20:05:00Z",
  "acceptedAt": null,
  "pickedUpAt": null,
  "deliveredAt": null,
  "dropoffNote": null,
  "customerRating": null,
  "customerNote": null
}
```

| Field | Notes |
|---|---|
| `courierId` | `null` until a courier accepts. |
| `acceptedAt`, `pickedUpAt`, `deliveredAt` | Set by the server when each step happens (timeline, K-24). |
| `dropoffNote` | Optional text the courier sends with "delivered" (K-34), max 80 chars. |
| `customerRating`, `customerNote` | 1-5 stars and optional thank-you, left by the customer after delivery (K-47). |

The app works out `totalPayCents` (fee + tip) and pay per mile itself, so
the server doesn't need to send them.

## Errors

Every error response looks like:

```json
{ "error": "already_taken", "message": "Another courier accepted this order." }
```

| HTTP | `error` | App exception | When |
|---|---|---|---|
| 404 | `not_found` | `OrderNotFoundException` | No such order (or it was cancelled). |
| 409 | `already_taken` | `OrderAlreadyTakenException` | Another courier accepted it first. |
| 409 | `active_delivery` | `ActiveDeliveryException` | This courier already has an accepted or picked-up order. |
| 409 | `invalid_transition` | `InvalidStatusChangeException` | Status change out of order (e.g. accepted -> delivered). |
| 403 | `not_your_delivery` | `NotYourDeliveryException` | Releasing an order another courier holds. |
| 5xx / no response | - | `ServiceUnavailableException` | The app shows "Couldn't reach the server" with Try again. |

## Endpoints

### List open requests
`GET /orders?status=requested` -> `CourierService.fetchAvailableRequests`

`200` with an array of Orders, **oldest first**.

### The courier's active delivery
`GET /couriers/{courierId}/active-delivery` -> `fetchActiveDelivery`

`200` with the Order that is `accepted` or `pickedUp`, or `204 No Content`
when there is none.

### Accept a request
`PATCH /orders/{orderId}/accept` -> `acceptRequest`

```json
{ "courierId": "courier-demo" }
```

`200` with the updated Order (`status: "accepted"`, `courierId` and
`acceptedAt` set). Must be **atomic** (B-08): if two couriers accept at the
same time, exactly one gets `200` and the other gets `409 already_taken`.
`409 active_delivery` if this courier already has a job.

### Update status
`PATCH /orders/{orderId}/status` -> `updateStatus`

```json
{ "status": "pickedUp" }
```
```json
{ "status": "delivered", "dropoffNote": "Left with the front desk" }
```

Only `accepted -> pickedUp -> delivered` is allowed (B-09); anything else
is `409 invalid_transition`. On `delivered` the server adds the order's
fee + tip to the courier's balance **in the same transaction** (B-10).

### Release before pickup
`PATCH /orders/{orderId}/release` -> `releaseDelivery`

```json
{ "courierId": "courier-demo" }
```

`200` with the Order back to `status: "requested"`, `courierId` and
`acceptedAt` cleared. Only allowed while `accepted` (`409
invalid_transition` after pickup); `403 not_your_delivery` if another
courier holds it.

### Earnings
`GET /couriers/{courierId}/earnings` -> `fetchEarnings`

```json
{
  "balanceCents": 4050,
  "completedDeliveries": [ { "...": "Order objects, newest first" } ]
}
```

## Hooking it up (K-12)

Once these endpoints exist, the app needs one new class,
`ApiCourierService implements CourierService`, that calls them and turns
the error codes above into the matching exceptions. Then `main.dart`
swaps `MockCourierService()` for it - no screen changes needed. The mock
already follows every rule on this page, so the screens are tested
against the same behaviour.
