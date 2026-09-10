# Current Handoff

Updated: 2026-09-11

## Current task

`TASK-OPS-002 — Phase 1 operational topology`

**Verdict:** `COMPLETE`  
**State:** frozen for Astra audit. Do not merge the Phase 1 PRs and do not begin Phase 2 until Astra findings are resolved or explicitly accepted.

Detailed evidence:

`docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

Matching Phase 1 branches:

```text
Hermann-33/Aida_System
  codex/phase-1-operational-topology

Hermann-33/Aida_System-Dashboard
  codex/phase-1-operational-topology
```

Matching audit PRs:

```text
Customer/backend PR #20
Dashboard/POS PR #17
```

## Trusted state handed off

AIDA now has authoritative operational topology through POS placement:

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

The seeded terminal remains `pending` until explicitly enrolled/activated by a manager.

Backend authority now covers:

- trusted branches and employee branch assignments;
- trusted sales points and terminals;
- one-time manager-issued terminal enrolment codes;
- HttpOnly terminal credential storage through the Dashboard BFF;
- terminal status and immediate revocation;
- staff branch-scope enforcement during terminal resolution and order operations;
- terminal-bound live POS placement;
- immutable `branch_id`, `sales_point_id` and `terminal_id` attribution on POS orders;
- customer orders remaining terminal-free.

Admin/Owner remain global operational roles for this tranche. Ordinary staff may operate only assigned branches.

## Validation evidence

Customer/backend code head before documentation-only closeout:

`d355cedb45995615a9946fb2844d55a1e6cde28d`

Backend database audit run #22 — PASS on clean local Supabase replay:

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
release APK artifact upload    PASS
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

## Canonical live migrations

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

The final permission fixes preserve the intended boundary: authenticated table SELECT on operational topology is still constrained by FORCE-RLS Admin/Owner policies; anonymous reads and direct DML remain denied.

## Live closeout verification

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

Supabase security advisor: one pre-existing leaked-password-protection WARN only. Performance advisor findings are INFO-only unused-index observations. No Phase 1-created security blocker remains.

## Dashboard handoff

Live mode now uses trusted APIs for:

- branch/sales-point management;
- terminal listing/creation/enrolment-code issuance/revocation;
- employee branch assignment;
- terminal enrolment/status/credential clearing;
- terminal-bound POS placement.

Explicit UI Preview remains fixture-backed by design and must never become backend authority.

Employee Auth-user creation, role mutation, disable/reactivation workflow and badge/PIN credential lifecycle are not part of Phase 1.

## Customer handoff

No Phase 1 customer request-contract change was required. Customer placement continues to resolve the current default branch server-side and never carries terminal authority.

Explicit pickup-branch selection plus branch hours/closures/capacity remain Phase 4.

## App Store review impact

Phase 1 added no customer login change, no payment processor, no iOS permission, no notification change and no third-party customer SDK. It introduces operational branch/sales-point/terminal attribution only.

No new App Store blocker was introduced. The previously identified production account-deletion requirement remains a later mandatory pre-release phase.

## Next action

Astra audits PR #20 and PR #17 as one Phase 1 boundary. Resolve or explicitly accept every Astra finding before starting Phase 2.

After Astra acceptance, the next bounded implementation phase is **Phase 2 — shift and cash authority**.

Still deferred after Phase 1:

- shifts/cash reconciliation;
- employee lifecycle/credentials beyond current role/branch-read contract;
- branch opening hours/closures/capacity and explicit customer branch selection;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- tax/accounting/reporting;
- payment capture/refunds/external integrations;
- printer/KDS/payment-device integrations;
- delivery;
- hosted production/release operations.
