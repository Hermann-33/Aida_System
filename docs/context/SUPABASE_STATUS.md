# Supabase Status

**Status date:** 2026-08-20
**Project:** Aida System
**Ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`
**Health:** ACTIVE_HEALTHY
**Postgres:** 17.6.1.155

## Current live snapshot

Latest independently checked operational counts:

- Auth users: 12
- profiles: 12
- members: 9
- trusted roles: 1 owner, 1 admin, 1 staff
- retained orders: 4
- catalogue revision: 42
- public base tables: 14

These counts are dated operational observations, not schema invariants.

## Identity/membership

Trusted identity/member objects remain live with forced RLS:

- `user_profiles`
- `members`
- `student_verifications`

The staff demo identity `staff.nora.demo@aida.test` is confirmed and active with trusted `app_role=staff`; the account is not disabled/banned/deleted. Authentication succeeds. Current staff POS trouble is post-auth Dashboard flow, not missing Auth identity.

## Catalogue

Live catalogue objects remain:

- `catalogue_categories`
- `catalogue_items`
- `catalogue_item_variants`
- `catalogue_item_addons`
- `catalogue_revision`
- `catalogue_audit_events`

Catalogue revision is currently 42. Supabase remains authoritative for publication, availability, IDs, variants, add-on compatibility and integer-sen pricing.

## Orders and scheduling

Canonical applied order migrations include:

1. `20260812182212_create_authoritative_orders_and_scheduling.sql`
2. `20260812183029_index_order_foreign_keys.sql`
3. `20260820151421_add_scheduled_order_preparation_window.sql`

Live order/scheduling tables remain:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

All five retain RLS + FORCE RLS where defined by the accepted order architecture. Ordinary authenticated clients have no direct INSERT/UPDATE authority over order commercial tables; controlled writes remain behind the accepted RPC helpers.

### Current policy

```text
timezone                 Asia/Kuala_Lumpur
schedule_enabled         true
minimum_lead_minutes     15
preparation_lead_minutes 15
slot_interval_minutes    15
maximum_advance_days     7
```

`minimum_lead_minutes` controls the earliest customer-selectable pickup. `preparation_lead_minutes` is separate operational authority used to snapshot when staff should begin a scheduled order.

Invariant:

```text
0 <= preparation_lead_minutes <= minimum_lead_minutes
```

### Scheduled-order operational authority

`orders` now stores server-owned `prepare_at` for scheduled orders:

```text
prepare_at = requested_pickup_at - preparation_lead_minutes
```

The value is snapshotted at placement and protected from later commercial-field mutation. A future policy change does not rewrite an accepted order.

Authorized order snapshots additionally expose:

```text
prepareAt
serverNow
scheduleState = future | due | overdue | null
```

For persisted `status=scheduled`:

- pickup already passed -> `overdue`
- preparation time reached -> `due`
- otherwise -> `future`

This operational classification does **not** auto-transition fulfilment status. Only staff-or-above may persist the existing legal status transitions with expected `statusVersion`.

### Current retained orders

The original closeout order `100006` remains completed evidence.

Three later scheduled customer orders remain persisted `scheduled` and are now correctly exposed as operationally `overdue`:

- `100007`
- `100008`
- `100009`

Their `prepare_at` values were backfilled from the current 15-minute preparation lead without manufacturing a fulfilment transition.

## Public RPC contract

Current order RPC boundary includes:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `place_pos_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- `list_orders(text[], integer)`
- `transition_order_status(uuid,text,bigint,text)`
- `save_ordering_policy(jsonb)`

`get_ordering_policy()` now includes `preparationLeadMinutes`; Admin/Owner `save_ordering_policy` accepts it subject to the bounds above.

## Realtime

`supabase_realtime` still publishes the intended mutable signals:

- `catalogue_revision`
- `orders`

Customer clients treat Realtime as invalidation and re-fetch authorized snapshots. Dashboard staff keeps the same-origin BFF/polling model because employee bearer tokens remain HttpOnly.

## Regression status

Canonical existing Auth/member, catalogue and order regressions remain the accepted baseline.

TASK-SCHEDULED-OPS-001 adds:

`supabase/tests/scheduled_order_operations_integration.sql`

Live transactional result: PASS.

It proves preparation schema/policy bounds, immutable scheduled `prepareAt`, backend-derived `scheduleState`, idempotent retry preservation, Admin policy mutation and validation, scheduled POS placement against the current policy, and non-rewriting of existing orders after policy changes.

## Security advisor

Current security advisor has exactly one WARN:

- `auth_leaked_password_protection` — **Leaked Password Protection Disabled**

Remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

No new security advisor finding was introduced by TASK-SCHEDULED-OPS-001.

## Performance advisor

Current findings are INFO-only unused-index notices on the small dataset. The new `orders_scheduled_prepare_idx` is reported unused immediately after creation, which is expected until the operational queue generates sufficient reads. Do not remove it merely to clear an INFO result.

## Explicitly deferred backend authority

Still not modeled as trusted live backend domains:

- branch-specific opening hours/closures/capacity
- authoritative branch assignment and branch-scoped order queues
- terminal enrolment/credentials
- sales-point authority
- shifts/cash reconciliation
- real payment/refunds
- loyalty earning/redemption
- inventory depletion
- promotions/discount engine
- tax/accounting/reporting
- delivery
- hosted production operations

Dashboard code must not fabricate these domains to unblock UI.