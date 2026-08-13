# Database Schema Foundation

Updated: 2026-08-14

Canonical executable migrations live in `Hermann-33/Aida_System/supabase/`. The Dashboard repository mirrors database documentation but does not own an independent migration history.

## Identity/member foundation

Trusted identity/membership tables:

- `user_profiles`
- `members`
- `student_verifications`

Supabase Auth is identity authority. `user_profiles.app_role` + `disabled_at` hold trusted employee/Admin authorization state. `members` holds customer membership state. All exposed identity/member tables use RLS/FORCE RLS according to the accepted foundation migrations.

Public signup cannot self-grant trusted roles/member codes/student verification. Member-code generation and privileged role changes are server/operator authority.

## Shared catalogue foundation

Catalogue tables:

- `catalogue_categories` — server UUID, slug/name/image, sort, active state.
- `catalogue_items` — server UUID/SKU/slug, category, product/add-on kind, integer-sen base price, publication/availability/merchandising flags, image/volume/prep route/sort.
- `catalogue_item_variants` — item-specific option label/code, sen delta, default/availability/sort.
- `catalogue_item_addons` — normalized product-to-addon compatibility.
- `catalogue_revision` — singleton public read-only invalidation counter.
- `catalogue_audit_events` — append-only trusted mutation evidence.

Controlled catalogue RPCs include:

- `get_catalogue()`
- `save_catalogue_category(jsonb)`
- `save_catalogue_item(jsonb)`

Catalogue mutation authority is admin/owner through the trusted caller boundary. Customer/public reads are publication-scoped. `catalogue_revision` is published for invalidation; clients refetch authoritative catalogue state after a revision event.

Canonical catalogue migrations include:

- `20260812231500_create_shared_catalogue.sql`
- `20260812235000_harden_catalogue_rls_policies.sql`

## Authoritative order/scheduling foundation

Order/scheduling tables:

- `order_schedule_settings` — singleton trusted scheduling policy.
- `orders` — server-owned order identity, customer/POS source, fulfilment intent, persisted status/version, commercial total and schedule snapshot.
- `order_lines` — immutable item/variant commercial snapshots.
- `order_line_addons` — immutable compatible add-on snapshots.
- `order_events` — append-only creation/status-transition evidence.

All five order/scheduling tables use RLS/FORCE RLS. Ordinary authenticated clients do not receive direct commercial INSERT/UPDATE authority; controlled RPCs validate caller/session/role and persist trusted outcomes.

Public/order RPC contract includes:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `place_pos_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- `list_orders(text[], integer)`
- `transition_order_status(uuid,text,bigint,text)`
- `save_ordering_policy(jsonb)`

Key invariants:

- clients submit selection/intent, not trusted prices/totals/order number/status;
- `quote_order` revalidates current catalogue truth;
- customer/member identity is derived from `auth.uid()` and active membership;
- POS placement requires staff-or-above;
- placement is idempotent through `clientRequestId`;
- persisted commercial snapshots are immutable;
- legal status transitions are allow-listed and require expected `statusVersion`;
- `order_events` records trusted lifecycle evidence.

Current scheduling defaults:

- timezone `Asia/Kuala_Lumpur`;
- minimum lead 15 minutes;
- slot interval 15 minutes;
- maximum advance 7 days.

Branch hours/closures/capacity are intentionally not part of this foundation.

Canonical order migrations:

- `20260812182212_create_authoritative_orders_and_scheduling.sql`
- `20260812183029_index_order_foreign_keys.sql`

`orders` is published to Supabase Realtime for authorized status/header invalidation. Immutable order lines/add-ons are not separately published.

## Current public schema inventory

As of the accepted current architecture, public base tables are:

- 3 identity/member tables;
- 6 catalogue tables;
- 5 order/scheduling tables.

Total: 14 public base tables.

Dated row counts/revisions belong in `docs/context/SUPABASE_STATUS.md` and `CLOSEOUT_EVIDENCE_2026-08-14.md`, not in schema invariants.

## Deferred schema domains

Separate future trusted schema work is still required for payment/refunds, loyalty ledgers/redemptions, inventory, promotions/discounts, tax/accounting, branch-scoped operations/hours/capacity, revenue reporting and delivery.
