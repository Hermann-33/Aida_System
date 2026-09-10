# Active Context

**As of:** 2026-09-11  
**Current task:** `TASK-OPS-002 — Phase 1 operational topology`  
**Current verdict:** `COMPLETE`  
**Audit state:** frozen for Astra review. Do not begin Phase 2 until Astra findings are resolved or explicitly accepted.

Detailed Phase 1 closeout evidence:

- `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`
- Customer/backend PR #20
- Dashboard/POS PR #17

Previous accepted work remains documented in its dedicated closeouts, including menu customization, scheduled-order operations and the customer UI redesign. Those historical task documents remain evidence but are not the current operational authority.

## Current product reality

AIDA Café is one product across:

- Flutter customer app — `Hermann-33/Aida_System`;
- React Dashboard/Admin/POS — `Hermann-33/Aida_System-Dashboard`;
- shared Supabase project `eswovqxqzfevcdwwcmuh`.

Canonical executable Supabase migrations remain owned by `Hermann-33/Aida_System/supabase/migrations/`.

The currently trusted backend tranche includes:

- Supabase Auth/member provisioning;
- same-origin HttpOnly employee/Admin sessions with caller-JWT forwarding;
- trusted employee roles/disabled state;
- trusted employee branch assignments;
- shared catalogue, variants, drink options and compatible add-ons;
- authoritative quote/order pricing and immutable commercial snapshots;
- Now/scheduled pickup policy and immutable preparation timestamps;
- customer order history/detail/status plus owner-scoped Realtime invalidation;
- branch-scoped staff order access and versioned fulfilment transitions;
- trusted branches, sales points and terminals;
- one-time manager-issued terminal enrolment and revocation;
- terminal-bound live POS placement with immutable branch/sales-point/terminal attribution.

Frontends remain non-authoritative for identity, roles, branch scope, catalogue commercial truth, modifier validity, prices/totals, order state, payment settlement, loyalty, inventory, promotions, shifts/cash or reporting.

## Phase 1 trusted topology

The backend authority chain is now:

```text
branch
 -> sales point
 -> terminal
 -> employee branch scope
 -> POS order
```

Live seed topology:

```text
BR-MAIN — Main Café
  SP-MAIN — Main Counter
    POS-MAIN-01
```

The seeded terminal is intentionally `pending` until a manager enrols/activates the workstation. Seed data never creates a live terminal credential automatically.

Trusted resources include:

```text
branches
employee_branch_assignments
sales_points
terminals
private.terminal_enrolment_codes
private.terminal_credentials
orders.branch_id
orders.sales_point_id
orders.terminal_id
```

Operational invariants:

- every persisted order has immutable `branch_id`;
- ordinary staff can operate only assigned branches;
- Admin/Owner retain global operational scope for the current tranche;
- customer orders never receive sales-point/terminal authority;
- live POS placement requires a valid active terminal credential;
- terminal credentials resolve branch and sales point server-side;
- browser-supplied branch/sales-point/terminal IDs are not trusted placement authority;
- terminal revocation blocks further terminal resolution and POS placement;
- credentialless `place_pos_order(jsonb)` is not executable by `authenticated`;
- terminal-bound `place_pos_order(jsonb,text)` is the live POS contract.

## Dashboard / POS behavior

Live Dashboard behavior now includes:

- employee `assignedBranchIds` loaded from trusted backend state;
- staff without branch assignment fail closed;
- Admin Locations reads/mutates trusted branches and sales points;
- Admin Terminals reads/mutates trusted terminals, issues enrolment codes and revokes terminals;
- Admin Employees reads trusted employee roles/status and mutates branch assignments;
- terminal enrolment/status/credential clearing use same-origin BFF endpoints;
- live POS requires valid terminal context before placement;
- POS order placement sends selection/fulfilment intent plus the server-held terminal credential; operational topology is derived server-side.

Explicit UI Preview mode may continue to use fixtures for demonstrations, but preview identifiers are never backend authority.

## Customer behavior

Customer request contracts did not change in Phase 1.

Customer ordering continues to send catalogue selections, quantity/note, fulfilment intent and `clientRequestId`. The backend resolves the current default branch for compatibility. Customer orders remain free of terminal/sales-point attribution.

Explicit customer pickup-branch selection, branch hours, closures and capacity remain Phase 4 work.

## Phase 1 executable evidence

Customer/backend code head before documentation-only closeout:

`d355cedb45995615a9946fb2844d55a1e6cde28d`

Backend database audit run #22 — PASS on clean Supabase replay:

```text
branch authority regression              PASS
operational topology regression         PASS
order regression                         PASS
scheduled-order operations regression    PASS
```

Customer release audit run #114:

```text
dependency resolution          PASS
Flutter static analysis        PASS
non-golden regressions         PASS
golden regressions             PASS
release APK build              PASS
release APK upload             PASS
```

Dashboard code head before documentation-only closeout:

`50c559f4ed5a5f0ddd373a4bf450a38c7e9716ba`

Dashboard CI run #23:

```text
npm ci                 PASS
lint                   PASS
typecheck              PASS
Vitest files      31 / 31 PASS
Vitest tests     150 / 150 PASS
production build        PASS
```

## Supabase closeout state

Relevant current migrations:

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

Live verification at closeout:

```text
branches                      1
active/default branches       1
sales points                  1
terminals                     1
active seeded terminals       0
orders total                 25
orders without branch         0
customer orders with terminal 0
```

Supabase advisors:

- security: one pre-existing WARN only — leaked-password protection disabled;
- performance: INFO-only unused-index findings on the current small dataset;
- no Phase 1-created security blocker remains.

## App Store impact

Phase 1 introduced no customer login change, no payment integration, no iOS protected-data permission, no notification change and no third-party customer SDK. It adds operational branch/sales-point/terminal attribution to Dashboard/POS data only.

No new App Store blocker was introduced. The existing production account-deletion requirement remains a later mandatory phase before release.

## Deferred domains

Still not authoritative:

- shifts/cash reconciliation;
- employee Auth-user provisioning, role mutation and badge/PIN credential lifecycle;
- branch opening hours/closures/capacity and explicit customer branch selection;
- inventory/recipes/stock movement/depletion;
- loyalty/rewards/vouchers;
- promotions/discount authority;
- tax/accounting/reporting;
- payment capture/refunds/processor settlement;
- printer/KDS/payment-device integrations;
- delivery;
- hosted production/release operations.

## Next boundary

Phase 1 is `COMPLETE` but not merged. PR #20 and PR #17 are the frozen Astra audit boundary.

Phase 2 — shift and cash authority — must not begin until Astra findings for Phase 1 are resolved or explicitly accepted.
