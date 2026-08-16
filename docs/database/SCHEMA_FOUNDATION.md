# Database Schema Foundation

Updated: 2026-08-17

Canonical executable migrations are owned by `Hermann-33/Aida_System/supabase/`. The Dashboard repository mirrors this schema documentation but does not own a second migration ledger.

## Identity/member foundation

Trusted identity/membership tables:

- `user_profiles` — Auth-linked application profile, trusted `app_role`, disabled state and profile fields.
- `members` — customer membership identity, server-generated member code, member type/student state and membership status.
- `student_verifications` — trusted verification-review records.

These tables use RLS/FORCE RLS according to the accepted identity/member migrations. Public signup provisions customer-only trusted state through the Auth trigger; clients cannot self-promote employee roles or assign trusted member codes/verification outcomes.

## Shared catalogue foundation

Live catalogue tables:

- `catalogue_categories` — server UUID, slug/name/image, sort and active state.
- `catalogue_items` — server UUID/SKU/slug, category, product/add-on kind, integer-sen base price, publication/availability/merchandising fields, image/volume/prep-route/sort.
- `catalogue_item_variants` — item-specific option label/code, integer-sen delta, default/availability/sort.
- `catalogue_item_addons` — normalized product-to-add-on compatibility.
- `catalogue_revision` — singleton public read-only invalidation counter; published to Realtime.
- `catalogue_audit_events` — append-only trusted catalogue mutation evidence.

Controlled catalogue RPCs:

- `get_catalogue()`
- `save_catalogue_category(jsonb)`
- `save_catalogue_item(jsonb)`

All exposed catalogue tables use RLS/FORCE RLS. Customer/public reads are publication-scoped; Admin/owner writes use trusted caller identity.

## Authoritative order/scheduling foundation

Live order/scheduling tables:

- `order_schedule_settings` — singleton scheduling policy.
- `orders` — server-owned order identity, source, trusted actor references, fulfilment intent, status/version, integer-sen totals and lifecycle timestamps.
- `order_lines` — immutable item/variant naming and price snapshots, quantity, note and line total.
- `order_line_addons` — immutable add-on naming/price snapshots.
- `order_events` — append-only creation/status transition evidence.

All five order/scheduling tables use RLS + FORCE RLS. Ordinary authenticated customers do not receive direct commercial order INSERT/UPDATE authority; controlled RPCs own quote/place/read/status operations.

Current order/scheduling RPC surface:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `place_pos_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- `list_orders(text[], integer)`
- `transition_order_status(uuid,text,bigint,text)`
- `save_ordering_policy(jsonb)`

`orders` is published to Realtime for authorized customer invalidation/refetch. Immutable order line/add-on snapshots are not separately published.

Current scheduling defaults:

- timezone `Asia/Kuala_Lumpur`
- enabled
- 15-minute minimum lead
- 15-minute slot interval
- 7-day maximum horizon

Branch opening hours, closures and capacity are not modeled in the current schema.

## Commercial authority rules

- Money is integer sen.
- Catalogue item/variant/add-on IDs are server-owned UUIDs.
- `quote_order` re-prices from current orderable catalogue state and ignores client price/total fields.
- Customer placement derives customer/member identity from the authenticated session and active member record.
- POS placement requires staff-or-above through the trusted caller boundary.
- Order number, totals, commercial snapshots, initial status and lifecycle timestamps are server-owned.
- Placement is idempotent through actor-scoped `clientRequestId`.
- Fulfilment transitions are allow-listed and require expected `statusVersion`.

## Current live inventory/evidence

At the 2026-08-17 closeout verification:

- 14 public base tables exist in the accepted identity/member + catalogue + order/scheduling architecture;
- 9 Auth users / 9 profiles / 6 members are present;
- trusted roles owner/admin/staff = 1/1/1;
- catalogue revision = 15;
- 1 retained completed order exists.

Retained E2E order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`) is customer-source, total 1,290 sen, final `completed` version 4, with creation/preparing/ready/completed event evidence.

## Canonical regression coverage

The customer repository owns transactional SQL regressions for:

- Auth/member provisioning and member-directory/RLS behavior;
- catalogue publication, mutation, audit/revision and customer write denial;
- order pricing, compatibility, scheduling, identity derivation, idempotency, owner-scoped reads, direct-DML denial, staff queue/POS behavior and legal/stale/terminal fulfilment transitions.

Synthetic test rows roll back and do not replace approved live/demo state.
