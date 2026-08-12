# Active Context

**As of:** 2026-08-13
**Current implementation task:** `TASK-DEMO-ORDER-001 — live ordering, scheduled pickup, POS queue, and Realtime fulfilment`
**Current task verdict:** PARTIAL

## Current product reality

The shared backend for the next demo ordering flow is implemented live; the remaining bounded work is frontend integration plus ADR-0004 client/E2E validation.

Existing trusted foundations remain in place:

- customer Supabase Auth/member integration and minimum offline member-code cache;
- shared Supabase catalogue with 4 categories / 16 items / 27 variants / 27 compatible add-on links;
- Flutter catalogue read + `catalogue_revision` invalidation/re-fetch;
- dashboard Admin and POS catalogue browsing through the same shared catalogue;
- dashboard employee/admin same-origin BFF with HttpOnly session cookies and caller-JWT Supabase access.

TASK-AUTH-003 remains operationally `PARTIAL`: Vercel preview exists but lacks its two publishable Supabase runtime variables, and live Supabase still has zero approved customer/staff/admin identities. That deployment/identity debt does not make the new order database contract client-authoritative.

## TASK-DEMO-ORDER-001 backend now live

Accepted ADR-0010 defines one authoritative order/fulfilment boundary.

Live migrations:

- `20260812182212_create_authoritative_orders_and_scheduling.sql`
- `20260812183029_index_order_foreign_keys.sql`

New public tables, all RLS-enabled and FORCE RLS:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

Order commercial state is server-owned. Clients submit item/variant/add-on IDs, quantity, note, fulfilment intent, schedule time, and a placement idempotency UUID. They never supply trusted prices, totals, order numbers, customer/member identity, roles, or fulfilment status.

`quote_order(jsonb)` revalidates the current shared catalogue and resolves integer-sen prices. Persisted line/add-on names, SKUs and prices are immutable snapshots, so later catalogue edits do not rewrite historical orders.

Customer placement requires an authenticated customer with an active trusted member. POS placement requires staff-or-above. `clientRequestId` makes retries idempotent; reusing the key with another payload fails.

Scheduling defaults are server-owned:

- timezone `Asia/Kuala_Lumpur`;
- scheduled ordering enabled;
- 15-minute minimum lead;
- 15-minute slots;
- 7-day horizon.

The backend validates lead/horizon/slot alignment. Branch-specific hours, closures and capacity are explicitly deferred because there is no accepted branch-hours/capacity authority yet.

Fulfilment states are `confirmed`, `scheduled`, `preparing`, `ready`, `completed`, `cancelled`. Staff-only legal transitions use optimistic `statusVersion` concurrency and append `order_events` evidence. `completed`/`cancelled` are terminal.

Realtime publication now contains exactly the catalogue revision signal and `orders`. Clients subscribe to authorized order-header changes then re-fetch full snapshots; immutable lines/add-ons are not separately published.

## Dashboard backend boundary

No React UI was changed by the backend task.

New same-origin server endpoints exist for frontend consumption:

- `GET /api/v1/orders/policy`
- `GET /api/v1/orders`
- `GET /api/v1/orders/detail?id=<uuid>`
- `POST /api/v1/orders/quote`
- `POST /api/v1/orders/place`
- `POST /api/v1/orders/status`
- `POST /api/v1/admin/orders/policy`

Employee endpoints validate the existing HttpOnly session and forward the caller JWT. State-changing requests require same origin. No service-role credential or employee bearer token is exposed to browser JavaScript.

## Validation completed

- canonical `supabase/tests/order_integration.sql`: passed transactionally against live Supabase;
- forged client totals were ignored; `2 × CF-SCL Medium + Oat Milk` resolved to 3080 sen from catalogue truth;
- incompatible add-on and invalid past schedule rejected;
- customer scheduled placement, snapshots, own-history read and idempotent retry passed;
- customer direct order DML and status transition denied;
- staff queue, guest POS placement and `scheduled -> preparing -> ready -> completed` passed;
- stale status version and illegal terminal transition rejected;
- staff ordering-policy write denied; admin policy write passed transactionally;
- cleanup proof: 0 retained Auth users / profiles / members / orders / lines / add-ons / order events;
- Supabase security advisor: 0 lints;
- performance advisor: only `unused_index` INFO after adding all missing FK-covering indexes;
- dashboard `server/orderBff.ts`: strict TypeScript 5.8.3 isolated compile passes under the repository server compiler settings;
- dashboard BFF contract tests are added in `server/orderBff.test.ts` for caller-JWT routing, origin checks, conflict mapping and admin policy authority.

## Frontend work deliberately not implemented here

Customer Flutter still has the old local checkout/order presentation until Codex integrates ADR-0010:

- random local order number;
- local `PastOrder` storage;
- fake payment-method choices;
- confirmation timeline driven by a local timer;
- no ASAP/scheduled pickup selector backed by server policy.

Dashboard React still needs to connect its existing POS/order surfaces to the new order BFF and present the live scheduled/confirmed/preparing/ready queues and transitions. Preview cart/totals/payment logic must not become trusted authority.

No real payment processor exists. Frontend integration must use an explicitly safe `Pay at counter`/unpaid demo flow and must not claim Card/E-wallet/Student Wallet payment has completed.

## Canonical frontend handoff

Read, in addition to the normal governance sequence:

- `docs/decisions/ADR-0010-authoritative-ordering-and-scheduled-fulfilment.md`
- `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md`

These define the exact RPC/BFF payloads, states, scheduling policy and security boundaries.

## Branch / dependency state

Shared task branch in both repositories:

`codex/task-demo-order-001-order-scheduling-backend`

It is stacked on each repository's `codex/task-auth-003-deployed-e2e` branch. Existing AUTH-003 deployment/identity gates remain separate unresolved prerequisites for a fully deployed real-identity E2E.

## Exact next task

Continue `TASK-DEMO-ORDER-001` on the same shared branch with **frontend integration only**: Flutter quote/schedule/place/history/Realtime status UI and dashboard POS quote/place/live order board/status controls. Preserve the established AIDA visual language rather than redesigning either product. Then run full client toolchains and the cross-client customer-place -> dashboard-status -> customer-Realtime E2E required by ADR-0004.
