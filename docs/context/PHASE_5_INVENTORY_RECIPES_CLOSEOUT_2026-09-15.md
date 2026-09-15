# Phase 5 Closeout — Inventory and Recipes

**Task:** `TASK-OPS-005`  
**Verdict:** `COMPLETE`  
**Date:** 2026-09-15  
**Dependency:** Phase 4 branch scheduling/pickup authority is `COMPLETE`.

## Scope and dependency rationale

Phase 5 makes branch inventory and recipe consumption server-authoritative on top of the Phase 4 branch/pickup boundary. The trusted chain is:

```text
catalogue item / variant / add-on
 -> active recipe
 -> recipe components
 -> branch inventory
 -> append-only stock movement ledger
 -> authoritative quote sufficiency
 -> transactional placement depletion
 -> cancellation reversal
```

Phase 4 had to close first because inventory must deplete against a trusted persisted branch and accepted order, not client-selected location state. Loyalty/rewards/vouchers remain Phase 6 and promotions/discounts remain Phase 7.

## Implemented schema and authority

Phase 5 adds:

- `public.inventory_items` — globally defined stock inputs with base unit `g`, `ml`, or `unit`;
- `public.branch_inventory` — one non-negative current balance per branch + inventory item;
- `public.inventory_movements` — append-only receiving/waste/adjustment/order-consumption/order-reversal ledger;
- `public.recipes` — item-default or variant-specific active recipe definitions;
- `public.recipe_components` — positive integer component requirements;
- Admin/Owner inventory-item, stock-movement, recipe and state RPCs;
- quote-time branch stock sufficiency checks;
- transactionally enforced order-line and add-on stock consumption;
- exactly-once cancellation reversal.

Physical quantities use integer milli-units. Money remains integer sen and is unchanged.

Recipe control is opt-in. Catalogue items/add-ons without an active recipe remain orderable. Once an active recipe exists, its active components are required inventory authority. Exact variant recipes take precedence over an item-default recipe.

## Canonical migrations

All executable migrations remain only under `Aida_System/supabase/migrations/`:

- `20260914172515_create_inventory_recipe_authority.sql`
- `20260914172636_integrate_inventory_with_orders.sql`
- `20260914172835_index_inventory_recipe_foreign_keys.sql`
- `20260914173303_fix_inventory_admin_rpc_write_boundary.sql`
- `20260914173609_enforce_active_recipe_inventory_items.sql`
- `20260914174142_attribute_inventory_reversal_to_caller.sql`
- `20260914174807_harden_inventory_private_write_helpers.sql`
- `20260914174924_restore_inventory_invoker_rpc_boundary.sql`

`20260914174807` temporarily moved the public Admin mutation boundary to `SECURITY DEFINER` while removing overly broad private-helper execution. The live security advisor correctly rejected that exposed-definer shape. `20260914174924` is the final authority state: public mutation RPCs are caller-bound `SECURITY INVOKER` wrappers; only guarded private definer helpers are executable by authenticated callers, and those helpers independently verify `p_actor = auth.uid()` plus trusted Admin/Owner authorization before reaching unchecked lower-level write helpers. Direct execution of the unchecked private write helpers is revoked.

## Ordering and concurrency behavior

Quote resolves the same server-validated Phase 4 branch and checks aggregate active recipe requirements against current branch stock. Quote does not reserve inventory.

Placement is final authority. Order-line and add-on insert triggers consume recipe components inside the order transaction. Stock decrements use atomic non-negative updates, so concurrent orders cannot both consume the same final stock. Any failed component consumption rolls back the order transaction. Client-computed stock or recipe quantities are never placement authority.

Order cancellation restores accepted consumption with compensating `order_reversal` movements. A unique reversal reference makes the restoration exactly once. Consumption rows and accepted commercial price/product snapshots are not rewritten.

## Security boundary

Phase 5 preserves the existing trust model:

- RLS + FORCE RLS on exposed Phase 5 tables;
- no direct ordinary authenticated/anonymous inventory or recipe writes;
- no service-role secret in Flutter or browser code;
- no browser-readable reusable employee bearer token or terminal credential;
- Dashboard privileged requests stay behind the same-origin BFF;
- Dashboard BFF forwards the caller employee JWT with the publishable key;
- public inventory mutation entrypoints are `SECURITY INVOKER`;
- guarded private write helpers re-check the trusted caller and Admin/Owner role;
- unchecked private write helpers are not executable by authenticated/anonymous roles;
- preview inventory fixtures are not a live fallback;
- branch identity for accepted orders remains server-owned from the existing customer/POS authority path.

## Dashboard implementation

The Dashboard Inventory page is now live rather than preview-backed. It supports:

- active-branch selection from authoritative operational locations;
- branch stock state;
- inventory-item creation;
- receiving, waste and signed manual adjustment movements;
- live catalogue product/add-on selection for recipes;
- item-default or variant-specific recipe selection;
- multi-component recipes;
- authoritative recipe/stock refresh after mutation;
- explicit out-of-stock display.

The BFF enforces Admin session authority and same-origin mutation requests, and tests verify caller-JWT/publishable-key forwarding, staff denial, cross-origin denial and exact RPC payload mapping.

## Regression coverage

`supabase/tests/inventory_recipes_integration.sql` is transactional and covers:

- FORCE RLS and grant boundaries;
- anonymous/admin RPC denial and authenticated RPC grants;
- public mutation RPCs remaining non-definer;
- unchecked private helper execution denial;
- Admin inventory item and branch receiving setup;
- base item and add-on recipe configuration;
- direct table mutation denial;
- customer inventory-admin denial;
- authoritative quote inventory checking;
- base + add-on consumption;
- insufficient-stock quote rejection;
- stock balance after accepted placement;
- exactly-once consumption movement attribution;
- cancellation stock restoration;
- exactly-once reversal behavior.

The clean-database workflow replays the complete migration chain and executes all Phase 1–5 regressions.

## Validation evidence

Final implementation heads before this documentation closeout:

```text
Aida_System             2b26bc531e2f03c1af1f31e5e51a8b529111fc04
Aida_System-Dashboard   2f6128c40fe0b9778f193c43681ad0b6bbf47653
```

Validation:

```text
Backend database audit #138   COMPLETE
Customer release audit #229   COMPLETE
Dashboard CI #99              COMPLETE
Supabase security advisor     COMPLETE for Phase 5
Supabase performance advisor  COMPLETE for Phase 5
```

The security advisor has no Phase 5 finding. The remaining Auth warning is pre-existing: leaked-password protection is disabled. Performance findings are INFO-level unused-index observations only; Phase 5 foreign-key indexes were added and no missing-FK-index blocker remains.

## Deferred / non-goals

Deferred beyond Phase 5:

- supplier purchasing and purchase orders;
- lot/expiry/serial tracking;
- generalized cross-branch transfer workflow;
- forecasting, par levels and automatic procurement;
- loyalty, rewards and vouchers — Phase 6;
- promotions and discounts — Phase 7;
- reporting/accounting expansion — Phase 8;
- external payment capture/refunds/settlement and deployment-heavy integrations;
- printer/KDS/device integrations.

## App Store impact

Phase 5 adds operational business inventory/recipe data only. It adds no tracking/advertising SDK, protected-device permission, StoreKit/IAP path, external payment processor or new customer identity field. Existing Phase 3 privacy/account-deletion behavior remains unchanged because inventory/recipe records are not customer-owned personal data.

## Handoff

Phase 5 is `COMPLETE`. Phase 6 may begin on dedicated branches from the frozen Phase 5 documentation heads. Existing Phase 1–5 PRs remain draft/unmerged; completion is not merge authorization. A valid independent Phase 1–3 audit blocker still reopens the affected earlier phase under ADR-0013.
