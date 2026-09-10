# Database Schema Foundation

Updated: 2026-09-11

Canonical executable migrations are owned by `Hermann-33/Aida_System/supabase/`. The Dashboard repository mirrors this schema documentation but does not own a second migration ledger.

## Identity/member foundation

Trusted identity/membership tables:

- `user_profiles` — Auth-linked application profile, trusted `app_role`, disabled state and profile fields;
- `members` — customer membership identity and server-generated member code;
- `student_verifications` — trusted verification-review records.

Public signup provisions customer-only trusted state. Clients cannot self-promote employee roles, assign trusted member codes/verification outcomes or grant branch scope.

## Shared catalogue foundation

Core live catalogue tables:

```text
catalogue_categories
catalogue_items
catalogue_item_variants
catalogue_item_addons
catalogue_option_groups
catalogue_option_values
catalogue_item_option_values
catalogue_revision
catalogue_audit_events
```

Money is integer sen. Catalogue IDs are server-owned UUIDs. Product/add-on availability, variants, option values, compatibility and prices are backend authority.

`catalogue_revision` is a public read-only invalidation signal, not catalogue truth.

## Authoritative order/scheduling foundation

Core order tables:

```text
order_schedule_settings
orders
order_lines
order_line_addons
order_line_options
order_events
```

`orders` contains server-owned order identity, source, trusted actor references, fulfilment intent, versioned status, integer-sen totals, scheduling timestamps and operational topology attribution.

`order_lines`, `order_line_addons` and `order_line_options` preserve immutable accepted commercial snapshots.

All exposed order tables use RLS + FORCE RLS. Ordinary customers receive no direct commercial INSERT/UPDATE authority; controlled RPCs own quote/place/read/status operations.

Current core RPC surface includes:

```text
get_ordering_policy()
quote_order(jsonb)
place_customer_order(jsonb)
place_pos_order(jsonb,text)
get_order(uuid)
get_my_orders(integer)
list_orders(text[],integer)
transition_order_status(uuid,text,bigint,text)
save_ordering_policy(jsonb)
```

The legacy credentialless `place_pos_order(jsonb)` signature is not executable by `authenticated`.

## Branch and employee operational scope

Live branch resources:

```text
branches
employee_branch_assignments
orders.branch_id
```

`orders.branch_id` is non-null, foreign-keyed and immutable.

Current seed:

```text
BR-MAIN — Main Café
Asia/Kuala_Lumpur
active/default
```

Authorization:

- customer ownership remains owner-scoped;
- ordinary staff can read/transition only assigned-branch orders;
- staff without assignments fail closed;
- Admin/Owner remain global operational roles for the current tranche;
- public branch directory reads expose active branch data only;
- branch/assignment mutations use controlled Admin/Owner RPCs.

## Phase 1 sales-point and terminal foundation

Live topology tables:

```text
public.sales_points
public.terminals
private.terminal_enrolment_codes
private.terminal_credentials
orders.sales_point_id
orders.terminal_id
```

Relationships:

```text
branches.id
  <- sales_points.branch_id
     <- terminals.sales_point_id

orders.branch_id
orders.sales_point_id
orders.terminal_id
```

Database constraints and server functions preserve topology consistency. Accepted POS attribution is immutable.

Live seed:

```text
BR-MAIN
  SP-MAIN
    POS-MAIN-01 [pending]
```

The terminal remains pending until manager-issued one-time enrolment creates an active credential.

`terminal_enrolment_codes` and `terminal_credentials` are private schema state and are not direct client tables.

Terminal credential resolution validates credential state, terminal status, sales-point/branch active state and employee branch authorization.

Customer orders keep `sales_point_id` and `terminal_id` null.

## RLS/grant model

Operational tables use RLS + FORCE RLS.

- browser roles have no direct INSERT/UPDATE/DELETE on branches, sales points or terminals;
- `authenticated` SELECT on `sales_points`/`terminals` exists to support SECURITY INVOKER Admin topology RPCs;
- RLS policies expose those rows only to Admin/Owner;
- anonymous SELECT remains denied;
- branch public reads are separately active/read-only;
- private terminal credential tables are not client-readable.

## Scheduling defaults

Current singleton policy:

```text
timezone                 Asia/Kuala_Lumpur
schedule_enabled         true
minimum_lead_minutes     15
preparation_lead_minutes 15
slot_interval_minutes    15
maximum_advance_days     7
```

Scheduled orders persist immutable `prepare_at`. Branch hours/closures/capacity are not yet modeled and belong to Phase 4.

## Phase 1 canonical migrations

```text
20260910014434_create_branch_location_authority.sql
20260910014457_index_employee_branch_assignment_actor.sql
20260910023510_create_operational_sales_points_and_terminals.sql
20260910023552_harden_operational_topology_rls_and_indexes.sql
20260910040814_revoke_direct_branch_mutation_grants.sql
20260910041057_enforce_terminal_branch_scope_on_resolution.sql
20260910042619_differentiate_terminal_resolution_failures.sql
20260910044613_grant_branch_rpc_private_impl_execution.sql
20260910050152_grant_admin_operational_topology_reads.sql
```

## Canonical regression coverage

Phase 1 database audit executes transactionally:

```text
branch_authority_integration.sql
operational_topology_integration.sql
order_integration.sql
scheduled_order_operations_integration.sql
```

GitHub Actions backend database audit run #22 rebuilt a clean Supabase environment from the canonical ledger and all four suites passed.

Synthetic test data rolls back.

## Current live Phase 1 observations

```text
branches                      1
sales points                  1
terminals                     1
active seeded terminals       0
orders total                 25
orders without branch         0
customer orders with terminal 0
```

Historical orders are not assigned fabricated sales-point/terminal IDs.

## Deferred schema domains

Not yet trusted/live schema authority:

- shifts and cash movement/reconciliation;
- employee provisioning/role/badge/PIN lifecycle;
- branch hours/closures/capacity;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- tax/accounting/reporting;
- payment settlement/refunds;
- device/KDS/printer integrations;
- delivery.

Full closeout evidence: `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.
