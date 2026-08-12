# POS/Admin State and Data Flow

Updated: 2026-08-13

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

Browser code never receives a service-role credential. A refreshed employee access cookie is reused by the BFF when the auth layer rotates the session.

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

The POS cart remains local selection state only:

```text
item/variant/add-on IDs + quantity + note
 -> local POS cart interaction
 -> POST /api/v1/orders/quote
 -> BFF validates employee session
 -> caller JWT -> quote_order
 -> server revalidates shared catalogue
 -> authoritative line/subtotal/total sen
```

Do not use preview/local total arithmetic as persisted order authority after integration.

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

Use the same `clientRequestId` for retries of the same intended placement. Generate another UUID for a genuinely new order.

Clear/reset the POS sale only after successful backend placement.

## Staff order queue

```text
order board active
 -> GET /api/v1/orders
 -> TanStack Query/cache
 -> render Scheduled / Confirmed / Preparing / Ready
 -> short safe refetch interval
```

The staff bearer token is intentionally unavailable to JavaScript because ADR-0008 keeps it HttpOnly. Do not weaken that security model to get direct Supabase Realtime in React.

For the current demo, the live-feeling dashboard queue should:

- refetch `/api/v1/orders` every ~2–3 seconds while visible;
- invalidate/refetch immediately after POS placement;
- invalidate/refetch immediately after a status transition;
- refetch on window focus/reconnection if supported by the existing query layer.

A future server-side event bridge may replace polling without exposing employee tokens.

## Status transition

```text
staff clicks next action
 -> current order.statusVersion
 -> POST /api/v1/orders/status
 -> BFF same-origin/session check
 -> caller JWT
 -> transition_order_status(expectedVersion)
 -> legal state change + order_events
 -> response returns updated snapshot/version
 -> invalidate order queue
```

HTTP 409 `ORDER_VERSION_CONFLICT` means another update already won. Refetch; do not blindly replay stale state.

Legal progression:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Completed/cancelled are terminal.

## Customer propagation

```text
staff status transition
 -> orders row changes
 -> Supabase Realtime
 -> customer owner-scoped subscription
 -> Flutter refetches get_order(orderId)
 -> customer status UI changes
```

The dashboard itself does not need direct browser Realtime for this customer propagation; the database event is emitted by the persisted status mutation.

## Payment boundary

There is no trusted payment processor state. Integrated demo order placement must use an explicit `Pay at counter`/unpaid path. Preview tender/payment UI must not be treated as settlement evidence.

## Deferred data flows

Loyalty, inventory depletion, refunds, tax/accounting, branch capacity/hours, reporting/revenue and delivery remain separate authority boundaries.