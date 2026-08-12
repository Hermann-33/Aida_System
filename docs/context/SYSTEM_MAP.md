# System Map

Updated: 2026-08-13

| System | Runtime | Current trusted source |
|---|---|---|
| Customer | Flutter/Riverpod | Supabase Auth/member + shared catalogue + customer order RPCs |
| Dashboard/Admin/POS | React/Vite | same-origin employee BFF + shared catalogue/member/order RPCs |
| Backend | Supabase | Auth, Postgres, FORCE RLS, controlled RPCs, Realtime |

## Catalogue flow

```text
Admin Menu
 -> same-origin BFF cookie session
 -> admin/owner caller JWT
 -> save_catalogue_* RPC
 -> catalogue tables + audit + revision bump
 -> catalogue_revision Realtime
 -> Flutter invalidates catalogue snapshot
 -> get_catalogue() under RLS
 -> updated menu shown
```

The production customer menu and dashboard POS catalogue browser contain no runtime hardcoded catalogue fallback.

## Customer order flow

```text
Flutter cart selections
 -> quote_order(ids/qty/intent only)
 -> server revalidates catalogue and calculates MYR sen totals
 -> customer chooses ASAP or server-policy-aligned scheduled pickup
 -> place_customer_order(clientRequestId + selections)
 -> trusted customer/member derived from auth session
 -> orders + immutable order_lines/order_line_addons snapshots
 -> order_events(created)
 -> order returned with server order number/status
```

The customer cannot submit trusted prices/totals/order numbers/member IDs/status. Placement requires an active member and is idempotent per authenticated actor + `clientRequestId`.

## POS order flow

```text
POS cart selections
 -> POST /api/v1/orders/quote
 -> employee HttpOnly session validated by BFF
 -> caller JWT -> quote_order
 -> authoritative quote returned
 -> POST /api/v1/orders/place
 -> caller JWT -> place_pos_order
 -> persisted guest POS order
 -> GET /api/v1/orders queue refresh
```

The browser's preview/local cart remains selection state only. Persisted price/total/order identity comes from the backend.

## Scheduled pickup

```text
get_ordering_policy
 -> Asia/Kuala_Lumpur
 -> 15-minute minimum lead
 -> 15-minute slots
 -> 7-day horizon
 -> selected scheduled timestamp
 -> quote_order validates server time/horizon/slot
 -> scheduled order persisted with status=scheduled
```

Branch hours, closures and capacity are not yet authoritative and therefore are not presented as backend guarantees.

## Fulfilment/status flow

```text
Dashboard order board
 -> GET /api/v1/orders
 -> staff selects legal next state
 -> POST /api/v1/orders/status + expectedVersion
 -> transition_order_status
 -> orders row/statusVersion updated
 -> order_events appended
 -> customer receives authorized orders Realtime event
 -> Flutter calls get_order(orderId)
 -> UI renders persisted status
```

Legal flow is `confirmed|scheduled -> preparing -> ready -> completed`, with cancellation allowed before ready. Completed/cancelled are terminal. Stale `statusVersion` changes fail.

Because employee JWTs remain HttpOnly, the React dashboard must not expose a staff token to connect directly to Supabase Realtime. For the current demo it should poll/refetch the same-origin `/api/v1/orders` queue at a short safe interval and invalidate immediately after local mutations. Customer Flutter can use owner-scoped Supabase Realtime directly.

## Deployment state

Vercel project `aida-system-dashboard` exists and source builds there, but the current preview BFF is not operational until an operator configures:

- `AIDA_SUPABASE_URL`
- `AIDA_SUPABASE_PUBLISHABLE_KEY`

A service-role key remains prohibited from Vite/browser code. Local dashboard + cloud Supabase + installed customer app can be used for demo/E2E once approved staff/customer identities exist.

## Deferred authority

Real payments/refunds, loyalty, inventory depletion, discounts, tax/accounting, revenue analytics, delivery, branch scheduling/capacity and branch-scoped operations remain separate trusted tasks.