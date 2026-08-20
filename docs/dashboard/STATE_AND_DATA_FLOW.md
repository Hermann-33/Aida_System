# POS/Admin State and Data Flow

Updated: 2026-08-17

## Employee/Admin session

```text
Admin/employee login
 -> same-origin employee BFF
 -> Supabase Auth password session on server boundary
 -> trusted user_profiles role/disabled-state check
 -> HttpOnly cookies
 -> React session identity
```

The browser does not persist the employee access token. Preview identity remains explicitly non-authoritative and does not substitute for a live employee session.

## Admin Members

```text
Admin Members page
 -> employeeFetch(credentials: include)
 -> same-origin /api/v1/admin/members
 -> employee session validation
 -> caller JWT
 -> list_admin_members / RLS
 -> trusted member directory
```

Preview mode does not request/fabricate privileged member data.

## Admin catalogue

```text
AdminMenuPage / AdminMenuEditorPage
 -> catalogueClient
 -> employeeFetch(credentials: include)
 -> same-origin catalogue BFF
 -> employee session validation
 -> caller admin JWT
 -> get_catalogue / save_catalogue_* RPC
 -> Postgres + audit + revision bump
```

## POS catalogue read

```text
CounterWorkspace
 -> catalogueClient
 -> GET /api/v1/catalogue
 -> get_catalogue(public read)
 -> posCatalogue adapter
 -> categories/items/variants/compatible add-ons
```

No preview catalogue fallback is used when this request fails.

## POS cart versus authoritative quote

```text
item/variant/add-on IDs + quantity + note
 -> local POS cart interaction
 -> POST /api/v1/orders/quote
 -> BFF validates employee session
 -> caller JWT -> quote_order
 -> server revalidates shared catalogue
 -> authoritative line/subtotal/total sen
```

Local cart arithmetic is an estimate only; the returned quote is authoritative.

## ASAP / scheduled POS order

```text
GET /api/v1/orders/policy
 -> serverNow + schedule policy
 -> POS offers ASAP / Schedule for later
 -> selected timestamp + selections
 -> POST /api/v1/orders/quote
 -> backend validates schedule
 -> create one clientRequestId
 -> POST /api/v1/orders/place
 -> place_pos_order with employee caller JWT
 -> persisted guest POS order
```

The checkout reuses the same `clientRequestId` for retry of the same intended placement. A genuinely changed/new order receives a new UUID. The sale clears only after successful backend placement.

## Staff order queue

```text
order board active
 -> GET /api/v1/orders
 -> TanStack Query/cache
 -> parse prepareAt/serverNow/scheduleState without local defaults
 -> project Active / Scheduled / Ready / History
 -> render persisted Scheduled even when operationally due/overdue
 -> refetch every ~2.5 seconds
```

The staff bearer token is intentionally unavailable to JavaScript. The queue invalidates/refetches after POS placement/status changes and on supported focus/reconnection paths. There is no preview-order fallback.

## Status transition

```text
staff clicks legal next action
 -> current order.statusVersion
 -> POST /api/v1/orders/status
 -> BFF same-origin/session check
 -> caller JWT
 -> transition_order_status(expectedVersion)
 -> legal state change + order_events
 -> response returns updated snapshot/version
 -> invalidate order queue
```

HTTP 409 `ORDER_VERSION_CONFLICT` means another update already won. Refetch; do not replay stale state.

Legal progression:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Completed/cancelled are terminal.

Active priority is backend-overdue, backend-due, preparing, confirmed. Future scheduled work sorts by immutable `prepareAt` and requested pickup. **Start preparing** sends the current `statusVersion`; no React timer mutates status. A 409 invalidates queue and selected detail before the action can be offered again.

## Live staff POS entry

```text
/employee password
 -> same-origin employee BFF
 -> HttpOnly employee cookies
 -> trusted role=staff
 -> /pos
 -> live Sale + Orders (single-café/global scope)
```

Live mode performs no terminal/current-shift lookup. Preview mode separately uses session/local preview terminal and shift repositories; those values never authorize live APIs.

## Customer propagation

```text
staff status transition
 -> orders row changes
 -> Supabase Realtime
 -> customer owner-scoped subscription
 -> Flutter refetches get_order(orderId)
 -> customer UI renders persisted status
```

Final live validation on 2026-08-17 proved this chain with order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`): Dashboard observed `confirmed` v1 and persisted `preparing` v2 → `ready` v3 → `completed` v4; customer-authorized reads observed each changed status.

## Payment boundary

There is no trusted payment processor state. Integrated demo order placement uses explicit `Pay at counter`/unpaid semantics. Preview tender/payment UI is not settlement evidence.

## Deferred data flows

Loyalty, inventory depletion, refunds, tax/accounting, branch scope/capacity/hours, shifts/cash, reporting/revenue, marketing publication, delivery and hosted production operations remain separate authority boundaries.
