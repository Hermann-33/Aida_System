# Phase 5 Plan — Inventory and Recipes

**Task:** `TASK-OPS-005`  
**Verdict:** `PARTIAL`  
**Date:** 2026-09-15  
**Dependency:** Phase 4 branch scheduling/pickup authority is `COMPLETE`.

## Goal

Make branch inventory and recipe consumption server-authoritative without weakening catalogue, order, topology, shift, scheduling or payment trust boundaries.

Trusted chain:

```text
catalogue item / variant / add-on
 -> active recipe
 -> recipe components
 -> branch inventory stock
 -> append-only stock movement ledger
 -> quote availability hint
 -> transactional order-place depletion
 -> cancellation reversal
```

## Authority model

Supabase/server owns:

- inventory item identity, SKU/name/unit and active state;
- recipe identity, item/variant scope and component quantities;
- branch on-hand quantity;
- stock movement reason/delta/actor/order attribution;
- inventory sufficiency at placement;
- order-triggered depletion and cancellation reversal.

Clients may request privileged inventory/recipe mutations only through controlled Admin/Owner RPCs. Dashboard uses its same-origin HttpOnly BFF with caller-JWT forwarding. No service-role secret or browser-readable reusable employee bearer/terminal credential is introduced.

## Quantity representation

Inventory quantity uses signed integer milli-units (`quantity_milli`). The inventory item declares its base unit (`g`, `ml`, or `unit`). Examples:

- 18 g espresso dose = `18000` milli-g;
- 240 ml milk = `240000` milli-ml;
- 0.5 packaged unit = `500` milli-unit.

This avoids floating-point inventory arithmetic. Money remains integer sen and is unchanged by Phase 5.

## Planned schema

```text
public.inventory_items
public.branch_inventory
public.inventory_movements
public.recipes
public.recipe_components
```

Key properties:

- `inventory_items` are globally defined ingredients/stock units;
- `branch_inventory` is one row per branch + inventory item and stores current on-hand milli-units;
- `inventory_movements` is append-only audit history for receiving, waste, manual adjustment, order consumption and cancellation reversal;
- `recipes` attach to catalogue items, optionally to one catalogue variant;
- `recipe_components` map recipes to inventory items with positive integer milli-unit requirements.

Recipe control is opt-in: a catalogue item/add-on without an active recipe remains orderable and does not consume inventory. Once an active recipe exists, its branch stock becomes authoritative for that item. This preserves existing menu behavior while inventory is configured deliberately instead of inventing stock data.

## Ordering behavior

Quote:

- server resolves the same branch authority established in Phase 4;
- controlled recipes are checked against current branch stock;
- insufficient stock returns an explicit inventory-unavailable failure;
- quote remains advisory with respect to races and never reserves stock.

Placement:

- accepted order-line and add-on recipe consumption decrements branch stock inside the same order transaction;
- each stock decrement uses an atomic non-negative guard so concurrent orders cannot oversell the same branch stock;
- failure rolls back the entire order transaction;
- accepted consumption is recorded in append-only `inventory_movements` with order/line attribution;
- cancellation inserts compensating reversal movements and restores stock exactly once.

Historical commercial snapshots remain immutable. Inventory depletion does not rewrite accepted line prices, recipes or order totals.

## Privileged operations

Admin/Owner RPCs will support:

- inventory item create/update/deactivate;
- branch stock receiving/waste/manual adjustment through append-only movements;
- recipe create/update/activate/deactivate and component replacement;
- inventory/recipe listing for Dashboard administration.

Direct authenticated INSERT/UPDATE/DELETE on inventory authority tables remains denied. RLS + FORCE RLS protect exposed tables.

## Dashboard scope

Phase 5 Dashboard work will add live inventory/recipe administration behind the existing BFF. Preview inventory fixtures must not become backend authority or fallback data.

Minimum live surfaces:

- branch stock list;
- receive/waste/adjust stock movement action;
- recipe list/editor for catalogue products/add-ons and variants;
- clear low/out-of-stock state from authoritative data.

## Customer/POS scope

Customer and POS ordering continue to send catalogue IDs/quantities only. They do not submit authoritative stock, recipe quantities or depletion values. Inventory unavailability must fail closed and surface the server rejection.

## Security requirements

- no service-role secret in clients;
- public/order RPCs remain invoker boundaries where practical;
- privileged helpers live in `private` with explicit grants only;
- SECURITY DEFINER helpers use empty/safe `search_path` and perform trusted role/actor checks where callable;
- direct inventory/recipe DML denied to ordinary browser roles;
- branch-scoped staff cannot forge another branch's stock authority;
- order depletion derives branch from trusted persisted order context.

## Regression plan

Add `supabase/tests/inventory_recipes_integration.sql` covering at minimum:

- RLS/FORCE RLS/grants;
- Admin inventory setup and branch stock movement;
- recipe configuration;
- quote rejection when controlled stock is insufficient;
- successful order consumption;
- concurrent-safe non-negative stock guard semantics;
- add-on recipe consumption;
- cancellation reversal exactly once;
- direct DML denial;
- customer/POS inability to submit inventory authority;
- no regression to Phase 1–4 order/topology/shift/scheduling invariants.

Backend clean-database CI must execute Phase 1–5 regressions. Affected customer/Dashboard tests/builds must be green. Supabase security/performance advisors must be rerun before `COMPLETE`.

## Documentation completion gate

Before Phase 5 can be `COMPLETE`, both repositories must synchronize:

1. this plan/scope/dependency rationale;
2. schema/architecture/contracts/security changes;
3. implementation status and exact validation evidence;
4. deferred/non-goals;
5. handoff/current context;
6. App Store impact.

## Deferred / non-goals

- supplier purchasing, purchase orders and vendor accounting;
- lot/expiry/serial tracking;
- cross-branch transfers beyond explicit future movement support;
- forecasting, par levels and automatic procurement;
- loyalty/rewards/vouchers — Phase 6;
- promotions/discounts — Phase 7;
- reporting/accounting expansion — Phase 8;
- external payment/refund settlement — later phase;
- printer/KDS/device/deployment-heavy work.

## App Store impact

Phase 5 adds no tracking, advertising SDK, protected-device permission, StoreKit/IAP or new customer identity category. Inventory and recipe data are operational business data. Existing Phase 3 privacy/account deletion behavior is unchanged.
