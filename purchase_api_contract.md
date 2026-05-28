# Purchase API Contract

## Endpoint

```
POST /api/purchases
```

---

## Request

### Headers

| Header | Value | Notes |
|---|---|---|
| `Content-Type` | `application/json` | Required |
| `Authorization` | `Bearer <token>` | Required in production; omitted in this prototype |
| `Idempotency-Key` | `<uuid>` | Recommended — allows safe retry without double-charging |

### Body

The client maps each `PurchaseItem` from the local cart directly to a `{food_item_id, quantity}` pair. Prices are intentionally omitted — the server resolves them from the catalogue to prevent client-side price tampering.

```json
{
  "items": [
    {
      "food_item_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "quantity": 2
    },
    {
      "food_item_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "quantity": 1
    }
  ]
}
```

### Field definitions

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array | Yes | Must contain at least one entry |
| `items[].food_item_id` | string (UUID) | Yes | Must match an existing food item |
| `items[].quantity` | integer | Yes | Must be ≥ 1 |

---

## Responses

### 201 Created — purchase confirmed

```json
{
  "order_id": "f3a1b2c3-d4e5-6789-abcd-ef0123456789",
  "status": "confirmed",
  "items": [
    {
      "food_item_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "name": "Organic Bananas",
      "unit_price": 1.29,
      "quantity": 2,
      "line_total": 2.58
    },
    {
      "food_item_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "name": "Sourdough Bread",
      "unit_price": 5.49,
      "quantity": 1,
      "line_total": 5.49
    }
  ],
  "total": 8.07,
  "currency": "USD",
  "purchased_at": "2026-05-28T14:30:00Z"
}
```

The client uses `order_id` to display a confirmation reference and `total` to show a receipt summary. `purchased_at` is an ISO 8601 UTC timestamp.

---

### 400 Bad Request — validation failed

Returned when the request body is malformed, `items` is empty, or a `quantity` is less than 1.

```json
{
  "error": "validation_error",
  "message": "Cart must contain at least one item.",
  "details": [
    {
      "field": "items",
      "issue": "must not be empty"
    }
  ]
}
```

---

### 404 Not Found — unknown food item

Returned when a `food_item_id` does not match any item in the catalogue.

```json
{
  "error": "not_found",
  "message": "One or more food items could not be found.",
  "details": [
    {
      "field": "items[0].food_item_id",
      "issue": "a1b2c3d4-e5f6-7890-abcd-ef1234567890 does not exist"
    }
  ]
}
```

---

### 409 Conflict — item unavailable

Returned when a requested item exists but is currently out of stock. Included here for forward compatibility; not required for the current catalogue.

```json
{
  "error": "item_unavailable",
  "message": "One or more items are no longer available.",
  "details": [
    {
      "food_item_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "issue": "out_of_stock"
    }
  ]
}
```

---

### 500 Internal Server Error

```json
{
  "error": "internal_error",
  "message": "An unexpected error occurred. Please try again."
}
```

---

## Mobile client notes

**Mapping** — The local cart is `[PurchaseItem]`, where each entry already holds a `food_item_id` and a `quantity`. The client maps this directly to the `items` array — no reduction or aggregation step needed.

**Idempotency** — The client generates a UUID per purchase attempt and sends it as `Idempotency-Key`. If the network fails after the server has committed the order, retrying with the same key returns the original 201 response without creating a duplicate order.

**Error handling** — The client surfaces a user-facing message for 400 and 404 (actionable by the user) and a generic retry prompt for 409 and 500. The `message` field from the response body is used directly in all cases.

**Cart clearing** — The client clears the local cart and persisted `cart.json` only after receiving a 201. Any other status code leaves the cart intact so the user can retry.

**Price authority** — The client never sends prices. The server looks up the current catalogue price for each `food_item_id` and uses that to compute `unit_price`, `line_total`, and `total` in the response. This prevents a client from submitting an arbitrary price. If a price has changed between when the user loaded the food list and when they submit, the server's current price wins and the receipt reflects it.
