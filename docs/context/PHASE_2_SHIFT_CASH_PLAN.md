# Phase 2 — Shift and Cash Authority Plan

**Task:** `TASK-OPS-003`  
**Status:** `COMPLETE`  
**Branch:** `codex/phase-2-shift-cash-authority`  
**Closeout:** `docs/context/PHASE_2_SHIFT_CASH_CLOSEOUT_2026-09-12.md`  
**Audit policy:** no Astra audit after Phase 2. Phases 1–3 will be audited together after Phase 3 is `COMPLETE`.

## Objective

Extend the trusted operational chain from terminal authority into shift and cash accountability:

```text
branch
 -> sales point
 -> terminal
 -> employee
 -> shift
 -> POS order / cash ledger
```

The browser must not invent shift identity, opening float, expected cash, closing totals or manager approval.

## Dependency rationale

Phase 1 established trustworthy branch, sales-point, terminal and employee scope. Phase 2 depends on that authority because a shift is meaningful only when the backend can prove which physical terminal, branch and employee own it. Inventory, reporting and payments remain downstream because they depend on trusted shift/sale attribution.

## Implemented bounded scope

### Shift authority

Trusted shifts persist UUID identity, terminal/sales-point/branch attribution, opening/current operator, `open | locked | closed` lifecycle, optimistic version, integer-sen opening float, timestamps and close/approval actors.

Constraints enforce one live shift per terminal and one live shift per operator. Locked/closed shifts cannot place sales.

### Cash ledger and reconciliation

The append-only ledger supports `cash_in` and `cash_out` with trusted actor, reason, timestamp and integer-sen amount.

Expected cash is derived server-side from opening float, trusted movements and trusted cash-paid POS sales. Employee submits actual cash only; backend derives variance. Non-zero variance close requires Admin/Owner authority.

### POS shift/payment attribution

New POS placement requires an open shift matching terminal credential, terminal, sales point, branch and authenticated operator. `shift_id`, tender and payment state are persisted as trusted immutable attribution. Customer orders remain shift-free and unpaid.

Phase 2 tender classification is deliberately limited to `cash | unpaid`. External processor settlement and refunds are deferred.

### BFF and Dashboard

Same-origin caller-JWT BFF paths cover current/open/lock/resume/close shift, cash movement, reconciliation and Admin shift history. The terminal credential remains HttpOnly/server-readable only.

Live POS requires trusted shift state. Expected cash is never browser authority. UI Preview remains explicitly non-authoritative.

## Validation

Detailed validation evidence is recorded in the closeout. Final documentation-only Phase 2 heads before governance refresh were green:

```text
Backend database audit #46   COMPLETE
Customer release audit #138 COMPLETE
Dashboard CI #59             COMPLETE
```

Database coverage includes no anonymous shift/cash authority, no direct authenticated mutation, branch/operator/terminal mismatch rejection, live-shift uniqueness, lock/close placement blocking, append-only cash movements, server-derived reconciliation, Admin/Owner variance approval, customer separation, immutable POS attribution and idempotency stability.

## Security model

- customer app has no Phase 2 shift/cash authority;
- Dashboard browser has no reusable employee bearer token and no readable terminal secret;
- BFF forwards the caller JWT and server-held terminal credential;
- service-role credentials remain prohibited from normal operational flows;
- exposed tables use explicit grants and RLS/FORCE RLS as appropriate;
- private helper internals default-deny client roles;
- privileged functions validate `auth.uid()`, role and operational scope internally.

## App Store impact

Phase 2 affects staff Dashboard/POS operations only. It introduces no customer iOS protected-data permission, tracking SDK, digital purchase, subscription or new customer personal-data collection. Physical café sales remain outside StoreKit/IAP. Phase 3 owns customer account deletion and privacy-release requirements.

## Deferred / non-goals

- external card/e-wallet/payment processor integration;
- cash refunds/returns;
- tax/accounting export;
- inventory/recipe depletion;
- printer/KDS/payment-device hardware integration;
- employee Auth-user creation or password/PIN/badge lifecycle;
- branch hours/closures/capacity;
- delivery and deployment-heavy work.

## Completion state

Phase 2 is `COMPLETE`, documented and frozen as an unmerged boundary. Its PRs remain draft/unmerged. Proceed to a dedicated Phase 3 plan and implementation; do not request Astra audit until Phase 3 is also `COMPLETE`.
