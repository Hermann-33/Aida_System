# AIDA Backend Completion Phases

**Status:** Active — Phase 2 in progress  
**Started:** 2026-09-10  
**Audit policy:** Astra audit is deferred until Phases 1, 2 and 3 are all complete; the three completed phase boundaries will then be audited together before Phase 4 begins.

## Phase rule

A phase is complete only when:

1. all bounded task IDs inside the phase are implemented;
2. canonical Supabase migrations are recorded in `Hermann-33/Aida_System/supabase/migrations/`;
3. database allow/deny regressions exist and pass in a writable test environment;
4. Dashboard/customer tests affected by the phase pass;
5. Supabase security/performance advisors are reviewed and task-created findings are fixed;
6. shared contracts/context are synchronized across both repositories;
7. the phase plan, implementation status, validation evidence, non-goals and handoff are documented in both repositories;
8. Apple App Review impact is explicitly reviewed.

Phases 1–3 may proceed sequentially without an intermediate Astra audit. After Phase 3 is `COMPLETE`, stop implementation and prepare one combined Phase 1–3 Astra audit boundary. Do not begin Phase 4 until Astra findings from that combined audit are resolved or explicitly accepted.

## Phase 1 — Operational topology

**Task:** `TASK-OPS-002`  
**Status:** `COMPLETE`  
**Evidence:** `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

Goal:

```text
branch
 -> sales point
 -> terminal
 -> employee branch scope
 -> POS order attribution
```

Implemented:

- trusted branches and employee branch assignments;
- trusted sales points under branches;
- trusted terminals under sales points;
- one-time manager-issued terminal enrolment;
- terminal credential stored only in an HttpOnly Dashboard/POS cookie;
- terminal status and immediate revocation;
- live terminal activation/status/clear-credential flow;
- immutable POS branch/sales-point/terminal attribution;
- branch-scoped staff order access;
- Admin Locations, Terminals and Employees live data paths backed by trusted APIs;
- customer ordering preserved without terminal authority;
- clean-database migration replay and all four SQL regression suites passing;
- Dashboard CI and customer release audit passing;
- Supabase advisor review completed with no Phase 1-created blocker;
- App Store impact reviewed with no new blocker.

Audit question result:

> Yes. Every new live POS sale requires a valid active enrolled terminal credential. The backend resolves the terminal's sales point and branch and validates the employee's operational branch scope; browser-supplied topology identifiers are not trusted placement authority.

Phase 1 non-goals remain deferred: shifts/cash, inventory, loyalty, branch hours/capacity, employee Auth-user provisioning, payment devices/processor settlement, printer/KDS health, reporting and external payments.

## Phase 2 — Shift and cash authority

**Task:** `TASK-OPS-003`  
**Status:** `PARTIAL` — implementation in progress.  
**Plan:** `docs/context/PHASE_2_SHIFT_CASH_PLAN.md`

Goal:

```text
branch
 -> sales point
 -> terminal
 -> employee
 -> shift
 -> POS order / cash ledger
```

Bounded scope:

- trusted shift lifecycle: open, lock, resume and close;
- one live open/locked shift per terminal;
- one live open/locked shift per ordinary staff operator;
- opening float in integer sen;
- append-only cash movement ledger for non-sale drawer movements;
- expected cash derived from trusted opening float + trusted cash movements + trusted cash-paid POS orders;
- actual cash count and closing variance;
- explicit manager/Admin approval when closing variance is non-zero;
- immutable shift attribution on newly placed POS orders;
- terminal credential + employee + shift consistency checked server-side;
- live POS blocked from sale placement when no valid open shift exists;
- current-shift and shift-history BFF/API paths;
- live POS shift UI replacing preview-only shift state where Phase 2 authority exists.

Phase 2 non-goals:

- payment processor/card settlement;
- cash refunds or return workflows;
- tax/accounting exports;
- inventory depletion;
- employee Auth-user provisioning, badge/PIN credential lifecycle or role mutation;
- multi-drawer hardware integration;
- branch hours/capacity;
- printer/KDS/payment-device health.

Phase 2 completion requires clean-database regressions, Dashboard CI, affected customer audit, Supabase advisor review, synchronized docs and an App Store impact review. Astra audit remains deferred until Phase 3 is also complete.

## Phase 3 — Customer privacy and App Store account requirements

**Status:** not started.  
**Plan:** must be documented in both repositories before Phase 3 implementation begins.

Goal:

- production account deletion, replacing the dormant draft;
- retention/deletion rules for personal versus legally retained transaction data;
- accessible privacy policy, terms/support contact surfaces;
- customer consent/preferences and notification marketing opt-in/out;
- explicit guest/public versus authenticated feature boundary;
- no unnecessary iOS protected-data permissions.

This phase is mandatory before any App Store release candidate. After Phase 3 is `COMPLETE`, stop and prepare the combined Phase 1–3 Astra audit.

## Phase 4 — Branch scheduling and pickup authority

Goal:

- branch opening hours;
- closures/holidays;
- schedule capacity;
- explicit customer pickup branch;
- explicit POS branch context where required;
- server validation of branch/time availability.

## Phase 5 — Inventory and recipes

Goal:

- inventory items/units;
- recipe/BOM definitions;
- stock movement ledger;
- receiving, adjustment and transfer;
- order depletion;
- branch/inventory-pool attribution;
- low-stock projections.

## Phase 6 — Loyalty, rewards and vouchers

Goal:

- append-only loyalty ledger;
- points/stamps earning;
- redemption;
- reward/voucher issuance and expiry;
- idempotent transaction linkage;
- member eligibility.

No mock balances may remain in trusted customer surfaces.

## Phase 7 — Promotions and discounts

Goal:

- promotion definitions;
- eligibility;
- stacking/exclusion rules;
- student/member rules;
- authoritative discount calculation and immutable order snapshots.

## Phase 8 — Reporting, accounting and audit

Goal:

- trusted sales and operational projections;
- branch/terminal/staff/shift breakdowns;
- tax-ready transaction records;
- export;
- append-only privileged audit events;
- reconciliation inputs.

## Phase 9 — Payments, refunds and external integrations

Goal:

- physical-goods payment processor integration;
- Apple Pay where selected;
- card/e-wallet settlement authority;
- refunds/partial refunds;
- processor idempotency/webhooks;
- accounting integrations;
- printer/KDS/payment-device integrations as required.

Digital In-App Purchase is not used for café food/drink purchases.

## Phase 10 — App Store release gate

Goal:

- iOS release build and current shipping iOS compatibility;
- privacy manifest / App Privacy answers verified against actual SDK behavior;
- account-deletion flow physically verified;
- all required purpose strings reviewed;
- no hidden/dormant production functionality;
- complete support/privacy URLs;
- App Review demo account or approved full-featured review path;
- backend live throughout review;
- review notes document non-obvious QR/member/order behavior;
- screenshots/metadata accurately reflect the submitted build;
- final on-device stability/accessibility review.

## Dependency rule

Do not skip forward when a later domain depends on an incomplete earlier authority boundary.

```text
branch
 -> sales point / terminal
 -> shift / cash
 -> inventory / sales attribution
 -> loyalty / promotions
 -> reporting
 -> payments / refunds
```
