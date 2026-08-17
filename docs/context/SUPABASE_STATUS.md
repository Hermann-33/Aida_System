# Supabase Status

**Status date:** 2026-08-17
**Project:** Aida System
**Ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`

## Current live snapshot

Independently rechecked after the final cross-client E2E:

- Auth users: 9
- profiles: 9
- members: 6
- trusted roles: 1 owner, 1 admin, 1 staff
- retained orders: 1
- catalogue revision: 15

These are dated operational counts, not schema invariants. Employee identities are intentionally not member/loyalty rows.

## Identity/membership

Trusted identity/member objects remain live with forced RLS:

- `user_profiles`
- `members`
- `student_verifications`

Trusted role helpers and Admin/owner member-directory functions remain unchanged. Physical Android signup created trusted Auth/profile/member rows and the resulting member was visible through protected Dashboard Members.

## Catalogue

Live catalogue objects:

- `catalogue_categories`
- `catalogue_items`
- `catalogue_item_variants`
- `catalogue_item_addons`
- `catalogue_revision`
- `catalogue_audit_events`

Validated catalogue baseline remains 4 categories, 16 items, 27 variants and 27 compatible add-on links. Catalogue revision was 15 at the closeout validation point. A real Owner price mutation was observed by the installed customer app through revision invalidation and authoritative refetch.

## Orders and scheduling

Canonical customer-repository migrations:

1. `20260812182212_create_authoritative_orders_and_scheduling.sql`
2. `20260812183029_index_order_foreign_keys.sql`

Live tables:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

All five use RLS + FORCE RLS.

Live public RPC contract:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `place_pos_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- `list_orders(text[], integer)`
- `transition_order_status(uuid,text,bigint,text)`
- `save_ordering_policy(jsonb)`

Ordinary authenticated clients have no direct INSERT/UPDATE authority over order commercial tables. Controlled persistence occurs through the accepted RPC boundary.

Current schedule policy:

```text
timezone                 Asia/Kuala_Lumpur
schedule_enabled         true
minimum_lead_minutes     15
slot_interval_minutes    15
maximum_advance_days     7
```

Branch-specific opening hours, closures and capacity are not modeled.

## Final retained E2E order

Order `100006` / `7cf027dc-3ff0-4604-a3fd-c7a943aac603` was created on 2026-08-17 through the supported authenticated customer placement boundary.

Verified properties:

- source: customer
- fulfilment: ASAP
- authoritative total: 1,290 sen
- initial persisted status: `confirmed`, version 1
- final persisted status: `completed`, version 4
- event sequence: created/confirmed → preparing → ready → completed
- customer-owned `get_order` reads observed preparing, ready and completed
- Dashboard Owner BFF queue/detail observed the same persisted record

The order remains intentionally retained as TASK-CLOSEOUT-001 evidence. It was not inserted directly with SQL and no service-role credential was used.

## Realtime

`supabase_realtime` publishes the intended mutable signals:

- `catalogue_revision`
- `orders`

Catalogue clients re-fetch the authoritative catalogue after revision changes. Customer order clients re-fetch an authorized order snapshot after an order-header change. Immutable order line/add-on snapshots are not separately published.

## Regression status

Canonical Auth/member, catalogue and order SQL regressions pass transactionally against the live project. Synthetic test data is rolled back and does not alter the retained live population.

The order regression proves server pricing, compatibility checks, scheduling validation, trusted customer/member derivation, idempotency, owner-scoped reads, absence of direct customer order DML/status authority, staff queue/POS capability, versioned legal transitions and Admin-only schedule-policy mutation.

## Security advisor

Current security advisor state has exactly one WARN:

- `auth_leaked_password_protection` — **Leaked Password Protection Disabled**

Remediation: <https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection>

Historical zero-lint results remain valid for their earlier dates but are not the current advisor state.

## Public schema inventory

Current active public base tables:

- 3 identity/member tables
- 6 catalogue tables
- 5 order/scheduling tables

Total: 14 public base tables within the accepted shared-backend architecture.

Historical pre-order migration filename/live-version differences remain documented history and are not current schema drift. Applied historical migrations must not be rewritten.
