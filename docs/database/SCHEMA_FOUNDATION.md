# Schema Foundation

Updated: 2026-09-15

**Current status:** `COMPLETE` through Phase 7. Canonical executable migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Identity and membership

Trusted identity begins with Supabase Auth and server-owned `user_profiles`. Customer/member state, employee branch assignments and role checks never trust customer-editable Auth metadata as authorization authority.

Whole-account deletion is caller-bound and removes customer-owned identity/member/loyalty data while preserving only documented anonymised commercial history.

## Catalogue and ordering

The shared catalogue uses canonical `catalogue_items`, `catalogue_item_variants`, option groups/values and add-on catalogue items. Accepted orders persist server-derived line/customization/commercial snapshots rather than trusting client prices.

Orders carry source, branch/topology, member/customer attribution where applicable, integer-sen subtotal/discount/total, fulfilment/scheduling state, payment classification, status/version and idempotency anchors.

## Operational topology and cash

Phase 1–2 add branches, employee branch scope, sales points, terminals, terminal credential authority, shifts and append-only cash movements/reconciliation. New POS orders require trusted terminal/caller context and an open shift.

## Scheduling and inventory

Phase 4 owns branch pickup policy, service windows/exceptions and capacity. Phase 5 owns inventory items, branch inventory, recipes/components and append-only inventory movements. Placement enforces schedule/capacity and transactional non-negative stock consumption; cancellation uses exactly-once reversal facts.

## Loyalty and vouchers

Phase 6 adds loyalty program configuration, member loyalty accounts, point/stamp ledgers, order award anchors, reward catalogue, member vouchers and immutable voucher order applications. Direct client table mutation is denied; caller-bound RPCs own reads/mutations.

## Promotions and discounts

Phase 7 adds:

```text
promotions
promotion_branches
promotion_items
promotion_variants
promotion_addons
promotion_order_applications
```

`promotions` stores server-owned fixed/percentage rules, windows, minimum subtotal, optional cap, priority, stacking mode, voucher compatibility, member requirement, global/per-member usage limits and activation state.

Scope tables reference canonical branches/catalogue resources. Product scope accepts only product catalogue items; add-on scope accepts only `kind='addon'` catalogue items.

`promotion_order_applications` stores immutable accepted commercial snapshots including promotion code/name, type/value, accepted discount, priority, stacking mode and voucher-coexistence state. `promotion_id`/`member_id` may detach where legitimate deletion/configuration lifecycle requires preserving non-identifying accepted transaction truth.

All six Phase 7 tables use RLS + FORCE RLS. Direct `public`/`anon`/`authenticated` table authority is revoked. Admin/Owner configuration and order evaluation are exposed through controlled caller-bound RPC/private-function paths.

## Commercial invariants through Phase 7

```text
sum(order line totals) = orders.subtotal_sen
voucher discount + promotion discount = orders.discount_sen
orders.total_sen = orders.subtotal_sen - orders.discount_sen
accepted promotion application sum = accepted promotion discount
```

Promotion usage is serialized by locking candidate promotion rows during placement. Idempotent order retries do not consume usage twice.

## Live migration state

Canonical Phase 7 replay files:

```text
20260915100000_create_promotion_discount_authority.sql
20260915101000_integrate_promotions_with_order_authority.sql
20260915101100_normalize_phase7_nullable_voucher_quote.sql
```

Live AIDA history records the equivalent applied operations as:

```text
20260915120917_create_promotion_discount_authority
20260915121057_integrate_promotions_with_order_authority
20260915121119_normalize_phase7_nullable_voucher_quote
```

Do not rewrite applied live migration history merely to match repository timestamps.

## Deferred schema authority

Phase 8 may add read-oriented reporting/accounting/audit projections or RPCs over trusted source facts. Phase 9 owns external processor/refund/settlement authority. Phase 10 owns final release validation. These later phases must not weaken the Phase 1–7 source-of-truth model.
