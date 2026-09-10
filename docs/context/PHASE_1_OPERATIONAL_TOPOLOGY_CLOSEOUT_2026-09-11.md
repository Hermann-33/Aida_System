# Phase 1 Operational Topology Closeout

**Date:** 2026-09-11  
**Phase:** Phase 1 — Operational topology  
**Task:** `TASK-OPS-002`  
**Verdict:** `COMPLETE`  
**Audit state:** frozen for Astra review; do not begin Phase 2 until Astra findings are resolved or explicitly accepted.

## Goal

Establish trusted operational identity from branch through sales point and terminal to a live POS order without trusting browser-supplied location identifiers.

```text
branch
 -> sales point
 -> terminal
 -> employee branch scope
 -> POS order attribution
```

## Trusted backend now in place

Phase 1 builds on the previously deployed branch foundation and adds authoritative sales-point and terminal topology.

Trusted resources now include:

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

Operational invariants:

- every persisted order has immutable trusted `branch_id`;
- customer orders remain free of sales-point/terminal attribution;
- new live POS placement requires an active enrolled terminal credential;
- the terminal resolves its own branch and sales point server-side;
- ordinary staff may operate only branches present in `employee_branch_assignments`;
- Admin/Owner retain global operational scope for the current tranche;
- terminal enrolment uses a one-time manager-issued code;
- the browser stores the issued terminal credential only in an HttpOnly cookie through the Dashboard BFF;
- terminal revocation invalidates terminal authority immediately;
- direct operational-topology DML remains denied to browser roles;
- the credentialless `place_pos_order(jsonb)` path is not executable by `authenticated`;
- the terminal-bound `place_pos_order(jsonb,text)` path is the live POS placement contract.

## Initial trusted topology

The live project currently contains:

```text
BR-MAIN — Main Café
  SP-MAIN — Main Counter
    POS-MAIN-01
```

The seeded terminal remains `pending` until a manager explicitly activates/enrols it. Pending is intentional; seed data must not silently create a live workstation credential.

Live verification at closeout:

```text
branches                          1
active branches                   1
default branches                  1
sales points                      1
terminals                         1
active/enrolled seeded terminals  0
orders total                     25
orders without branch             0
customer orders with terminal     0
```

Historical orders are not retroactively fabricated with sales-point/terminal identity.

## Canonical migrations

Phase 1 and its branch prerequisite are represented canonically in `Hermann-33/Aida_System/supabase/migrations/`.

Relevant migration sequence:

```text
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

The last two closeout migrations fixed fresh-install permission gaps discovered by executable database regression:

- branch mutation `SECURITY INVOKER` wrappers now have authenticated-only execute access to their private implementations; those private functions still validate caller identity and Admin/Owner authority;
- `sales_points` and `terminals` now grant table-level SELECT to `authenticated`, while FORCE-RLS policies expose rows only to Admin/Owner; anonymous SELECT and direct DML remain denied.

No security boundary was relaxed to satisfy tests.

## Database executable evidence

GitHub Actions `Backend database audit` run **#22** passed on a clean local Supabase instance reconstructed from the canonical migration ledger.

All four writable-database regressions passed:

```text
branch_authority_integration.sql                 PASS
operational_topology_integration.sql            PASS
order_integration.sql                           PASS
scheduled_order_operations_integration.sql      PASS
```

The Phase 1 regression proves, among other cases:

- one-time enrolment codes cannot be reused;
- possessing an enrolment code is insufficient when staff lacks branch scope;
- removing staff branch scope immediately blocks terminal resolution;
- re-authorizing branch scope restores valid terminal resolution;
- POS orders persist trusted branch/sales-point/terminal attribution;
- same-terminal idempotent retry does not create a duplicate order;
- persisted topology attribution is immutable;
- customer placement remains terminal-free;
- revoked terminal credentials cannot resolve or place orders.

The older order/scheduling regressions were updated to discover terminals through the authorized Admin operational-topology RPC rather than by direct reads of protected terminal tables.

## Dashboard executable evidence

Dashboard code head before documentation-only closeout:

`50c559f4ed5a5f0ddd373a4bf450a38c7e9716ba`

Dashboard CI run **#23**:

```text
npm ci                 PASS
lint                   PASS
typecheck              PASS
Vitest files      31 / 31 PASS
Vitest tests     150 / 150 PASS
production build        PASS
```

Live Dashboard behavior now includes:

- employee session branch assignments loaded from Supabase with the caller JWT;
- ordinary staff with no trusted branch assignment fail closed;
- Admin branch, sales-point, terminal and employee-branch management through same-origin BFF endpoints;
- terminal enrolment/status/clear-credential paths through same-origin BFF endpoints;
- POS shell requires trusted terminal context for live placement;
- Admin Locations, Terminals and Employees consume trusted APIs in live mode while explicit UI Preview remains fixture-backed and non-authoritative.

No service-role credential or browser-readable employee bearer token was introduced.

## Customer executable evidence

Customer/backend code head before documentation-only closeout:

`d355cedb45995615a9946fb2844d55a1e6cde28d`

Customer release audit run **#114**:

```text
dependency resolution            PASS
Flutter static analysis          PASS
non-golden regression suite      PASS
golden regression suite          PASS
release APK build                PASS
release APK artifact upload      PASS
```

Phase 1 did not require a customer request-contract change. Customer ordering continues to resolve the current default branch server-side and never receives terminal authority.

## Supabase advisor review

Closeout advisor state:

- security: one pre-existing WARN only — leaked-password protection is disabled;
- performance: INFO-only unused-index observations on the current small dataset;
- no Phase 1-created security WARN/ERROR remains;
- no Phase 1 unindexed foreign-key blocker remains.

Leaked-password protection is hosted Auth configuration and remains separate from Phase 1 topology implementation.

## Apple App Review impact

```text
account/login:
  No customer login/account behavior changed.

payments:
  No processor, StoreKit, Apple Pay, card or e-wallet settlement added.
  Café purchases remain physical-goods / pay-at-counter semantics.

privacy/data collected:
  New trusted operational data identifies café branches, sales points,
  terminals, employee branch assignments and POS order workstation attribution.
  No new customer personal-data field was introduced by Phase 1.

permissions:
  No iOS protected-data permission added.

notifications:
  No notification behavior changed.

third-party SDKs:
  None added for Phase 1.

review/demo implications:
  None for the customer app beyond keeping the backend available.
  Terminal/Admin flows are operational Dashboard functionality, not an iOS
  customer permission or payment path.

App Store blocker introduced? no
```

The existing production account-deletion requirement remains a later mandatory phase before App Store release; Phase 1 neither creates nor resolves that independent blocker.

## Explicit non-goals / still deferred

Phase 1 does **not** make these domains authoritative:

- shifts, cash drawers, opening float, cash movement or variance;
- employee Auth-user provisioning, role mutation or badge/PIN credential lifecycle;
- branch opening hours, closures, schedule capacity or explicit customer branch selection;
- inventory, recipes, receiving, stock movement or depletion;
- loyalty/rewards/vouchers;
- promotions/discount authority;
- tax/accounting/reporting projections;
- real payment capture/refunds/processor settlement;
- printer/KDS/payment-device integrations;
- delivery;
- hosted production/release operations.

## Phase boundary

`TASK-OPS-002` and Phase 1 are `COMPLETE` by the project completion criteria.

The matching PRs are the Astra audit boundary:

```text
Customer/backend: Hermann-33/Aida_System PR #20
Dashboard/POS:    Hermann-33/Aida_System-Dashboard PR #17
```

Do not merge these PRs as part of this closeout. Do not start Phase 2 until Astra has reviewed the frozen Phase 1 boundary and findings are resolved or explicitly accepted.
