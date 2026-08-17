# ADR-0010 — Authoritative ordering and scheduled fulfilment

- **Status:** Accepted
- **Date:** 2026-08-13
- **Task:** `TASK-DEMO-ORDER-001`

## Context

AIDA now has trusted identity/member state and one shared catalogue, but customer checkout and POS transaction state are still local/preview. A demo-worthy ordering flow needs real persisted orders, scheduled pickup, a staff queue, and live customer status updates without making Flutter or the browser authoritative for prices, totals, schedules, or fulfilment state.

There is not yet an accepted branch-hours/capacity authority, payment processor, loyalty ledger, or inventory depletion model. Those concerns must not be fabricated inside this task.

## Decision

### Shared authority

Supabase is the authoritative order/fulfilment boundary for both customer and POS channels.

Clients send catalogue item IDs, optional variant IDs, compatible add-on IDs, quantities, notes, fulfilment intent, and an idempotency key. They do not submit trusted names, prices, totals, order numbers, status, member identity, or role state.

`public.quote_order(jsonb)` resolves current catalogue truth and validates:

- product publication and availability;
- active category membership;
- required/available per-item variants;
- add-on compatibility and availability;
- quantity/note bounds;
- ASAP versus scheduled-pickup policy.

Any client-supplied price/total fields are ignored.

### Persistence and immutable snapshots

`orders`, `order_lines`, and `order_line_addons` persist the commercial snapshot accepted at placement time. Product/variant/add-on names, SKUs and integer-sen prices are retained so later catalogue edits cannot rewrite historical receipts/orders.

Order UUIDs and numeric order numbers are server-owned. `clientRequestId` is required and unique per authenticated actor; an identical retry returns the existing order, while reuse with a different payload fails.

### Channels and identity

Customer placement uses `public.place_customer_order(jsonb)` and requires the authenticated customer to have an active trusted member row. `customer_user_id` and `member_id` are derived from trusted backend identity, never request JSON.

POS placement uses `public.place_pos_order(jsonb)` and requires `staff`, `admin`, or `owner`. In this bounded task POS orders are guest orders; member attachment/scanning remains a later trusted POS/member task.

### Scheduled pickup

A singleton server policy begins with:

- timezone: `Asia/Kuala_Lumpur`;
- scheduled ordering enabled;
- minimum lead time: 15 minutes;
- slot interval: 15 minutes;
- maximum advance horizon: 7 days.

Scheduled timestamps are validated against server time, lead time, horizon, timezone, and slot alignment. Admin/owner may update the policy through the trusted mutation boundary.

Branch-specific opening hours, closures and per-slot capacity are intentionally deferred because no accepted branch-hours/capacity model exists yet. The current policy is therefore a single-café demo policy, not a claim of branch-aware scheduling.

### Fulfilment state machine

Persisted statuses are:

- `confirmed` — ASAP order accepted;
- `scheduled` — future pickup accepted;
- `preparing`;
- `ready`;
- `completed`;
- `cancelled`.

Legal staff transitions are:

- `confirmed -> preparing | cancelled`;
- `scheduled -> preparing | cancelled`;
- `preparing -> ready | cancelled`;
- `ready -> completed`.

`completed` and `cancelled` are terminal. Status changes require staff-or-above authority and an expected `statusVersion`; stale concurrent updates fail rather than overwriting newer state. `order_events` records creation and status-transition evidence.

### Realtime

Only the mutable `orders` header is added to `supabase_realtime`. Commercial lines/add-ons are immutable and are not separately published. Customer/staff clients subscribe to authorized order-row changes and re-fetch the full authorized order snapshot after a change.

RLS remains authoritative: customers may read only their orders; staff-or-above may read the current global queue. Global staff visibility is an explicit single-café limitation until branch assignment/scope becomes authoritative.

### Client integration boundaries

Flutter will call the public Supabase order RPCs with its authenticated customer session.

The dashboard continues the ADR-0008 same-origin BFF model. Employee order endpoints validate HttpOnly employee cookies, forward the caller JWT to Supabase, require same-origin state-changing requests, and never expose a service-role credential or staff bearer token to browser JavaScript.

### Payment and downstream domains

No real payment is processed in this task. Frontends must not present Card/E-wallet/Student Wallet as completed real transactions. The demo may use an explicitly safe `Pay at counter`/unpaid flow until payment authority exists.

No loyalty points, inventory depletion, reporting revenue, refunds, tax, promotion, delivery, or kitchen-capacity side effects are created by order placement/completion in this ADR. Those domains must consume trusted completed orders in later bounded tasks.

## Consequences

- Customer and POS share one commercial pricing/order authority.
- Scheduled orders are real persisted orders rather than local timers/placeholders.
- Catalogue changes cannot rewrite historical order snapshots.
- Duplicate network retries do not duplicate orders.
- Realtime UI can be driven by persisted staff transitions instead of fake timers.
- The order backend can be demoed before payment/loyalty/inventory are implemented.
- Branch-aware scheduling and branch-scoped queues remain explicit future work.

## Completion gate

Backend/database completion can be validated independently, but the end-user feature remains `PARTIAL` under ADR-0004 until Flutter and dashboard frontends consume these contracts, remove conflicting local order authority, pass their toolchains, and prove the customer-place -> staff-status -> customer-Realtime journey end-to-end.
