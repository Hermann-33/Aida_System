# AIDA Backend Completion Phases

**Status:** Active — Phases 1 and 2 `COMPLETE`; Phase 3 next  
**Started:** 2026-09-10  
**Updated:** 2026-09-12  
**Audit policy:** Astra audit is deferred until Phases 1, 2 and 3 are all `COMPLETE`; the three frozen phase boundaries will then be audited together before Phase 4 begins.

## Phase rule

A phase is `COMPLETE` only when:

1. all bounded task IDs inside the phase are implemented;
2. canonical Supabase migrations are recorded only in `Hermann-33/Aida_System/supabase/migrations/`;
3. database allow/deny regressions exist and pass in a writable test environment;
4. Dashboard/customer tests affected by the phase pass;
5. Supabase security/performance advisors are reviewed and task-created findings are fixed;
6. shared contracts/context are synchronized across both repositories;
7. phase scope, architecture/contracts/schema/security changes, implementation status, exact validation evidence, deferred/non-goals and handoff are documented in both repositories;
8. Apple App Review impact is explicitly reviewed.

Phases 1–3 proceed sequentially without intermediate Astra review. After Phase 3 is `COMPLETE`, implementation stops and one combined Phase 1–3 Astra audit boundary is prepared. Phase 4 must not begin before that audit boundary is resolved or explicitly accepted.

## Phase 1 — Operational topology

**Task:** `TASK-OPS-002`  
**Status:** `COMPLETE`  
**Evidence:** `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

Trusted chain:

```text
branch
 -> sales point
 -> terminal
 -> employee branch scope
 -> POS order attribution
```

Phase 1 established trusted branch assignment, sales-point/terminal authority, manager-issued terminal enrolment, HttpOnly terminal credentials, revocation, branch-scoped staff order access and immutable POS topology attribution. It remains frozen and unmerged.

## Phase 2 — Shift and cash authority

**Task:** `TASK-OPS-003`  
**Status:** `COMPLETE`  
**Plan:** `docs/context/PHASE_2_SHIFT_CASH_PLAN.md`  
**Evidence:** `docs/context/PHASE_2_SHIFT_CASH_CLOSEOUT_2026-09-12.md`

Trusted chain:

```text
branch
 -> sales point
 -> terminal
 -> employee
 -> shift
 -> POS order / cash ledger
```

Implemented boundary:

- trusted shift lifecycle: open, lock, resume and close;
- one live open/locked shift per terminal and per operator;
- integer-sen opening float;
- append-only `cash_in` / `cash_out` ledger;
- server-derived expected cash and closing variance;
- Admin/Owner authority required for non-zero variance close;
- immutable shift/tender/payment attribution on new POS orders;
- terminal + employee + shift consistency enforced server-side;
- live POS blocked without a valid open shift;
- same-origin caller-JWT shift BFF with HttpOnly terminal credential;
- live Dashboard shift/cash controls and explicit cash/unpaid tender semantics;
- customer ordering remains shift-free and unpaid;
- cash-paid cancellation remains blocked until trusted refund authority exists.

Final documentation-only Phase 2 heads and checks:

```text
Hermann-33/Aida_System
  b9e9eaa98c338a020dacc0d3374f710e1182b6d7
  Backend database audit #46   COMPLETE
  Customer release audit #138 COMPLETE

Hermann-33/Aida_System-Dashboard
  fe5aebdb22264e21646bfcf5ca49b1fd0d9bfe2d
  Dashboard CI #59             COMPLETE
```

Phase 2 PRs remain draft and unmerged:

```text
Aida_System PR #21
Aida_System-Dashboard PR #18
```

Phase 2 non-goals remain deferred: external card/e-wallet processor settlement, refunds/returns, tax/accounting export, inventory depletion, employee credential lifecycle, physical drawer/printer/KDS/payment-device integration, branch hours/capacity and delivery.

## Phase 3 — Customer privacy and App Store account requirements

**Status:** `PARTIAL` only after its bounded plan is committed; implementation must not begin before that plan exists in both repositories.

Required boundary:

- production account deletion replacing the dormant draft;
- explicit retention/deletion rules for personal data versus legally retained transaction records;
- accessible privacy policy, terms and support/contact surfaces;
- customer consent/preferences with explicit marketing-notification opt-in/out;
- explicit guest/public versus authenticated feature boundary;
- no unnecessary iOS protected-data permissions;
- regression evidence for authorization, deletion, retention and customer release behavior;
- synchronized App Store impact documentation.

This phase is mandatory before any App Store release candidate. After Phase 3 reaches `COMPLETE`, stop implementation and prepare the combined Phase 1–3 Astra audit boundary.

## Later phases

Phase 4: branch scheduling and pickup authority.  
Phase 5: inventory and recipes.  
Phase 6: loyalty, rewards and vouchers.  
Phase 7: promotions and discounts.  
Phase 8: reporting, accounting and audit.  
Phase 9: payments, refunds and external integrations.  
Phase 10: App Store release gate.

## Dependency rule

Do not skip forward when a later domain depends on an incomplete earlier authority boundary.

```text
branch
 -> sales point / terminal
 -> shift / cash
 -> customer privacy/account requirements
 -> combined Phase 1–3 Astra audit
 -> branch scheduling / inventory / loyalty / reporting
 -> payments / refunds / external integrations
```
