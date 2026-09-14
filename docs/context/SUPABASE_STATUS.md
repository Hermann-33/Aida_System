# Supabase Status

**Status date:** 2026-09-15  
**Project:** Aida System  
**Ref:** `eswovqxqzfevcdwwcmuh`  
**Region:** `ap-southeast-1`  
**Implementation verdict:** Phases 1–5 `COMPLETE`; Phase 6 `PARTIAL`.

## Current role

Supabase is the shared trusted backend for the Flutter customer app and React Dashboard/Admin/POS. Canonical executable migration files live only in `Hermann-33/Aida_System/supabase/migrations/`.

Trusted authority through Phase 5 covers:

- Supabase Auth identity and trusted profile role/disabled state;
- customer membership and privacy/account-deletion state;
- branch identity, employee branch assignments, sales points and terminals;
- terminal enrolment/revocation and terminal credentials;
- shift lifecycle, append-only cash movements and server-derived reconciliation;
- catalogue/options/add-ons, integer-sen prices and immutable order snapshots;
- POS shift/tender/payment classification;
- branch-local pickup policy, hours/exceptions, lead/horizon/slot rules and scheduled capacity;
- inventory items, branch balances, recipes/components and append-only stock movements;
- transactional inventory depletion and exactly-once cancellation reversal.

Client/browser values remain intent only for these domains. Dashboard privileged access remains behind the same-origin HttpOnly BFF with caller-JWT forwarding and no service-role credential in browser code.

## Phase 1 resources — topology

```text
public.branches
public.employee_branch_assignments
public.sales_points
public.terminals
private.terminal_enrolment_codes
private.terminal_credentials
public.orders.branch_id
public.orders.sales_point_id
public.orders.terminal_id
```

## Phase 2 resources — shifts/cash

```text
public.shifts
public.cash_movements
public.orders.shift_id
public.orders.tender_type
public.orders.payment_state
public.orders.paid_at
```

## Phase 3 resources — privacy/account deletion

```text
public.customer_privacy_preferences
public.orders.customer_deleted_at
public.get_my_privacy_preferences()
public.save_my_privacy_preferences(...)
public.delete_own_account()
```

Whole-account deletion is caller-bound to `auth.uid()`, accepts no target user ID, scrubs retained customer-authored free text and anonymizes retained customer commercial history without weakening staff/POS audit identity.

## Phase 4 resources — branch scheduling/pickup

```text
public.branch_ordering_policies
public.branch_service_windows
public.branch_service_exceptions
public.list_active_branches()
public.get_branch_pickup_state(...)
public.list_available_pickup_slots(...)
Admin/Owner branch pickup configuration RPCs
```

Customer branch selection is validated intent. POS branch authority remains terminal/open-shift derived. Scheduled placement validates branch-local calendar/policy and serializes branch+slot capacity before persistence.

Canonical Phase 4 migration tail:

```text
20260914153532 create_branch_scheduling_authority
20260914153751 implement_branch_pickup_policy_rpcs
20260914154002 enforce_branch_pickup_on_orders
20260914154100 preserve_ordering_policy_compatibility
20260914154200 harden_public_branch_pickup_rpcs
20260914154300 grant_phase4_private_rpc_schema_usage
20260914154400 preserve_quote_schedule_policy_timezone
20260914154500 grant_quote_pickup_helper_execute
20260914165306 optimize_branch_scheduling_read_policies
20260914165735 reconcile_phase4_rpc_contract
20260914170102 normalize_branch_scheduling_validation_error
20260914170625 restore_customer_payment_authority_guard
```

## Phase 5 resources — inventory/recipes

```text
public.inventory_items
public.branch_inventory
public.inventory_movements
public.recipes
public.recipe_components
public.list_inventory_state(uuid)
public.save_inventory_item(jsonb)
public.record_inventory_movement(...)
public.save_recipe(jsonb)
```

Inventory physical quantities are signed integer milli-units; resulting on-hand stock cannot be client-supplied. Quote checks branch stock but does not reserve it. Placement consumes recipe requirements transactionally with non-negative enforcement. Cancellation writes compensating reversal movements rather than mutating historical consumption.

Canonical Phase 5 migrations:

```text
20260914172515 create_inventory_recipe_authority
20260914172636 integrate_inventory_with_orders
20260914172835 index_inventory_recipe_foreign_keys
20260914173303 fix_inventory_admin_rpc_write_boundary
20260914173609 enforce_active_recipe_inventory_items
20260914174142 attribute_inventory_reversal_to_caller
20260914174807 harden_inventory_private_write_helpers
20260914174924 restore_inventory_invoker_rpc_boundary
```

## Security boundary

- RLS + FORCE RLS protects exposed trusted tables where required.
- Ordinary authenticated/anonymous roles do not receive direct mutation authority over topology, shift/cash, privacy, branch-scheduling, inventory or recipe state.
- Public privileged mutation RPCs use caller-bound invoker boundaries where practical.
- Narrow private `SECURITY DEFINER` helpers use explicit caller/role checks and restricted execute grants.
- Dashboard employee/terminal credentials remain HttpOnly; browser JavaScript does not receive the reusable employee bearer token or terminal credential.
- Customer-editable Auth metadata is not authorization authority.
- Preview fixtures never become backend authority.

## Validation evidence through Phase 5

Phase 5 final implementation validation:

```text
Backend database audit #138   COMPLETE
Customer release audit #229   COMPLETE
Dashboard CI #99              COMPLETE
Supabase security advisor     COMPLETE for Phase 5
Supabase performance advisor  COMPLETE for Phase 5
```

The Phase 5 security advisor reported no Phase 5-created finding. The remaining Auth warning is the pre-existing leaked-password-protection setting. Performance findings were INFO-level unused-index observations; Phase 5 FK support indexes are present.

Full evidence: `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`.

## Current Phase 6 boundary

Phase 6 is planned but not complete. It owns server-authoritative loyalty points, stamps, rewards, customer vouchers and voucher application/consumption. Its plan is `docs/context/PHASE_6_LOYALTY_REWARDS_VOUCHERS_PLAN.md`.

No Phase 6 schema/migration may be marked complete until canonical migration replay, transactional regressions, affected customer/Dashboard validation and Supabase security/performance advisors all pass against the actual Aida System project.

## Deferred backend authority

- generalized promotions/discounts — Phase 7;
- reporting/tax/accounting export — Phase 8;
- supplier purchasing, lot/expiry tracking, forecasting and automated procurement;
- external payment capture/refunds/processor settlement;
- employee Auth-user/credential lifecycle;
- printer/KDS/payment-device integration;
- notification/marketing delivery provider;
- delivery and deployment-heavy production infrastructure.

## Governance

Phases 1–5 remain individually `COMPLETE` and their PRs remain draft/unmerged unless explicitly authorized. Under ADR-0013, the independent Phase 1–3 Codex audit may run in parallel; any valid blocking finding reopens the affected earlier phase. Phase 6 remains `PARTIAL` until its full completion gate passes.
