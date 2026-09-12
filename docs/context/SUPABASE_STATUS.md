# Supabase Status

**Status date:** 2026-09-11  
**Project:** Aida System  
**Ref:** `eswovqxqzfevcdwwcmuh`  
**Region:** `ap-southeast-1`

## Current role

Supabase is the shared trusted backend for the Flutter customer app and the React Dashboard/Admin/POS.

Canonical executable migration files live only in `Hermann-33/Aida_System/supabase/migrations/` unless an accepted ADR changes ownership.

## Trusted domains currently live

Supabase authority currently covers:

- Supabase Auth identity;
- `user_profiles` employee role/disabled state;
- `members` customer membership identity;
- shared catalogue, variants, option groups/values and compatible add-ons;
- authoritative quote/order pricing and immutable commercial snapshots;
- global ordering/scheduling policy and immutable scheduled preparation timestamps;
- branch identity and employee branch assignments;
- sales points and terminals;
- one-time terminal enrolment and terminal credentials;
- terminal-bound POS placement and immutable branch/sales-point/terminal order attribution;
- versioned fulfilment transitions and order events.

## Phase 1 topology resources

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

Live seed topology:

```text
BR-MAIN — Main Café
  SP-MAIN — Main Counter
    POS-MAIN-01 [pending]
```

The seeded terminal is intentionally pending until a manager enrols/activates it.

## Current live observations

```text
branches                      1
active branches               1
default branches              1
sales points                  1
terminals                     1
active seeded terminals       0
orders total                 25
orders without branch         0
attributed historical POS     0
customer orders with terminal 0
```

Historical orders were backfilled only with trusted branch identity. Sales-point/terminal identity is not fabricated retroactively.

## Relevant migration tail

```text
20260812152607 create_shared_catalogue
20260812154805 harden_catalogue_rls_policies
20260812182212 create_authoritative_orders_and_scheduling
20260812183029 index_order_foreign_keys
20260820151421 add_scheduled_order_preparation_window
20260820214041 refresh_catalogue_product_images
20260820221139 replace_americano_catalogue_image
20260822135421 add_drink_customization_catalogue
20260822135602 integrate_drink_customizations_with_orders
20260822141814 harden_drink_customization_indexes_and_rls
20260822143542 grant_public_drink_customization_reads
20260910014434 create_branch_location_authority
20260910014457 index_employee_branch_assignment_actor
20260910023510 create_operational_sales_points_and_terminals
20260910023552 harden_operational_topology_rls_and_indexes
20260910040814 revoke_direct_branch_mutation_grants
20260910041057 enforce_terminal_branch_scope_on_resolution
20260910042619 differentiate_terminal_resolution_failures
20260910044613 grant_branch_rpc_private_impl_execution
20260910050152 grant_admin_operational_topology_reads
```

The final two Phase 1 closeout migrations repair permission gaps discovered during clean-database replay while preserving the intended authorization model.

## Identity and branch authorization

Trusted employee authorization is server-owned through `user_profiles.app_role` plus `disabled_at`.

Operational branch scope is server-owned through `employee_branch_assignments`:

- ordinary staff may operate only assigned branches;
- staff with no assignment fail closed;
- Admin/Owner remain global operational roles for the current tranche;
- customer ownership rules remain separate and unchanged.

Public signup cannot self-assign privileged roles, branch scope or member codes.

## Operational topology authorization

`branches`, `sales_points` and `terminals` are authoritative server entities. IDs are server-owned UUIDs and stable operational codes remain backend data.

Admin/Owner management uses controlled RPCs through the Dashboard BFF. Direct mutation grants are denied.

`public.sales_points` and `public.terminals` grant SELECT to `authenticated` only so `SECURITY INVOKER` Admin topology RPCs can read them. FORCE-RLS policies still expose rows only to Admin/Owner. Anonymous SELECT remains denied.

One-time terminal enrolment codes are private server state. Successful enrolment issues a terminal credential stored server-side as a hash and returned once to the BFF for HttpOnly cookie storage.

Terminal resolution validates:

- credential validity;
- terminal status/revocation;
- active sales point and branch relationship;
- caller employee status;
- caller branch scope.

Revocation blocks resolution and placement immediately.

## POS placement contract

The legacy credentialless signature exists only for compatibility history and is not executable by `authenticated`:

```text
place_pos_order(jsonb)              authenticated execute: false
place_pos_order(jsonb,text)         authenticated execute: true
```

The terminal-bound function resolves trusted topology from the terminal credential. Browser/client payloads do not become authority for `branch_id`, `sales_point_id` or `terminal_id`.

Customer placement remains terminal-free and resolves the active default branch server-side for current compatibility.

## Catalogue/order authority

Catalogue authority remains server-owned across products, variants, option groups/values, compatible add-ons, availability and integer-sen prices.

Order selection payloads may include:

```text
itemId
variantId?
optionValueIds[]
addOnIds[]
quantity
note?
```

`quote_order(jsonb)` calculates authoritative `pricingVersion=2` totals. Required option groups omitted by older clients resolve through configured available defaults.

Immutable commercial history remains stored in `orders`, `order_lines`, `order_line_addons`, `order_line_options` and `order_events`.

## Scheduling

Current global policy remains:

```text
timezone                 Asia/Kuala_Lumpur
schedule_enabled         true
minimum_lead_minutes     15
preparation_lead_minutes 15
slot_interval_minutes    15
maximum_advance_days     7
```

Scheduled orders snapshot immutable `prepare_at`. Branch-specific hours, closures and capacity remain Phase 4.

## Realtime

`supabase_realtime` publishes the intended mutable invalidation signals:

- `catalogue_revision` for catalogue refetch;
- `orders` for authorized customer order refetch.

Dashboard employee clients continue to poll/refetch same-origin BFF endpoints because the employee bearer token is HttpOnly and not exposed to React.

## Executable database evidence

Backend database audit run #22 rebuilt a clean local Supabase environment from the canonical migration ledger and passed:

```text
branch_authority_integration.sql              PASS
operational_topology_integration.sql         PASS
order_integration.sql                        PASS
scheduled_order_operations_integration.sql   PASS
```

This closes the previous writable-database validation gap.

## Advisor state

Security advisor at Phase 1 closeout reports one pre-existing WARN only:

```text
auth_leaked_password_protection — Leaked Password Protection Disabled
```

No Phase 1-created security WARN/ERROR remains.

Performance advisor findings are INFO-only unused indexes on the current small dataset. The earlier missing FK-supporting index on `employee_branch_assignments.assigned_by` was fixed by migration `20260910014457`.

## Preserved non-live drafts

Account-deletion/referral prototypes under `supabase/drafts/` remain non-live and outside canonical migrations. They must not be treated as deployed backend authority.

## Still deferred backend authority

- shifts/cash reconciliation;
- employee Auth-user provisioning, role mutation and badge/PIN lifecycle;
- branch opening hours/closures/capacity and explicit customer branch selection;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- tax/accounting/reporting;
- real payment capture/refunds/processor settlement;
- printer/KDS/payment-device integrations;
- delivery;
- hosted production operations.

Phase 1 evidence: `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.
