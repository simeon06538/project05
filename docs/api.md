# Campus Delivery API

Owner: Person 3 (server). Change this file in the same commit as any API change.

- Base URL (local): `http://localhost:3000`
  - Android emulator: `http://10.0.2.2:3000`
  - Physical phone on the same Wi-Fi: `http://<your-computer-LAN-IP>:3000`
- All request and response bodies are JSON (`Content-Type: application/json`).
- IDs: users and orders have integer IDs. Locations have short string IDs
  (for example `"union"`, `"middleton-library"`).
- Money is in **US dollars** as numbers with at most 2 decimals (for example `3.5` means $3.50).
  The server stores cents internally, so rounding is exact.
- Timestamps are ISO-8601 UTC strings (`"2026-10-16T18:04:11.123Z"`).

## Data models

### User

```json
{
  "id": 1,
  "name": "Alex Customer",
  "email": "alex@example.edu",
  "role": "customer",
  "earnings": 0
}
```

| Field      | Type            | Notes                                         |
|------------|-----------------|-----------------------------------------------|
| `id`       | int             | Server-assigned                               |
| `name`     | string          | 1-100 chars                                   |
| `email`    | string \| null  | Optional, unique if given                     |
| `role`     | string          | `"customer"` or `"courier"`                   |
| `earnings` | number (dollars)| Demo balance. Always `0` for customers        |

### Location

```json
{ "id": "middleton-library", "name": "Middleton Library", "distanceFromUnionMiles": 0.2 }
```

### Order

```json
{
  "id": 12,
  "customerId": 1,
  "courierId": null,
  "pickupLocation": "union",
  "pickupLocationName": "LSU Student Union",
  "dropoffLocation": "west-campus-apts",
  "dropoffLocationName": "West Campus Apartments",
  "distanceMiles": 1.0,
  "deliveryFee": 4.0,
  "tip": 2.0,
  "totalPay": 6.0,
  "status": "requested",
  "pawPointsOrderNumber": "PP-10442",
  "createdAt": "2026-10-16T18:04:11.123Z",
  "updatedAt": "2026-10-16T18:04:11.123Z"
}
```

- `pickupLocation` and `dropoffLocation` are location IDs. The `...Name` fields are
  included so screens don't have to look them up.
- `courierId` is `null` until a courier accepts.
- `distanceMiles` is the approximate pickup-to-drop-off distance. Union pickups retain the catalog's Union estimate; other origins use schematic offsets. See [location sources and limitations](locations.md).
- `deliveryFee`, `distanceMiles` and `totalPay` are always **calculated by the server**.
  If the client sends them, the server ignores them.

### Status values

```
requested -> accepted -> picked_up -> delivered
requested -> cancelled
```

No other transitions are allowed. `delivered` and `cancelled` are final.

### Customer pickup metadata

Orders now include nullable `orderName` and `pickupRestaurant` strings. New customer requests send both (1–100 characters, trimmed); they remain optional on the server for compatibility with existing courier/demo clients. Old orders have null values. These fields identify the food order and restaurant within a pickup building.

## Pricing

```
deliveryFee = min($2.00 + $0.50 * ceil(distanceMiles / 0.25), $6.00)
totalPay    = deliveryFee + tip
```

| Estimated delivery distance | Fee   |
|---------------------|-------|
| 0 mi                | $2.00 |
| 0.1 mi              | $2.50 |
| 0.25 mi             | $2.50 |
| 0.3 mi              | $3.00 |
| 1.0 mi              | $4.00 |
| 2.0 mi or more      | $6.00 (cap) |

Tip: from `0` to `50` dollars, at most 2 decimal places. The app offers $0/$1/$2/$3/custom.

## Errors

Every error uses the same shape:

```json
{
  "error": {
    "code": "validation_error",
    "message": "tip must be a number between 0 and 50",
    "details": [{ "field": "tip", "message": "must be a number between 0 and 50" }]
  }
}
```

`details` appears only for `validation_error`.

| HTTP | `code`               | When                                                        |
|------|----------------------|-------------------------------------------------------------|
| 400  | `validation_error`   | Missing or invalid fields, malformed JSON, bad query params |
| 403  | `forbidden`          | Wrong user for this action (for example, not the order's courier) |
| 404  | `not_found`          | Unknown user, order, courier or route                       |
| 409  | `email_taken`        | `POST /users` with an email that already exists             |
| 409  | `already_accepted`   | Another courier already accepted the order                  |
| 409  | `courier_busy`       | Courier already has an active (accepted or picked_up) delivery |
| 409  | `invalid_transition` | Status change not allowed from the current status           |
| 500  | `internal_error`     | Unexpected server error                                     |

## Endpoints

### `GET /health`

`200 {"status": "ok"}`

### `GET /locations`

Lists the shared campus catalog, sorted by distance from the Union. Each location also includes `demoXMiles`, `demoYMiles`, and `category` (`campus`, `residence_hall`, or `apartment`). These are approximate demo offsets, not GPS coordinates. Source details: [locations.md](locations.md).

`200`
```json
[
  { "id": "union", "name": "LSU Student Union", "distanceFromUnionMiles": 0 },
  { "id": "middleton-library", "name": "Middleton Library", "distanceFromUnionMiles": 0.2 }
]
```

### `POST /users`

Creates a user (used by the role-selection / login screen).

Request:
```json
{ "name": "Alex Customer", "role": "customer", "email": "alex@example.edu" }
```
`email` is optional.

`201` returns the User. Errors: `400 validation_error`, `409 email_taken`.

### `GET /users/:id`

`200` returns the User. Errors: `400` (id is not a positive integer), `404 not_found`.

### `POST /orders`

Customer creates a delivery request.

Request:
```json
{
  "customerId": 1,
  "pickupLocation": "union",
  "dropoffLocation": "west-campus-apts",
  "tip": 2,
  "orderName": "Alex Customer",
  "pickupRestaurant": "Chick-fil-A",
  "pawPointsOrderNumber": "PP-10442"
}
```

Rules:
- `customerId` must be an existing user with role `customer`.
- `pickupLocation` and `dropoffLocation` must be known location IDs and must be different.
- `tip` is optional (default `0`), from 0 to 50, at most 2 decimals.
- `pawPointsOrderNumber` is required, 1-40 chars, for mobile orders. Set `isMobileOrder: false` for Panera or other restaurants outside LSU Dining; the number may then be omitted or empty (maximum 40 chars). `isMobileOrder` defaults to true for existing clients.
- `orderName` and `pickupRestaurant` are optional for older clients; when provided they must be nonblank strings of 1–100 chars. The customer app requires both.

`201` returns the Order with `status: "requested"`.
Errors: `400 validation_error`, `404 not_found` (no user with that id, or the user is not a customer).

### `GET /orders`

Lists orders, newest first. Filters can be combined:

| Query        | Example                         | Meaning                          |
|--------------|---------------------------------|----------------------------------|
| `customerId` | `/orders?customerId=1`          | A customer's orders              |
| `courierId`  | `/orders?courierId=3`           | Orders a courier has accepted    |
| `status`     | `/orders?status=requested`      | Courier "Available" list         |
|              | `/orders?courierId=3&status=accepted,picked_up` | Comma-separated list of statuses |

`200` returns an array of Orders (may be empty). Errors: `400 validation_error`.

### `GET /orders/:id`

`200` returns the Order. Errors: `400`, `404 not_found`.

### `PATCH /orders/:id/accept`

Courier accepts a requested order. This is atomic: if two couriers accept at the same
time, exactly one gets `200` and the other gets `409 already_accepted`.

Request:
```json
{ "courierId": 3 }
```

`200` returns the Order with `status: "accepted"` and `courierId: 3`.

Errors:
- `400 validation_error`
- `404 not_found` (order or courier doesn't exist, or the user is not a courier)
- `409 already_accepted` (order is no longer `requested`)
- `409 courier_busy` (courier already has an active delivery)

### `PATCH /orders/:id/status`

Moves an order to the next status. Use `/accept` to accept, not this endpoint.

Request (courier):
```json
{ "status": "picked_up", "courierId": 3 }
```
```json
{ "status": "delivered", "courierId": 3 }
```

Request (customer cancelling):
```json
{ "status": "cancelled", "customerId": 1 }
```

Rules:
- `picked_up` and `delivered` need the `courierId` of the courier who accepted the order.
- `cancelled` needs the `customerId` of the order's customer, and only works while
  the order is still `requested`.
- When an order becomes `delivered`, its `totalPay` is added to the courier's `earnings`
  in the same database transaction.

`200` returns the updated Order.
Errors: `400 validation_error`, `403 forbidden`, `404 not_found`, `409 invalid_transition`.

### `GET /couriers/:id/earnings`

Courier's demo balance and completed deliveries, newest first.

`200`
```json
{
  "courierId": 3,
  "earnings": 10.5,
  "deliveryCount": 2,
  "deliveries": [
    {
      "orderId": 12,
      "pickupLocation": "union",
      "pickupLocationName": "LSU Student Union",
      "dropoffLocation": "west-campus-apts",
      "dropoffLocationName": "West Campus Apartments",
      "deliveryFee": 4.0,
      "tip": 2.0,
      "totalPay": 6.0,
      "deliveredAt": "2026-10-16T18:30:00.000Z"
    }
  ]
}
```

Errors: `400`, `404 not_found` (no courier with that id).

### `DELETE /orders/:id`

Permanently deletes a request while it is still `requested`. Body: `{ "customerId": 1 }`.
Returns `204` with no body. The request disappears from every list, including history; this is distinct from cancellation. Ownership and status are checked in the same SQLite write transaction as deletion.

Errors: `400 validation_error` (invalid IDs/body), `403 forbidden` (another customer), `404 not_found`, `409 invalid_transition` (accepted, picked up, delivered, or cancelled). Fulfilled orders cannot be deleted through this endpoint and remain in Past deliveries.

## Class-demo identity

The API currently trusts supplied user IDs and has no password authentication. Flutter creates a customer with `POST /users`, remembers the returned unique ID per normalized welcome-screen name and API origin on the device, and verifies the saved ID with `GET /users/:id` when reopening the profile. Matching names on different devices are separate demo profiles. A server reset requires restarting the app; stale/mismatched saved IDs are checked before reuse. This is not production authentication.
