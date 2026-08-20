# Order and Scheduling Contract

**Current task extension:** `TASK-SCHEDULED-OPS-001`

**Status:** backend extension IMPLEMENTED and verified; Dashboard operational UI integration remains PARTIAL until the matching Dashboard branch is completed.

ADR-0010 remains authoritative for order identity, quote/persistence, scheduling and fulfilment-state ownership. TASK-SCHEDULED-OPS-001 extends the operational scheduled-order contract without changing the persisted fulfilment state machine.

## Backend authority

Live Supabase project: `eswovqxqzfevcdwwcmuh`.

Canonical migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

Relevant migrations:

- `20260812182212_create_authoritative_orders_and_scheduling.sql`
- `20260812183029_index_order_foreign_keys.sql`
- `20260820151421_add_scheduled_order_preparation_window.sql`

Persistent resources:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

Realtime publication remains `catalogue_revision` + `orders`; staff Dashboard clients continue to use the same-origin BFF/polling model because the employee bearer token remains HttpOnly.

## Trusted order payload

Clients submit only selection and fulfilment intent:

```json
{
  "clientRequestId": "UUID-required-for-placement",
  "fulfillmentType": "asap | scheduled",
  "requestedPickupAt": "ISO-8601 timestamptz only when scheduled",
  "items": [
    {
      "itemId": "catalogue item UUID",
      "variantId": "variant UUID when required",
      "addOnIds": ["compatible add-on UUID"],
      "quantity": 1,
      "note": "optional <= 300 chars"
    }
  ]
}
```

Clients do not submit trusted prices, totals, names, member/customer IDs, order numbers, `prepareAt`, `scheduleState`, fulfilment status, role or payment state.

## Authoritative quote

`quote_order(jsonb)` remains the commercial/scheduling validator. It re-prices from the current catalogue and validates scheduled timestamps against server time and the customer-selectable scheduling policy.

Unknown client price/total fields remain ignored.

## Scheduling policy

Read RPC:

`get_ordering_policy()`

Current live policy:

```text
timezone: Asia/Kuala_Lumpur
scheduleEnabled: true
minimumLeadMinutes: 15
preparationLeadMinutes: 15
slotIntervalMinutes: 15
maximumAdvanceDays: 7
```

### Customer minimum lead

`minimumLeadMinutes` controls the earliest scheduled pickup a customer/POS user may request.

### Operational preparation lead

`preparationLeadMinutes` controls when café operations should begin a scheduled order. It is a separate backend-owned value.

Invariant:

```text
0 <= preparationLeadMinutes <= minimumLeadMinutes
```

This prevents accepting an order whose preparation due time is already earlier than the earliest allowed customer placement horizon.

Admin/Owner may update policy through the existing trusted `save_ordering_policy(jsonb)` / Dashboard Admin BFF boundary. Staff may not mutate policy.

Branch-specific hours, closures and capacity remain unimplemented and must not be fabricated by clients.

## Scheduled-order preparation snapshot

Scheduled orders now persist:

`orders.prepare_at timestamptz`

At placement:

```text
prepareAt = requestedPickupAt - preparationLeadMinutes
```

Properties:

- backend-generated only;
- null for ASAP orders;
- snapshotted at placement;
- included in the protected immutable order fields;
- later preparation-policy changes do not rewrite accepted orders.

Existing scheduled orders were backfilled from the live policy without changing their persisted status.

## Operational schedule state

Authorized order snapshots now add:

```text
prepareAt
authoritative serverNow
scheduleState = future | due | overdue | null
```

For an order with `fulfillmentType=scheduled` and persisted `status=scheduled`:

```text
requestedPickupAt < serverNow  -> scheduleState=overdue
prepareAt <= serverNow          -> scheduleState=due
otherwise                       -> scheduleState=future
```

For non-scheduled or already-transitioned orders, `scheduleState=null`.

`scheduleState` is **not** a fulfilment status and is not persisted as a new lifecycle state. It is server-derived operational classification.

The Dashboard must use the backend `scheduleState` for future/due/overdue queue classification. It must not use the workstation/device clock alone as business authority. Local time may only animate/display a countdown between authoritative refreshes.

## Persisted fulfilment state machine

Initial persisted state remains:

```text
ASAP      -> confirmed
scheduled -> scheduled
```

Legal staff transitions remain:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready     -> completed
```

`completed` and `cancelled` remain terminal.

No cron/timer/migration auto-transitions `scheduled -> preparing` when `prepareAt` is reached. Reaching `prepareAt` only makes the order operationally `due` in server responses. An authorized staff action is still required to persist **Start preparing**, using the current `statusVersion`.

This distinction is mandatory: “the kitchen should start now” is not proof that a human actually started preparation.

## Customer API

Customer Flutter continues to use:

- `place_customer_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- owner-scoped `orders` Realtime invalidation + authorized refetch.

The additional snapshot fields are backward-compatible with the current customer parser; customer fulfilment UI continues to display persisted status and does not manufacture progression.

## Dashboard/POS API

Existing same-origin endpoints remain:

```text
GET  /api/v1/orders/policy
GET  /api/v1/orders
GET  /api/v1/orders/detail?id=<uuid>
POST /api/v1/orders/quote
POST /api/v1/orders/place
POST /api/v1/orders/status
POST /api/v1/admin/orders/policy
```

The order BFF still forwards the authenticated caller JWT and never exposes a service-role credential or employee bearer token to React.

Dashboard clients must parse the new fields:

```text
OrderingPolicy.preparationLeadMinutes
OrderSnapshot.prepareAt
OrderSnapshot.serverNow
OrderSnapshot.scheduleState
```

## Required operational Dashboard classification

AIDA's intended POS workload model is:

### Active

- persisted `confirmed`;
- persisted `preparing`;
- persisted `scheduled` + `scheduleState=due`;
- persisted `scheduled` + `scheduleState=overdue`, promoted first.

### Scheduled

- persisted `scheduled` + `scheduleState=future`;
- sorted by `prepareAt`, then pickup time;
- group Today / Tomorrow / Later where useful.

### Ready

- persisted `ready`.

### History

- persisted `completed`;
- persisted `cancelled`.

A due/overdue order keeps persisted `status=scheduled` until staff explicitly selects **Start preparing**. Existing optimistic-concurrency/version-conflict behavior remains mandatory.

## Payment boundary

There is still no trusted payment processor/payment-settlement state. Current flow remains explicit `Pay at counter` / unpaid. Fulfilment completion does not prove payment settlement.

## Staff single-café scope

Current order authorization still allows staff-or-above to see the global queue because branch-scoped backend authority is deferred.

The Dashboard must not block this accepted live Sale/Orders path on fake/nonexistent terminal/shift authority. Terminal, sales-point, branch assignment and shifts remain separate trusted domains. Preview simulation may remain preview-only.

## Verification

Existing canonical order regression remains valid.

TASK-SCHEDULED-OPS-001 adds:

`supabase/tests/scheduled_order_operations_integration.sql`

Live transactional result: PASS.

It verifies:

- preparation schema and bounds;
- scheduled placement `prepareAt`;
- server-derived future classification;
- idempotent retry preserving `prepareAt`;
- Admin preparation-policy updates;
- rejection when preparation lead exceeds customer minimum lead;
- scheduled POS placement snapshots the current preparation lead;
- later policy changes do not rewrite existing orders.

## Deferred domains

Still separate bounded tasks:

- branch-specific hours/closures/capacity
- branch-scoped order visibility
- terminal/sales-point authority
- shift/cash authority
- real payment/refunds
- loyalty
- inventory
- promotions/discounts
- tax/accounting/reporting
- delivery
- hosted production operations
