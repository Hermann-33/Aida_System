# Phase 1 Plan — Operational Topology

**Task:** `TASK-OPS-002`
**Status:** `COMPLETE`
**Closeout:** `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

## Goal
Establish trusted branch -> sales point -> terminal -> employee -> POS attribution without trusting browser-supplied operational IDs.

## Scope
- sales points under branches;
- terminal lifecycle and one-time enrolment;
- HttpOnly terminal credential boundary;
- employee branch-scope checks;
- server-resolved POS branch/sales-point/terminal attribution;
- immutable operational snapshots;
- Admin topology management;
- customer orders remain terminal-free.

## Validation
Canonical migrations, clean database regressions, Dashboard tests/build, Supabase advisors, synchronized docs, and App Store review.

## Non-goals
Shifts/cash, branch hours/capacity, inventory, loyalty, promotions, payments/refunds, printer/KDS health, and employee Auth provisioning.

## Result
`COMPLETE`; see the closeout document for exact evidence.
