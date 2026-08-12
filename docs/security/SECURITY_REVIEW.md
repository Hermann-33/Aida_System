# AIDA Café Security Review

Updated: 2026-08-13

**Verdict:** identity, catalogue, and new order/scheduling authority are hardened at the backend boundary; overall demo feature remains `PARTIAL` until frontend integration and real-identity E2E.

## Existing identity/catalogue controls

- Supabase Auth plus trusted `user_profiles`/`members` remain authoritative for identity and membership.
- Public signup cannot self-promote role/member/verification state.
- Catalogue tables use FORCE RLS.
- Public/customer catalogue reads are publication-scoped.
- Catalogue admin/owner writes use trusted caller identity; no service-role browser bypass.
- Dashboard privileged flows retain same-origin HttpOnly employee sessions and caller-JWT Supabase access.
- Customer runtime has no production hardcoded catalogue fallback; dashboard POS has no preview catalogue fallback.

## TASK-DEMO-ORDER-001 order controls

All new order/scheduling tables use RLS + FORCE RLS:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

Authenticated browser/mobile roles have no direct INSERT/UPDATE grants on order commercial tables. Controlled persistence occurs only through bounded RPC helpers with explicit caller/role validation.

### Pricing and identity

- `quote_order(jsonb)` ignores client price/total fields and re-prices from current published/available catalogue data.
- Item/variant/add-on compatibility is revalidated server-side.
- Customer/member identity is derived from `auth.uid()` plus the active member row, never request JSON.
- POS placement requires staff-or-above.
- Order UUID, numeric order number, price snapshots, totals, initial status, timestamps, and audit events are server-owned.
- Persisted commercial fields are protected against later mutation by a database trigger.

### Idempotency

Placement requires a `clientRequestId` UUID scoped to the authenticated actor.

- identical retry -> returns the same persisted order;
- same key + different payload -> conflict;
- client retry cannot create a duplicate order for the same key.

### Scheduling

The server validates scheduled pickup against trusted server time and the singleton policy:

- timezone `Asia/Kuala_Lumpur`;
- 15-minute minimum lead;
- 15-minute slots;
- 7-day maximum horizon.

Staff cannot change policy. Admin/owner can change it only through the trusted RPC/BFF boundary.

Branch hours/closures/capacity are not yet authoritative, so neither backend nor frontend may claim branch-aware schedule validation.

### Fulfilment/status

Only staff-or-above may mutate status. Legal transitions are allow-listed and require an expected `statusVersion`; stale concurrent changes fail.

`order_events` records creation/status evidence and has no ordinary client write grant.

### Realtime

Only `orders` is added for order-status Realtime. Customer visibility remains owner-scoped through RLS; staff currently sees the global queue because branch scope is not yet modeled. Clients re-fetch full authorized snapshots after order-header changes.

### Dashboard BFF

New order BFF routes:

- validate the existing employee HttpOnly session;
- forward the caller JWT, not a service-role token;
- require same origin for POST requests;
- do not return employee access/refresh tokens in JSON;
- map idempotency/version conflicts to HTTP 409 for safe client recovery.

No React/Vite browser module receives a service-role key or trusted staff bearer token.

## Live security validation

Canonical `supabase/tests/order_integration.sql` passed transactionally and proved:

- anonymous quote allowed but privileged order capabilities denied;
- direct authenticated order DML absent;
- forged total ignored;
- incompatible add-on and invalid schedule rejected;
- customer owner/history boundary;
- customer status mutation denied;
- staff queue/POS placement allowed;
- admin-only schedule-policy write;
- legal/stale/terminal transition enforcement;
- cleanup leaves zero synthetic identities/orders/events.

Supabase security advisor after both order migrations: **0 lints**.

Performance advisor's initial four unindexed-FK INFO findings were resolved with a forward migration; final findings are only unused-index INFO expected on the empty/new dataset.

## Explicitly untrusted / deferred

No real payment authority exists. Card/E-wallet/Student Wallet UI must not claim successful settlement. Use an explicit `Pay at counter`/unpaid demo path until a trusted payment task exists.

Order completion currently represents fulfilment completion, not verified payment settlement.

The following remain separate trusted domains:

- payment/refunds
- loyalty earning/redemption
- inventory depletion
- promotions/discounts
- tax/accounting
- revenue/reporting
- branch-scoped staff/order access
- branch scheduling hours/capacity
- delivery

## Remaining release/E2E gates

- Flutter/frontend integration must remove local random order numbers, local-only order authority, fake payment completion, and timer-driven status progression.
- Dashboard frontend must use server quote/place/queue/status endpoints rather than preview totals/order records as authority.
- Real approved customer/staff/admin identities are still absent.
- Existing Vercel preview still lacks its publishable Supabase runtime variables.
- Cross-client customer placement -> dashboard status -> customer Realtime UI proof remains outstanding under ADR-0004.
