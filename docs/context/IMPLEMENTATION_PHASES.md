# AIDA Backend Completion Phases

**Status:** Active — Phases 1 and 2 `COMPLETE`; Phase 3 `PARTIAL`  
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

Phase 2 PRs remain draft and unmerged:

```text
Aida_System PR #21
Aida_System-Dashboard PR #18
```

## Phase 3 — Customer privacy and App Store account requirements

**Task:** `TASK-PRIVACY-001`  
**Status:** `PARTIAL` — bounded plan committed in both repositories; implementation active.  
**Plan:** `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_PLAN.md`

Required boundary:

- production whole-account deletion replacing the dormant draft;
- explicit anonymization/retention rules for historical commercial records;
- deletion of customer profile/member/student-verification and preference PII;
- customer privacy/notification preferences with marketing default-off;
- accessible privacy policy, terms and support/contact surfaces;
- explicit guest/public versus authenticated feature boundary;
- iOS permission/data-minimization audit;
- database authorization/deletion/retention regressions;
- customer release validation and synchronized App Store impact documentation.

Design constraint: retained historical customer orders must lose stable customer/member/Auth identifiers without using a permanent synthetic Auth user. POS/staff audit identity must not be weakened by the customer-deletion path.

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

```text
branch
 -> sales point / terminal
 -> shift / cash
 -> customer privacy/account requirements
 -> combined Phase 1–3 Astra audit
 -> later backend phases
```

Do not begin Phase 4 while Phase 3 is `PARTIAL` or before the combined Astra boundary is resolved/accepted.
