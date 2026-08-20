# System Map

Updated: 2026-08-17

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

The production customer menu and Dashboard POS catalogue browser contain no runtime hardcoded catalogue fallback. Physical validation proved a real Owner catalogue price mutation propagated to the installed Android customer app.

## Customer order flow

```text
Flutter cart selections
 -> quote_order(ids/qty/intent only)
 -> server revalidates catalogue and calculates integer-sen totals
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

The Dashboard renders the server quote as commercial authority, keeps one `clientRequestId` across retry of the same intended placement, clears the sale only after persisted success, and labels the current non-processor path `Pay at counter`/unpaid. Preview/local cart state is selection state only and is never a live order fallback.

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

Branch hours, closures and capacity are not yet authoritative and are not presented as backend guarantees.

Dashboard operational projection:

```text
GET /api/v1/orders (server snapshots)
 -> scheduled + overdue/due => Active (persisted status stays scheduled)
 -> scheduled + future => Scheduled
 -> ready => Ready
 -> completed/cancelled => History
 -> explicit Start preparing + expectedVersion => persisted preparing
```

The browser may update cosmetic lateness copy between polls, but backend `serverNow`/`scheduleState` determine workload placement.

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

Because employee JWTs remain HttpOnly, React does not expose a staff token to connect directly to Supabase Realtime. The Orders rail polls the same-origin BFF about every 2.5 seconds, invalidates after place/status mutations, shows legal next actions only and refetches on version conflict. Customer Flutter uses owner-scoped Supabase Realtime directly and re-fetches the authorized order snapshot.

## Validated cross-client state

Physical/manual validation proved:

- Android release connectivity and customer signup;
- trusted profile/member provisioning visible in protected Dashboard Members;
- real Owner Admin login;
- Owner catalogue mutation → installed Android catalogue refresh.

Final live order E2E on 2026-08-17 proved:

```text
customer Auth/member
 -> quote Sandwich ASAP at 1,290 sen
 -> place order 100006 / 7cf027dc-3ff0-4604-a3fd-c7a943aac603
 -> Dashboard observes confirmed v1
 -> Dashboard preparing v2
 -> customer authorized refresh sees preparing
 -> Dashboard ready v3
 -> customer refresh sees ready
 -> Dashboard completed v4
 -> customer refresh sees completed
```

One completed E2E order remains intentionally retained as evidence.

## Deployment state

Hosted/Vercel deployment remains **DEFERRED** and is not a blocker for the accepted local Dashboard PC + cloud Supabase + installed Android phone topology. Do not claim hosted BFF operation until its runtime configuration/routes are separately proven. Service-role credentials remain prohibited from Flutter/Vite/browser code.

## Deferred authority

Real payments/refunds, loyalty, inventory depletion, discounts/promotions, tax/accounting, revenue analytics, branch scheduling/capacity, branch-scoped operations, delivery and hosted production release operations remain separate trusted tasks.

Live staff POS entry therefore uses global single-café order scope and does not call terminal/current-shift APIs. Terminal and shift lifecycle remains preview-only until a separate authoritative domain is approved.
