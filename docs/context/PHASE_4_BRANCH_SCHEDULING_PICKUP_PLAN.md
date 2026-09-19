# Phase 4 Plan — Branch Scheduling and Pickup Authority

**Task:** `TASK-OPS-004`
**Status:** `PARTIAL` — plan approved; implementation active.

## Goal
Make branch-local hours, scheduled-pickup policy and pickup-slot capacity authoritative on the server. Clients may express pickup intent, but they cannot decide whether a branch is open or a slot is valid/available.

Audit question:

> Can every ASAP or scheduled pickup be accepted only when the trusted branch is active, open under its branch-local calendar, inside its scheduling horizon and within server-owned slot capacity, with POS branch authority still derived from the enrolled terminal?

## Dependencies
Phases 1–3 are `COMPLETE`. The independent Phase 1–3 Codex audit runs in parallel by explicit owner direction dated 2026-09-14. A blocking audit finding reopens the affected earlier phase; it does not permit weakening Phase 4 trust boundaries.

## Server model
- one `branch_ordering_policies` row per branch;
- weekly `branch_service_windows` in branch local time;
- dated `branch_service_exceptions` for closures or overrides;
- branch policy owns ASAP enabled, scheduled enabled, minimum lead, preparation lead, slot interval, maximum advance and per-slot order capacity;
- the branch timezone remains owned by `branches.timezone`;
- scheduled capacity is derived from persisted non-cancelled orders and rechecked transactionally at placement;
- customer payload may choose an active branch as intent; the server validates it;
- POS payload never supplies trusted branch authority: terminal resolution determines the branch.

## RPC boundary
Public/customer reads expose active branch pickup policy and available slots. Admin/Owner mutation RPCs manage policy/windows/exceptions. Existing global ordering-policy RPCs remain compatibility surfaces only where safe and must no longer be the scheduling authority.

## Order integration
- quote and placement use the same branch-aware validation helper;
- ASAP requires the branch to be open at server time;
- scheduled pickup must align to the configured slot interval, service window, lead time and horizon;
- placement rechecks capacity under a transaction-scoped slot lock;
- `prepare_at` uses the selected branch preparation lead;
- persisted orders retain immutable branch and pickup timestamps;
- cancellation may free future slot capacity; clients cannot reserve capacity without a persisted order.

## Dashboard/customer work
- Admin Locations gains live branch hours, schedule policy, capacity and exception management;
- customer ordering reads trusted branch availability/slots and sends only branch/pickup intent;
- POS checkout surfaces server scheduling failures without local fallback.

## Validation
Canonical migration replay, transactional branch-scheduling regression, existing order/schedule regressions, customer tests/release build, Dashboard lint/typecheck/tests/build, Supabase security/performance advisors and synchronized documentation.

## Non-goals
Inventory availability, recipe depletion, loyalty, vouchers, promotions/discounts, external payment/refund settlement, delivery, tax, printer/KDS capacity, staffing forecasts and arbitrary resource-duration scheduling.
