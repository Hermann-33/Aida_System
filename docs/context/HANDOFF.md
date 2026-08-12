# Current Handoff

Updated: 2026-08-13

## Current task

`TASK-DEMO-ORDER-001 — live ordering, scheduled pickup, POS queue, and Realtime fulfilment`

**Overall verdict:** PARTIAL under ADR-0004 because the shared backend is implemented/validated but the Flutter and React integrations are intentionally left for the next Codex frontend pass.

Shared branch in both repositories:

`codex/task-demo-order-001-order-scheduling-backend`

The branch is stacked on each repository's `codex/task-auth-003-deployed-e2e` branch. Do not alter default branches or merge this stack out of order.

## Backend implemented

### Supabase

Live project: `eswovqxqzfevcdwwcmuh`.

Canonical customer-repo migrations:

- `20260812182212_create_authoritative_orders_and_scheduling.sql`
- `20260812183029_index_order_foreign_keys.sql`

They create and secure:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

Public order RPCs:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `place_pos_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- `list_orders(text[], integer)`
- `transition_order_status(uuid,text,bigint,text)`
- `save_ordering_policy(jsonb)`

Clients submit IDs/quantities/notes/fulfilment intent only. The backend validates the current shared catalogue and owns price, totals, order IDs/numbers, trusted identity, status and schedule acceptance. Historical line/add-on commercial data is persisted as immutable snapshots.

Placement requires a `clientRequestId` UUID. Identical retries return the same order; using the same key for different content fails.

### Scheduling

Current server policy:

- timezone `Asia/Kuala_Lumpur`
- enabled
- minimum lead 15 minutes
- slot interval 15 minutes
- maximum advance 7 days

Branch-hours/closures/capacity are not yet authoritative and therefore are not enforced or claimed by this task.

### Fulfilment / Realtime

Statuses:

`confirmed`, `scheduled`, `preparing`, `ready`, `completed`, `cancelled`.

Legal staff transitions:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Transitions use expected `statusVersion` concurrency and append `order_events` evidence.

`orders` is published to Supabase Realtime alongside the existing `catalogue_revision`. Clients re-fetch an authorized full snapshot after an order-header change.

### Dashboard server/BFF

No React UI was changed.

New server endpoints:

- `GET /api/v1/orders/policy`
- `GET /api/v1/orders`
- `GET /api/v1/orders/detail?id=<uuid>`
- `POST /api/v1/orders/quote`
- `POST /api/v1/orders/place`
- `POST /api/v1/orders/status`
- `POST /api/v1/admin/orders/policy`

Privileged calls use the existing HttpOnly employee session, same-origin POSTs, the publishable Supabase project key, and the caller JWT. No service-role credential or employee token is exposed to browser JavaScript.

## Backend validation evidence

Canonical `supabase/tests/order_integration.sql` passed transactionally against the live project.

Proved:

- forged client price/total values are ignored;
- `2 × Salted Caramel Latte / Medium / Oat Milk` resolves from live catalogue truth to 3080 sen;
- incompatible add-ons and invalid past schedules fail;
- customer scheduled placement persists trusted immutable snapshots;
- same `clientRequestId` retry does not duplicate;
- changed payload with reused idempotency key fails;
- customer history is owner-scoped;
- customer direct order DML and status transition fail;
- staff sees queue and can create a guest POS order;
- `scheduled -> preparing -> ready -> completed` works;
- stale status versions and illegal terminal transitions fail;
- staff cannot update scheduling policy; admin can;
- regression rollback leaves zero synthetic identities/orders/events.

Supabase security advisor: **0 lints**.

Performance advisor: only `unused_index` INFO after a forward migration added all missing foreign-key covering indexes.

Dashboard `server/orderBff.ts` passes isolated strict TypeScript 5.8.3 compilation under the repository server compiler rules. `server/orderBff.test.ts` adds contract coverage for publishable-key public policy reads, staff caller-JWT queue/quote/place, same-origin rejection, optimistic-conflict mapping, and admin-only policy writes.

## Frontend work remaining

### Customer Flutter

Replace the current local/mock order authority with ADR-0010:

- call the authoritative quote before placement;
- add ASAP / Schedule for later checkout UX from `get_ordering_policy()`;
- generate/reuse a placement `clientRequestId` correctly;
- call `place_customer_order()`;
- replace random local order numbers and local-only `PastOrder` authority with backend snapshots/history;
- replace the timer-driven confirmation timeline with persisted status;
- subscribe to authorized `orders` Realtime changes and re-fetch the order;
- display scheduled pickup and status using existing AIDA visual language.

### Dashboard React

Keep preview POS cart editing only as selection state, but make quote/place totals and persisted orders authoritative through the BFF:

- quote current cart through `/api/v1/orders/quote`;
- place ASAP or scheduled POS orders through `/api/v1/orders/place`;
- add the live staff order board/queue using `/api/v1/orders`;
- visually distinguish Scheduled / Confirmed / Preparing / Ready;
- transition statuses through `/api/v1/orders/status` with `expectedVersion`;
- refresh/refetch on order Realtime changes or a safe query invalidation strategy;
- preserve existing AIDA dashboard components/tokens/layout conventions.

No real payment processor exists. Frontend must use an explicit `Pay at counter`/unpaid demo path and must remove or disable copy that falsely implies Card/E-wallet/Student Wallet was processed.

## Required frontend sources

In both repos read normal governance docs first, then:

- `docs/decisions/ADR-0010-authoritative-ordering-and-scheduled-fulfilment.md`
- `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md`

Do not re-design the backend contract in frontend work unless actual repository/live evidence shows a defect.

## Existing external validation debt

TASK-AUTH-003 remains PARTIAL because the Vercel preview lacks its two publishable Supabase environment variables and the live project has zero approved real customer/staff/admin identities. Those operator gates will still be needed for a real-identity deployed E2E.

For a local demo, the dashboard may run locally against the same Supabase project once an approved staff/admin identity exists; the customer app/device can independently use the same cloud project.

## Exact next task

Continue `TASK-DEMO-ORDER-001` on the current shared branch with **frontend-only integration and full client validation**, then prove:

```text
customer quote + ASAP/scheduled placement
-> persisted order
-> dashboard queue
-> staff Preparing/Ready/Completed transition
-> running customer app Realtime event
-> authorized re-fetch
-> visible status update without a fake timer
```

Do not begin payment, loyalty, inventory or analytics authority until this trusted order flow is integrated.
