# Order and Scheduling Contract

**Task:** `TASK-DEMO-ORDER-001`

**Closeout status (2026-08-17): COMPLETE.** The authoritative backend, customer Flutter integration, Dashboard POS/order-board integration and final supported cross-client order lifecycle are implemented and validated. ADR-0010 remains authoritative for architectural decisions.

## Backend state

Live Supabase project: `eswovqxqzfevcdwwcmuh`.

Canonical migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

Persistent resources:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

Realtime publication contains:

- `catalogue_revision`
- `orders`

Only `orders` is required for order-status Realtime. After a permitted order row changes, customer clients re-fetch the authorized full snapshot; immutable lines/add-ons are not separately published. Dashboard employee clients use the same-origin BFF queue/polling model because the staff bearer token remains HttpOnly.

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

Do not send or trust client-derived item names, prices, line totals, subtotal, total, member IDs, customer IDs, order numbers, status, role or payment completion state. Unknown price/total fields are ignored by the quote engine.

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

Each returned line includes server-resolved item/variant/add-on snapshots and integer-sen prices.

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

For `scheduled`, the backend rejects timestamps that are missing, too soon, beyond the horizon or not aligned to a local 15-minute slot. Frontends derive selectable slots from `serverNow` + policy rather than a device-clock-only hardcode.

Branch opening hours/closures/capacity are not modeled. Do not invent branch-aware scheduling claims.

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

A customer can read only their own orders and cannot create POS orders, change status or perform direct table DML.

Customer integration rules:

- quote before placement;
- server quote total is commercial authority;
- reuse the same `clientRequestId` for retry of the same intended placement;
- clear cart only after persisted placement;
- display persisted order number/status/history/detail;
- use owner-scoped `orders` Realtime as invalidation, followed by authorized refetch;
- never manufacture fulfilment status with a local timer.

## Dashboard/POS BFF API

Dashboard browser code uses same-origin endpoints and does not call privileged order RPCs with browser-stored employee tokens.

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

A version conflict requires refetch before another transition.

Dashboard integration rules:

- active POS quote/place submits catalogue IDs, quantity, optional note and fulfilment intent only;
- server quote response is authoritative for persisted commercial totals;
- one `clientRequestId` is reused for retry of the same placement;
- ASAP/scheduled choices derive from server policy;
- cart clears only after successful persisted placement;
- live Orders rail polls/refetches the BFF at a short interval and has no preview-order fallback;
- status controls expose legal next states only and submit current `statusVersion`;
- HTTP 409 version conflict triggers refetch rather than stale overwrite.

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

Customer UI displays persisted backend status.

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

Each line contains immutable item/variant/add-on naming and price snapshots, quantity, note and line total.

## Payment boundary

There is no payment processor or trusted payment state in this tranche.

Frontend checkout uses an explicitly non-processor `Pay at counter`/unpaid flow. It must not imply Cash/Card/E-wallet/Student Wallet has actually been processed or manufacture paid/payment-received state.

Order completion means fulfilment completion, not verified payment settlement.

## Final completion proof

The required cross-client chain was completed on 2026-08-17 through supported boundaries:

```text
customer Auth + active member
-> quote Sandwich ASAP at 1,290 sen
-> place_customer_order
-> persisted order 100006 / 7cf027dc-3ff0-4604-a3fd-c7a943aac603, confirmed v1
-> Dashboard same-origin Owner session observes exact order
-> preparing v2
-> customer-authorized get_order sees preparing
-> ready v3
-> customer-authorized get_order sees ready
-> completed v4
-> customer-authorized get_order sees completed
```

Independent database verification confirms the retained order is `completed` at version 4 and the event ledger records created/confirmed → preparing → ready → completed.

No service role, direct SQL order insert, password reset, browser employee bearer-token persistence or client-trusted price/status was used. Approved credentials were process-local and removed after the E2E.

Toolchain and ADR-0004 completion gates for this contract's current scope pass. The order/scheduling implementation is no longer `PARTIAL`.

## Deferred domains

Do not couple current order authority to unimplemented domains:

- payment capture/refunds
- promotions/discount engine
- loyalty earning/redemption
- inventory depletion
- tax/accounting
- delivery
- branch-specific schedule hours/capacity and branch-scoped queues
- revenue/reporting side effects
- hosted production deployment/release operations

Those domains build on trusted orders later.
