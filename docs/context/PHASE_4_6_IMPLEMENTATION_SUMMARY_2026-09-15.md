# Phases 4–6 Implementation Summary — 2026-09-15

**Scope:** cumulative implementation record for Phases 4, 5 and 6.  
**Verdict:** Phases 4–6 are `COMPLETE`.  
**Repositories:** `Hermann-33/Aida_System` + `Hermann-33/Aida_System-Dashboard`.  
**Backend:** Supabase project `eswovqxqzfevcdwwcmuh`.  
**Canonical migration ownership:** executable migrations live only under `Hermann-33/Aida_System/supabase/migrations/`.

This document is the cumulative handoff for all material changes introduced from Phase 4 through Phase 6. The phase-specific plans and closeouts remain authoritative for detailed evidence; this summary connects the three phases and records the final combined authority model.

## Cumulative authority chain

```text
Phase 4
active branch
 -> branch-local service calendar
 -> pickup policy
 -> lead/horizon/slot interval
 -> slot capacity
 -> authoritative quote/place

Phase 5
trusted accepted branch/order
 -> active recipe
 -> recipe components
 -> branch inventory
 -> append-only stock movements
 -> transactional depletion/reversal

Phase 6
trusted member
 -> loyalty program
 -> append-only points/stamp ledgers
 -> server-derived balances
 -> rewards
 -> issued voucher
 -> authoritative discount
 -> atomic voucher consumption
 -> immutable commercial voucher snapshot
```

Across all three phases, client state remains intent only. Supabase/server remains authoritative for branch/scheduling/capacity, inventory/recipes/depletion, member loyalty state, reward/voucher eligibility, discounts and persisted commercial facts. Money remains integer sen. Inventory physical quantities use integer milli-units. Dashboard privileged flows remain behind the same-origin HttpOnly BFF with caller-JWT forwarding and no normal service-role path.

# Phase 4 — Branch Scheduling and Pickup Authority

**Task:** `TASK-OPS-004`  
**Verdict:** `COMPLETE`

## Backend changes

Phase 4 introduced server-owned branch pickup scheduling through:

- `branch_ordering_policies` for ASAP enablement, scheduled-order enablement, lead/preparation times, slot interval, maximum advance and optional per-slot capacity;
- `branch_service_windows` for recurring weekly branch-local service windows;
- `branch_service_exceptions` for dated closure/open-hours/capacity overrides;
- safe defaults for newly created branches;
- authoritative active-branch, pickup-state and slot-listing RPCs;
- Admin/Owner policy/window/exception mutation RPCs;
- customer branch selection as validated intent only;
- POS branch derivation from trusted terminal/open-shift authority;
- transaction-scoped slot-capacity serialization and recheck;
- server-derived `prepare_at`;
- persisted creation-event normalization from the accepted order row.

Existing branches were initialized with all-day/unlimited capacity so Phase 4 did not invent business hours or silently make previously valid ordering unavailable.

## Canonical Phase 4 migrations

```text
20260914153532_create_branch_scheduling_authority.sql
20260914153751_implement_branch_pickup_policy_rpcs.sql
20260914154002_enforce_branch_pickup_on_orders.sql
20260914154100_preserve_ordering_policy_compatibility.sql
20260914154200_harden_public_branch_pickup_rpcs.sql
20260914154300_grant_phase4_private_rpc_schema_usage.sql
20260914154400_preserve_quote_schedule_policy_timezone.sql
20260914154500_grant_quote_pickup_helper_execute.sql
20260914165306_optimize_branch_scheduling_read_policies.sql
20260914165735_reconcile_phase4_rpc_contract.sql
20260914170102_normalize_branch_scheduling_validation_error.sql
20260914170625_restore_customer_payment_authority_guard.sql
```

## Customer changes

Customer checkout now:

- reads active pickup branches from authoritative RPCs;
- uses server pickup state and authoritative slot listing;
- submits branch/pickup time only as intent;
- binds quote and placement to the same selected branch;
- fails closed when authoritative availability cannot be loaded;
- preserves retry-stable placement idempotency.

The retained local slot helper is compatibility/test-only and is not production scheduling authority.

## Dashboard changes

Dashboard gained live scheduling administration behind the BFF, including:

- weekly service windows;
- lead/preparation times;
- slot interval and horizon;
- branch slot capacity;
- dated closure/open-hours/capacity overrides;
- same-origin mutation enforcement;
- caller-JWT/publishable-key forwarding;
- fail-closed propagation of scheduling rejection to POS.

Preview scheduling fixtures remain non-authoritative.

## Phase 4 validation

```text
Backend database audit #122   COMPLETE
Customer release audit #213   COMPLETE
Dashboard CI #84              COMPLETE
Supabase security advisor     COMPLETE for Phase 4
Supabase performance advisor  COMPLETE for Phase 4
```

Primary regression: `supabase/tests/branch_scheduling_pickup_integration.sql`.

# Phase 5 — Inventory and Recipes

**Task:** `TASK-OPS-005`  
**Verdict:** `COMPLETE`

## Backend changes

Phase 5 introduced:

- `inventory_items` with base units `g`, `ml`, or `unit`;
- `branch_inventory` with non-negative current balances;
- append-only `inventory_movements` for receiving, waste, adjustment, order consumption and reversal;
- `recipes` for item-default or variant-specific active recipes;
- positive integer `recipe_components`;
- Admin/Owner inventory, stock-movement, recipe and state RPCs;
- quote-time stock sufficiency checks;
- transactional order-line/add-on depletion;
- exactly-once cancellation reversal.

Recipe control is opt-in. Catalogue items/add-ons without an active recipe remain orderable. Exact variant recipes take precedence over item-default recipes.

Quote checks availability but does not reserve inventory. Placement is final authority. Atomic non-negative updates prevent concurrent orders from both consuming the same final stock; failed consumption rolls back the order transaction.

## Canonical Phase 5 migrations

```text
20260914172515_create_inventory_recipe_authority.sql
20260914172636_integrate_inventory_with_orders.sql
20260914172835_index_inventory_recipe_foreign_keys.sql
20260914173303_fix_inventory_admin_rpc_write_boundary.sql
20260914173609_enforce_active_recipe_inventory_items.sql
20260914174142_attribute_inventory_reversal_to_caller.sql
20260914174807_harden_inventory_private_write_helpers.sql
20260914174924_restore_inventory_invoker_rpc_boundary.sql
```

The final mutation boundary keeps public Admin mutation RPCs caller-bound `SECURITY INVOKER`; guarded private definer helpers independently re-check actor identity and Admin/Owner authority. Unchecked private write helpers are not executable by normal authenticated/anonymous roles.

## Dashboard changes

The Inventory page moved from preview to live authority and supports:

- authoritative active-branch selection;
- branch stock state;
- inventory-item creation;
- receiving, waste and signed adjustment movements;
- live catalogue product/add-on selection for recipes;
- item-default and variant-specific recipes;
- multi-component recipes;
- refresh of authoritative stock/recipe state after mutation;
- explicit out-of-stock state.

The BFF enforces Admin session authority and same-origin writes; preview inventory remains isolated from live authority.

## Phase 5 validation

```text
Backend database audit #138   COMPLETE
Customer release audit #229   COMPLETE
Dashboard CI #99              COMPLETE
Supabase security advisor     COMPLETE for Phase 5
Supabase performance advisor  COMPLETE for Phase 5
```

Primary regression: `supabase/tests/inventory_recipes_integration.sql`.

# Phase 6 — Loyalty, Rewards and Vouchers

**Task:** `TASK-OPS-006`  
**Verdict:** `COMPLETE`

## Backend changes

Phase 6 introduced server-authoritative:

- loyalty program configuration;
- member loyalty accounts/current state;
- append-only points and stamp ledgers;
- exactly-once completed-order earning anchors;
- reward catalogue/configuration;
- atomic points redemption and milestone issuance;
- member-issued vouchers;
- voucher eligibility/expiry/state;
- customer wallet/reward redemption RPCs;
- Admin/Owner loyalty configuration, reward management and audited support adjustments;
- shift/terminal-bound POS member loyalty lookup;
- authoritative voucher quote discount;
- placement-time voucher revalidation and atomic one-time consumption;
- immutable voucher/discount commercial snapshots on accepted orders;
- privacy-compatible removal/detachment of customer-owned loyalty identity during whole-account deletion.

Customers and POS submit only member/reward/voucher intent. They do not author points, balances, voucher state, eligibility, discount or resulting totals.

## Canonical Phase 6 migrations

```text
20260914183500_create_loyalty_rewards_voucher_authority.sql
20260914183600_harden_loyalty_authority_foundation.sql
20260914183800_integrate_vouchers_with_order_authority.sql
20260914183900_make_voucher_consumption_trigger_internal.sql
20260914184000_preserve_loyalty_privacy_deletion.sql
20260914184100_expose_voucher_commercial_snapshot.sql
20260914184200_separate_voucher_quote_from_consumption_lock.sql
20260914184300_add_loyalty_admin_authority.sql
20260914184400_add_loyalty_program_configuration_authority.sql
20260914184500_add_pos_loyalty_lookup_authority.sql
20260914235500_restore_privacy_anonymization_boundary.sql
20260914235600_harden_pos_order_authority_boundary.sql
20260915000500_reconcile_loyalty_account_deletion.sql
20260915002000_reconcile_partial_phase6_live_schema.sql
20260915002800_index_loyalty_foreign_keys.sql
```

The live AIDA project contained an obsolete partial loyalty draft. Before replacement, live customer loyalty accounts, point/stamp ledgers and member vouchers were all verified at zero rows. The guarded reconciliation refuses destructive replacement if customer loyalty data exists, then replaces the unused draft with the canonical Phase 6 schema.

Six Phase 6 foreign keys initially lacked covering indexes; `20260915002800_index_loyalty_foreign_keys.sql` added them and the performance advisor was rerun successfully.

## Customer changes

The customer app now uses live server authority for:

- loyalty wallet;
- points/stamps;
- reward catalogue;
- atomic reward redemption;
- issued voucher wallet;
- checkout voucher selection;
- server-derived voucher discount.

Checkout sends only `voucherId` intent and re-quotes before placement. Customer visual tests use deterministic loyalty fixtures rather than live Supabase.

The customer release workflow was hardened so full-screen goldens are a real blocking gate rather than `continue-on-error` advisory output. The golden comparator uses the checked-in baseline path correctly and retains a strict raster-stability boundary.

## Dashboard/POS changes

Dashboard Phase 6 provides:

- Admin/Owner loyalty program configuration;
- reward create/edit/enable/disable;
- member-code support lookup;
- audited points/stamp adjustments;
- terminal/open-shift-bound POS member lookup;
- trusted active voucher selection at POS;
- quote invalidation whenever member/voucher intent changes;
- live order parsing/authority hardening inherited from the Phase 1–3 audit remediation.

Employee bearer and terminal credential remain HttpOnly/BFF-held. Preview member/reward state is never live authorization.

## Phase 1–3 remediation integrated during Phase 6

While Phase 6 was being completed, valid independent Codex findings against the Phase 1–3 foundation were fixed cumulatively without weakening later-phase authority. Relevant fixes included:

- removal of ordinary authenticated execution of the generic private order writer;
- narrower trusted POS placement authority;
- safe recovery of an already-persisted idempotent POS request after shift lock/close without allowing a genuinely new order;
- restoration of the one-way Phase 3 anonymization exception after later commercial immutability hardening;
- replacement of deleted customer request payload hashes with deletion-safe markers;
- loyalty-aware whole-account deletion;
- live Admin Shifts authority instead of fixture-backed live state;
- strict POS order/topology/shift parsing;
- blocking Dashboard live-POS E2E coverage;
- blocking customer full-screen golden coverage;
- signed-out guest catalogue access through the public catalogue boundary.

Detailed evidence: `PHASE_1_3_CODEX_AUDIT_REMEDIATION_CLOSEOUT_2026-09-15.md`.

## Phase 6 validation

Implementation heads before Phase 6 documentation closeout:

```text
Aida_System             9273ba8f6c2f3d42404d9f6a34005bdde3df69e0
Aida_System-Dashboard   9979df27ed663b779c3d5c79670de4f19367b01c
```

```text
Backend database audit #190   COMPLETE
Customer release audit #281   COMPLETE
Dashboard CI #126             COMPLETE
Live AIDA Supabase deployment COMPLETE
Supabase security advisor     COMPLETE for Phase 6
Supabase performance advisor  COMPLETE for Phase 6
```

Documentation-head revalidation also passed:

```text
Backend database audit #195   COMPLETE
Customer release audit #286   COMPLETE
Dashboard CI #127             COMPLETE
```

The only remaining Supabase security WARN is the pre-existing leaked-password-protection setting. It is not a Phase 4–6 regression.

# Cross-phase security and architecture result

After Phase 6:

- customer orders remain terminal/shift-free;
- POS topology and shift attribution remain server-owned;
- branch/pickup scheduling is server-owned;
- quote never becomes reservation authority for slot or inventory unless placement succeeds;
- inventory depletion is transactional and non-negative;
- stock movement history is append-only;
- points/stamp ledgers are server-owned;
- voucher state and discount are server-owned;
- accepted commercial facts remain immutable snapshots;
- whole-account deletion covers customer-owned loyalty state without removing legitimate non-identifying transaction history;
- no browser/client service-role secret was introduced;
- Dashboard employee and terminal credentials remain HttpOnly;
- Preview fixtures remain presentation-only.

# Documentation updated through Phase 6

The mirrored/current governance set includes:

- `ACTIVE_CONTEXT.md`
- `HANDOFF.md`
- `IMPLEMENTATION_PHASES.md`
- `ARCHITECTURE.md`
- `SYSTEM_MAP.md`
- `SUPABASE_STATUS.md`
- `APP_STORE_READINESS.md`
- `SHARED_BACKEND_CONTRACT.md`
- Phase 4 plan/closeout
- Phase 5 plan/closeout
- Phase 6 plan/closeout
- Phase 1–3 Codex remediation closeout
- `CODEX_AUDIT_WORKFLOW.md`
- this cumulative Phase 4–6 summary

Dashboard-specific audit/state/fragile-boundary/mock documentation is current through Phase 6.

# Deferred after Phase 6

The following are not Phase 4–6 implementation gaps:

- generalized promotions/discounts — Phase 7;
- reporting/accounting/audit — Phase 8;
- external payment capture/refunds/settlement and integrations — Phase 9;
- final App Store release gate — Phase 10;
- employee Auth provisioning/credential lifecycle unless explicitly pulled into a later approved phase;
- printer/KDS/payment-device hardware integrations unless explicitly approved;
- supplier purchasing, lots/expiry, forecasting/procurement automation;
- deployment-heavy production infrastructure unless a later approved phase owns it.

# Handoff

Phases 4–6 are `COMPLETE`. Their PRs remain draft/unmerged; completion does not authorize merge. Phase 7 is the next implementation dependency boundary. Any valid Phase 4–6 audit finding reopens only the affected boundary and must be resolved before a dependent later phase is considered fully closed.
