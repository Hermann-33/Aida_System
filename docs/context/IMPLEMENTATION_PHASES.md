# AIDA Backend Completion Phases

**Status:** Active  
**Started:** 2026-09-10  
**Audit model:** each phase stops at a frozen audit boundary for Astra before the next phase begins.

## Phase rule

A phase is complete only when:

1. all bounded task IDs inside the phase are implemented;
2. canonical Supabase migrations are recorded in `Hermann-33/Aida_System/supabase/migrations/`;
3. database allow/deny regressions exist and pass in a writable test environment;
4. Dashboard/customer tests affected by the phase pass;
5. Supabase security/performance advisors are reviewed and task-created findings are fixed;
6. shared contracts/context are synchronized across both repositories;
7. Apple App Review impact is explicitly reviewed;
8. the phase branch is frozen for Astra audit.

Astra findings must be resolved or explicitly accepted before the next phase begins.

## Phase 1 — Operational topology

**Task:** `TASK-OPS-002`  
**Goal:** trusted branch -> sales point -> terminal -> employee -> POS order attribution.

Scope:

- trusted sales points under branches;
- trusted terminals under sales points;
- one-time manager-issued terminal enrolment;
- terminal credential stored only in an HttpOnly cookie on the Dashboard/POS browser;
- terminal status/revocation;
- live terminal activation flow;
- POS order snapshots persist sales-point/terminal attribution;
- current customer ordering remains unaffected;
- Admin location/terminal surfaces consume trusted APIs rather than session fixtures where implemented.

Non-goals:

- shifts/cash;
- inventory;
- loyalty;
- branch opening hours/capacity;
- payment devices/processor settlement;
- printer/KDS health;
- employee Auth-user provisioning.

Audit question:

> Can every new live POS sale be attributed to a valid active terminal and sales point that belongs to a branch the employee may operate, without trusting browser-supplied location identifiers?

## Phase 2 — Shift and cash authority

Goal:

- open/lock/resume/close shifts;
- one active operator/shift policy as defined by ADR;
- opening float in integer sen;
- cash movement ledger;
- expected/actual cash and variance;
- manager approval for material variance;
- orders/sales attributed to a shift when required.

No payment-processor settlement yet.

## Phase 3 — Customer privacy and App Store account requirements

Goal:

- production account deletion, replacing the dormant draft;
- retention/deletion rules for personal versus legally retained transaction data;
- accessible privacy policy, terms/support contact surfaces;
- customer consent/preferences and notification marketing opt-in/out;
- explicit guest/public versus authenticated feature boundary;
- no unnecessary iOS protected-data permissions.

This phase is mandatory before any App Store release candidate.

## Phase 4 — Branch scheduling and pickup authority

Goal:

- branch opening hours;
- closures/holidays;
- schedule capacity;
- explicit customer pickup branch;
- explicit POS branch context;
- server validation of branch/time availability.

## Phase 5 — Inventory and recipes

Goal:

- inventory items/units;
- recipe/BOM definitions;
- stock movement ledger;
- receiving, adjustment, transfer;
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

Do not skip forward when a later domain depends on an unaudited earlier authority boundary.

In particular:

```text
branch
 -> sales point / terminal
 -> shift
 -> inventory / sales attribution
 -> loyalty / promotions
 -> reporting
 -> payments / refunds
```
