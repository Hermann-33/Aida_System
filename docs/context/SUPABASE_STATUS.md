# Supabase Status

**Status date:** 2026-08-14
**Project:** Aida System
**Ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`

This document records architecture and dated closeout evidence. Dynamic row counts and catalogue revisions are observations, not permanent invariants.

## Current identity/membership evidence

Closeout baseline observed on 2026-08-14:

- Auth users: 9
- `user_profiles`: 9
- `members`: 6
- trusted owners: 1
- trusted admins: 1
- trusted staff: 1

The six member rows are customer identities. The three employee identities are intentionally not loyalty/member rows.

Trusted identity/member objects remain:

- `user_profiles`
- `members`
- `student_verifications`

Supabase Auth is authentication authority. `user_profiles.app_role` plus `disabled_at` are trusted employee/admin authorization state. Member code and membership state are server-owned. Public signup cannot self-assign employee roles, member codes or verified student state.

The user physically validated fresh Android customer signup -> Auth/profile/member provisioning -> Dashboard Members visibility.

## Catalogue

Live catalogue objects:

- `catalogue_categories`
- `catalogue_items`
- `catalogue_item_variants`
- `catalogue_item_addons`
- `catalogue_revision`
- `catalogue_audit_events`

The closeout baseline observed catalogue revision **15**. Historical seed structure remains 4 categories / 16 original seeded items with normalized per-item variants and compatible add-on links; live Admin edits may change mutable catalogue fields over time.

A real Owner mutation is present in catalogue audit evidence. The user physically validated Dashboard Admin price mutation -> shared Supabase catalogue -> installed customer app refresh.

Catalogue authority remains:

- public/customer published reads through `get_catalogue()` under RLS;
- admin/owner mutations through protected caller-JWT BFF/RPC paths;
- server UUID identifiers and integer-sen prices;
- normalized variant/add-on relationships;
- revision bump plus audit on mutation;
- `catalogue_revision` Realtime invalidation followed by authoritative customer refetch.

## Orders and scheduling

Canonical repository migrations:

1. `20260812182212_create_authoritative_orders_and_scheduling.sql`
2. `20260812183029_index_order_foreign_keys.sql`

Live tables:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

All use RLS/FORCE RLS as defined by the accepted order architecture.

Public RPC contract includes:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `place_pos_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- `list_orders(text[], integer)`
- `transition_order_status(uuid,text,bigint,text)`
- `save_ordering_policy(jsonb)`

Ordinary authenticated clients have no direct commercial-table INSERT/UPDATE authority; controlled persistence occurs through bounded RPCs with caller/role validation.

Current scheduling singleton:

```text
timezone                 Asia/Kuala_Lumpur
schedule_enabled         true
minimum_lead_minutes     15
slot_interval_minutes    15
maximum_advance_days     7
```

Branch-specific opening hours, closures and capacity are not modeled and must not be claimed by clients.

Closeout baseline retained order state:

- orders: 0

No final cross-client order E2E had been retained at the time this baseline was recorded. TASK-CLOSEOUT-001 is responsible for closing that remaining path.

## Realtime

`supabase_realtime` publishes the intended mutable signals:

- `catalogue_revision`
- `orders`

Customer clients use authorized Supabase Realtime and refetch full trusted snapshots. Dashboard employee JWTs remain HttpOnly, so the React order board must poll/refetch the same-origin BFF rather than exposing a staff bearer token merely to connect directly to Realtime.

## Canonical regression evidence

Previous canonical transactional SQL regressions passed for:

- Auth/member provisioning and tamper resistance;
- catalogue publication/admin mutation/revision/audit rules;
- authoritative quote/order placement/scheduling/idempotency/ownership/status rules.

The order regression proved, among other cases:

- anonymous quote but no anonymous placement/status capability;
- no direct authenticated order-table DML;
- forged client totals ignored;
- catalogue/variant/add-on compatibility revalidated;
- invalid schedule rejected;
- trusted customer/member derivation;
- immutable commercial snapshots;
- idempotent retry and key-reuse conflict;
- customer owner-scoped history;
- customer status-mutation denial;
- staff queue/POS guest-order creation;
- versioned legal status transitions;
- stale/illegal transition rejection;
- admin-only schedule-policy update.

## Security advisor

Current closeout advisor state is **not zero findings**.

Security advisor reports:

- `auth_leaked_password_protection` — WARN — leaked-password protection disabled.

This is hosted Supabase Auth configuration debt. It is not a schema/RLS regression and must not be worked around by weakening application authentication.

Performance advisor currently contains unused-index INFO notices on new/low-volume indexes. Do not delete those indexes solely because the current dataset has not exercised them without a separate performance task and workload evidence.

## Current public schema inventory

Current active public base-table architecture consists of:

- 3 identity/member tables;
- 6 catalogue tables;
- 5 order/scheduling tables.

Total: 14 public base tables within the accepted shared-backend architecture.

## Historical migration-ledger drift

The pre-order identity/catalogue migration timestamp differences documented earlier remain historical naming drift, not schema drift. Do not rewrite applied migrations. The order migration source/ledger names were aligned before closeout.

## Operational note

The current accepted demo topology is local Dashboard PC -> cloud Supabase -> installed Android customer app. Hosted Vercel runtime configuration remains deferred unless a later accepted requirement makes hosted deployment part of the completion gate.
