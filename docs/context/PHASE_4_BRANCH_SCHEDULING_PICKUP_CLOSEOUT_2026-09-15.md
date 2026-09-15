# Phase 4 Closeout — Branch Scheduling and Pickup Authority

**Task:** `TASK-OPS-004`  
**Verdict:** `COMPLETE`  
**Date:** 2026-09-15

## Scope and dependency rationale

Phase 4 makes branch-local pickup availability server-authoritative before Phase 5 inventory work. The trusted chain is:

```text
active branch
 -> branch timezone
 -> weekly service windows / dated exceptions
 -> ASAP or scheduled policy
 -> lead time / scheduling horizon / slot interval
 -> persisted scheduled-order capacity
 -> authoritative quote and order placement
```

Customer branch selection is intent only and is validated by the server. POS branch identity remains terminal/open-shift derived and is never trusted from a browser branch ID. Inventory/recipe authority is intentionally deferred to Phase 5 so scheduling capacity and branch attribution exist first.

## Implemented backend authority

Canonical migrations under `Aida_System/supabase/migrations/` add:

- `branch_ordering_policies` — ASAP enablement, scheduled enablement, minimum lead, preparation lead, slot interval, maximum advance and optional per-slot order capacity;
- `branch_service_windows` — weekly branch-local service windows;
- `branch_service_exceptions` — dated closure/open-hours/capacity overrides;
- automatic safe scheduling defaults for new branches;
- public active-pickup-branch, pickup-state and authoritative available-slot reads;
- Admin/Owner branch policy/window/exception mutation RPCs;
- authoritative customer branch-intent validation;
- POS branch authority derived from trusted terminal/open-shift context;
- transaction-scoped advisory locking and capacity recheck for scheduled placement;
- server-derived `prepare_at` using the selected branch's preparation lead;
- persisted created-event normalization from the final order row.

Existing branches were initialized as all-day/unlimited capacity to preserve pre-Phase-4 behavior rather than invent operating hours or capacity.

## Canonical Phase 4 migrations

- `20260914153532_create_branch_scheduling_authority.sql`
- `20260914153751_implement_branch_pickup_policy_rpcs.sql`
- `20260914154002_enforce_branch_pickup_on_orders.sql`
- `20260914154100_preserve_ordering_policy_compatibility.sql`
- `20260914154200_harden_public_branch_pickup_rpcs.sql`
- `20260914154300_grant_phase4_private_rpc_schema_usage.sql`
- `20260914154400_preserve_quote_schedule_policy_timezone.sql`
- `20260914154500_grant_quote_pickup_helper_execute.sql`
- `20260914165306_optimize_branch_scheduling_read_policies.sql`
- `20260914165735_reconcile_phase4_rpc_contract.sql`
- `20260914170102_normalize_branch_scheduling_validation_error.sql`
- `20260914170625_restore_customer_payment_authority_guard.sql`

## Security and contract boundary

Phase 4 preserves the existing authority model:

- no service-role secret is introduced into Dashboard/customer clients;
- Dashboard Admin mutations use the same-origin BFF, HttpOnly employee session and caller JWT forwarding;
- reusable terminal credential remains HttpOnly and is only forwarded server-side;
- public pickup/quote RPC entrypoints are `SECURITY INVOKER` wrappers;
- privileged aggregate/table work is isolated behind narrowly granted `private` helpers;
- direct customer/Admin DML against scheduling authority remains denied;
- client-calculated opening hours, slot capacity or branch identity never become trusted placement authority;
- customer orders remain terminal/shift-free; POS orders retain trusted topology and shift attribution;
- quote/place compatibility and customer payment-authority guards remain intact after scheduling integration.

## Customer app implementation

Customer checkout now:

- loads active pickup branches from authoritative RPCs;
- defaults to the server-designated default branch;
- loads current branch pickup state using server time;
- loads scheduled slots from `list_branch_pickup_slots` rather than deriving live availability locally;
- submits branch and pickup time only as intent;
- binds quote and placement to the same selected branch;
- fails closed when authoritative availability cannot be obtained;
- retains existing idempotent customer placement request IDs.

The old local slot derivation helper remains only as a compatibility/test utility and is not live scheduling authority.

## Dashboard implementation

Dashboard Phase 4 adds:

- live branch scheduling/pickup Admin route;
- BFF endpoints for reading/saving branch pickup configuration and dated exceptions;
- caller-JWT forwarding with the publishable key only;
- same-origin enforcement for scheduling mutations;
- typed client parsing;
- live weekly-hours, lead/preparation, slot interval/horizon/capacity controls;
- dated closure/open-hours/capacity overrides;
- explicit POS fail-closed propagation of server scheduling rejection.

Preview fixtures remain non-authoritative.

## Validation evidence

Final implementation heads before documentation closeout:

```text
Aida_System             f5e204c0cb882a1b0b4ca25b32086c47f5eef796
Aida_System-Dashboard   de7e9da36db8a9d426e8d545d89229cc53ce733f
```

Validation results:

```text
Backend database audit #122   COMPLETE
Customer release audit #213   COMPLETE
Dashboard CI #84              COMPLETE
```

`supabase/tests/branch_scheduling_pickup_integration.sql` covers forced RLS/grants, branch initialization, Admin configuration, service windows, dated closures, quote validation, server-derived `prepare_at`, one-order slot capacity, full-slot rejection, cancellation freeing capacity and direct-DML denial. The backend workflow replays the full migration chain on a clean database and executes all Phase 1–4 regressions.

## Supabase advisor evidence

Live project: `eswovqxqzfevcdwwcmuh` (`Aida System`).

Security advisor: `COMPLETE` for the Phase 4 boundary. No Phase 4-created security lint remains. The single remaining warning is the pre-existing Auth setting `auth_leaked_password_protection` (Leaked Password Protection Disabled).

Performance advisor: `COMPLETE` for the Phase 4 boundary. Findings are INFO-level unused-index observations only, including new branch scheduling indexes that have not yet accumulated production usage. No missing-RLS, unsafe-function, missing-FK-index or Phase 4 performance blocker is reported.

## Deferred / non-goals

Deferred beyond Phase 4:

- inventory availability and recipes — Phase 5;
- loyalty, rewards and vouchers — Phase 6;
- promotions and discounts — Phase 7;
- reporting/accounting expansion — Phase 8;
- external payment/refund settlement — Phase 9;
- printer/KDS capacity, delivery, staffing forecasts and generalized resource scheduling.

## App Store impact

Phase 4 adds no tracking, advertising SDKs, new device permissions, StoreKit/IAP or new account/privacy categories. It changes pickup-location and scheduling behavior only. Phase 3 privacy/account-deletion authority remains unchanged.

## Handoff

Phase 4 is `COMPLETE`. Phase 5 may begin from the frozen Phase 4 heads after mirrored closeout/current-context documentation is synchronized. Phase 4 PRs remain draft/unmerged; completion alone is not merge authorization.
