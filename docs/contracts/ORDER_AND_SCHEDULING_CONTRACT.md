# Order and Scheduling Contract

**Task:** `TASK-DEMO-ORDER-001`

This contract is the implementation handoff from the completed shared backend to the customer and dashboard frontends. ADR-0010 is authoritative for architectural decisions.

## Backend state

Live Supabase project: `eswovqxqzfevcdwwcmuh`.

Canonical migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

New persistent resources:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

Realtime publication now contains:

- `catalogue_revision`
- `orders`

Only `orders` is required for order-status Realtime. After a permitted order row changes, clients re-fetch the authorized full snapshot; immutable lines/add-ons are not separately published.

## Trusted payload

Clients may submit only selection/intent data:

```json
{
  "clientRequestId": "UUID-required-for-placement",
  "fulfillmentType": "asap | scheduled",
  "requestedPickupAt": "ISO-8601 timestamptz only when scheduled",
  "items": [
    {
      "itemId": "catalogue item UUID",
      "variantId": "variant UUID when the item has available variants",
      "addOnIds": ["compatible addon UUID"],
      "quantity": 1,
      "note": "optional <= 300 chars"
    }
  ]
}
```

Do not send or trust client-derived item names, prices, line totals, subtotal, total, member IDs, customer IDs, order numbers, status, role, or payment completion state. Unknown price/total fields are ignored by the quote engine.

Limits:

- 1–50 lines per order
- quantity 1–20 per line
- at most 20 distinct add-ons per line
- note <= 300 chars

## Authoritative quote

RPC:

```text
quote_order(p_payload jsonb)
```

Executable by `anon` and `authenticated` because it performs no write and exposes only publicly orderable catalogue data.

It validates current category/item publication/availability, variant ownership/availability, compatible add-ons, quantity/note bounds and scheduling policy, then returns:

```text
pricingVersion
currency = MYR
subtotalSen
totalSen
fulfillmentType
requestedPickupAt
serverNow
schedulePolicy
lines[]
```

Each returned line includes the server-resolved item/variant/add-on snapshots and integer-sen prices.

## Scheduling policy

Read RPC:

```text
get_ordering_policy()
```

Current defaults:

```text
timezone: Asia/Kuala_Lumpur
scheduleEnabled: true
minimumLeadMinutes: 15
slotIntervalMinutes: 15
maximumAdvanceDays: 7
```

For `asap`, `requestedPickupAt` must be null/omitted.

For `scheduled`, the backend rejects timestamps that are missing, too soon, beyond the horizon, or not aligned to a local 15-minute slot. Frontends must derive selectable slots from `serverNow` + policy, not hardcode a device-clock-only list.

Branch opening hours/closures/capacity are not yet modeled. Do not invent branch-aware scheduling UI or claims.

Admin/owner schedule-policy mutation RPC:

```text
save_ordering_policy(p_payload jsonb)
```

Dashboard BFF endpoint:

```text
POST /api/v1/admin/orders/policy
```

## Customer order API

Customer Flutter uses its authenticated Supabase session directly.

Place:

```text
place_customer_order(p_payload jsonb)
```

Requirements:

- authenticated trusted role = customer
- active member row exists
- customer/member identity is derived server-side
- `clientRequestId` is required

Read one:

```text
get_order(p_order_id uuid)
```

History:

```text
get_my_orders(p_limit integer default 20)
```

A customer can read only their own orders and cannot create POS orders, change status, or perform direct table DML.

## Dashboard/POS BFF API

Dashboard browser code must use same-origin endpoints; it must not call privileged order RPCs with browser-stored employee tokens.

Public policy:

```text
GET /api/v1/orders/policy
```

Employee queue:

```text
GET /api/v1/orders
GET /api/v1/orders?status=scheduled&status=preparing&limit=100
```

Employee detail:

```text
GET /api/v1/orders/detail?id=<order UUID>
```

Server quote:

```text
POST /api/v1/orders/quote
<body = trusted selection/intent payload>
```

POS place:

```text
POST /api/v1/orders/place
<body includes clientRequestId>
```

Status transition:

```text
POST /api/v1/orders/status
{
  "orderId": "UUID",
  "toStatus": "preparing | ready | completed | cancelled",
  "expectedVersion": 1,
  "reason": "optional"
}
```

All employee endpoints validate the existing HttpOnly session and forward the caller JWT. State-changing requests require same origin. No service-role key is used.

BFF conflict codes:

```text
ORDER_IDEMPOTENCY_CONFLICT -> HTTP 409
ORDER_VERSION_CONFLICT     -> HTTP 409
```

A version conflict means re-fetch the order before another transition.

## Order states

Initial state:

```text
ASAP      -> confirmed
scheduled -> scheduled
```

Legal staff transitions:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready     -> completed
```

`completed` and `cancelled` are terminal.

Customer UI must display persisted backend status. The existing fake timer-driven confirmation/status sequence must be removed when the frontend is integrated.

## Snapshot fields

Authorized order snapshots contain:

```text
id
orderNumber
source
customerUserId
memberId
fulfillmentType
requestedPickupAt
status
statusVersion
currency
pricingVersion
subtotalSen
totalSen
createdAt
updatedAt
statusUpdatedAt
preparingAt
readyAt
completedAt
cancelledAt
lines[]
```

Each line contains immutable item/variant/add-on naming and price snapshots, quantity, note, and line total.

## Payment boundary

There is no payment processor or trusted payment state in this task.

Frontend demo checkout must use an explicitly non-processor flow such as `Pay at counter`. Remove or disable copy that implies Cash/Card/E-wallet/Student Wallet has actually been processed. Do not manufacture paid/payment-received state.

## Deferred domains

Do not couple frontend work to unimplemented authority for:

- payment capture/refunds
- promotions/discount engine
- loyalty earning/redemption
- inventory depletion
- tax/accounting
- delivery
- branch-specific schedule hours/capacity
- revenue/reporting side effects

Those will build on trusted orders later.

## Required frontend completion proof

The overall feature remains `PARTIAL` until both frontends are implemented and prove:

```text
customer app quote
-> ASAP or scheduled placement
-> persisted Supabase order
-> dashboard queue receives/re-fetches it
-> staff changes status
-> customer running app receives authorized Realtime order change
-> customer re-fetches order
-> visible status updates without a fake timer
```

Toolchain tests and ADR-0004 completion gates still apply.
