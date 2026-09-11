# Phase 2 — Shift and Cash Authority Plan

**Task:** `TASK-OPS-003`  
**Status:** `PARTIAL` — implementation in progress  
**Branch:** `codex/phase-2-shift-cash-authority`  
**Audit policy:** no Astra audit after Phase 2. Phases 1–3 will be audited together after Phase 3 is `COMPLETE`.

## Objective

Extend the trusted operational chain from terminal authority into shift and cash accountability:

```text
branch
 -> sales point
 -> terminal
 -> employee
 -> shift
 -> POS order / cash movement
```

The browser must not invent shift identity, opening float, expected cash, closing totals or manager approval.

## Dependency rationale

Phase 1 established trustworthy branch, sales-point, terminal and employee scope. Phase 2 depends on that authority because a shift is meaningful only when the backend can prove which physical terminal, branch and employee own it. Inventory, reporting and payments remain downstream because they depend on trusted shift/sale attribution.

## Bounded implementation plan

### 1. Shift authority

Create trusted server-owned shifts with:

- stable UUID;
- terminal, sales point and branch attribution derived from the terminal credential;
- opening employee;
- current operator;
- lifecycle status `open`, `locked`, `closed`;
- opening float in integer sen;
- opened/locked/resumed/closed timestamps;
- optimistic version for state transitions;
- close actor and optional approving manager.

Constraints:

- one `open`/`locked` shift per terminal;
- one `open`/`locked` shift per ordinary staff operator;
- Admin/Owner may inspect all permitted operational shifts but do not bypass terminal consistency for POS placement;
- locked or closed shifts cannot place sales.

### 2. Cash movement ledger

Create an append-only trusted ledger for non-sale drawer movements:

- `cash_in`;
- `cash_out`;
- reason text;
- amount in integer sen;
- shift/terminal/branch identity;
- actor and timestamp.

No browser-owned balance field will exist.

### 3. Expected cash and close reconciliation

Expected cash will be derived server-side from:

```text
opening float
+ trusted cash_in
- trusted cash_out
+ trusted cash-paid completed/valid POS order amounts
```

Phase 2 will add only the minimum internal tender classification required to distinguish pay-at-counter cash from non-cash/unpaid semantics. It will not integrate a payment processor.

Close flow:

- employee submits actual counted cash in integer sen;
- backend derives expected cash and variance;
- zero variance may close under normal operator authority;
- non-zero variance requires explicit Admin/Owner approval recorded server-side;
- closed financial facts are immutable.

### 4. POS order shift attribution

New live POS placement must require a valid open shift matching:

- terminal credential;
- terminal;
- sales point;
- branch;
- authenticated employee/operator.

Persist immutable `shift_id` on new POS orders. Customer orders remain shift-free.

### 5. BFF/API and Dashboard

Add same-origin caller-JWT BFF paths for:

- current shift;
- open shift;
- lock/resume;
- record cash movement;
- reconciliation preview;
- close shift;
- Admin shift history/inspection where required.

Live `PosShellPage` must stop using preview shift state and require the trusted current shift. UI Preview stays explicitly non-authoritative.

### 6. Validation

Phase 2 database regression must prove at minimum:

- no anonymous shift/cash authority;
- no direct authenticated table DML;
- staff cannot open/use a shift outside assigned branch;
- a terminal cannot own two live shifts;
- ordinary staff cannot own two live shifts;
- terminal/employee mismatch blocks POS placement;
- locked/closed shift blocks POS placement;
- cash ledger is append-only;
- expected cash is server-derived;
- non-zero variance cannot close without Admin/Owner approval;
- approved close persists immutable reconciliation facts;
- customer ordering remains shift-free;
- POS order shift attribution is immutable;
- idempotent order placement remains stable.

Dashboard CI and affected customer release audit must pass after integration.

## Security model

- customer app: no Phase 2 shift/cash access;
- Dashboard browser: no reusable employee bearer token and no terminal secret readable by JavaScript;
- BFF forwards the caller JWT and server-held terminal credential;
- service-role credentials remain prohibited from normal operational flows;
- exposed public tables use RLS + FORCE RLS where appropriate;
- private helper/ledger internals default-deny client roles;
- privileged functions must validate `auth.uid()`, role and operational scope internally.

## App Store impact

Phase 2 affects staff Dashboard/POS operations only. It introduces no customer iOS permission, tracking SDK, digital purchase, subscription or new customer personal-data collection. Physical café sales remain outside StoreKit/IAP. Phase 3 remains responsible for customer account deletion and privacy-release requirements.

## Non-goals

- external card/e-wallet/payment processor integration;
- cash refunds/returns;
- tax/accounting export;
- inventory/recipe depletion;
- printer/KDS/payment-device hardware integration;
- employee Auth-user creation or password/PIN/badge lifecycle;
- branch hours/closures/capacity;
- delivery.

## Completion gate

Phase 2 may be marked `COMPLETE` only after implementation, clean-database regressions, Dashboard/customer validation, advisor review, App Store impact review and synchronized documentation in both repositories. Then proceed directly to the documented Phase 3 plan; do not request Astra audit until Phase 3 is also `COMPLETE`.
