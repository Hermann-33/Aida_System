# Phase 8 Reporting, Accounting and Audit Plan — 2026-09-16

## Status

**`PARTIAL` — active implementation**

Phase 7 is `COMPLETE`. Phase 8 is authorized and active. Phases 9–10 remain frozen. Completion of this plan does not authorize PR merge or Phase 9.

## Objective

Replace production Dashboard reporting/audit fixtures with read-only, server-derived operational reporting over the trusted Phase 1–7 facts already owned by Supabase.

Phase 8 is an **operational reporting and reconciliation** phase. It is not a statutory-accounting implementation and must not invent accounting facts that AIDA does not yet authoritatively store.

## Authority rules

1. Reports are derived read models, never a second mutation path.
2. Admin/Owner caller identity and branch scope remain server-enforced.
3. Dashboard access continues through the same-origin HttpOnly employee-session BFF and caller JWT.
4. No service-role shortcut or browser-readable reusable employee/terminal credential is permitted.
5. Production reporting may only display values supported by trusted persisted facts.
6. Preview fixtures remain isolated and must not contact privileged reporting RPCs.
7. Customer PII must not be exposed merely because it exists in source tables.
8. Branch-local reporting periods must respect authoritative branch timezone semantics.

## In scope

### Sales and order reporting

- accepted order counts and status distribution;
- authoritative subtotal, total discount and accepted total;
- separate voucher and promotion discount components;
- branch and sales-point dimensions where persisted;
- product/line quantities and accepted line revenue from immutable order snapshots;
- staff/terminal attribution for POS orders where trusted topology exists;
- hourly/day grouping derived with explicit timezone semantics.

### Shift and cash reconciliation

- open/closed shift counts;
- opening float and append-only cash movement totals;
- expected cash, declared close cash and recorded variance where Phase 2 source facts support them;
- branch/sales-point/employee attribution already persisted by shift authority.

### Loyalty / reward reporting

- authoritative point/stamp ledger activity;
- completed-order award activity;
- reward redemption and issued voucher activity;
- voucher application discount from immutable application snapshots.

### Promotion reporting

- accepted promotion applications;
- promotion discount totals separate from voucher totals;
- promotion usage counts by accepted immutable application snapshots.

### Inventory reporting

- authoritative inventory movement quantities and movement kinds;
- depletion/reversal/adjustment attribution already present in the inventory ledger;
- no fabricated COGS or profit without a trusted cost basis.

### Transaction detail

- source-backed order/commercial/topology detail;
- no invented processor settlement status;
- no fabricated refund value before Phase 9 refund authority exists.

### Audit

Expose immutable or append-only trusted operational events already authored by Phase 1–7 ledgers/event streams. If a source action has no durable audit fact, Phase 8 must label that coverage gap rather than fabricate an event.

## Explicitly out of scope

The following remain outside Phase 8 unless a trusted source fact already exists:

- tax/VAT/SST computation or statutory tax reporting;
- formal general ledger, double-entry journals, chart of accounts or financial statements;
- profit, margin or COGS without authoritative historical cost basis;
- processor capture, chargeback, refund and settlement truth;
- bank reconciliation;
- external accounting integrations;
- payment-provider webhooks;
- App Store submission.

Processor/refund/settlement authority belongs to Phase 9. Final App Store submission belongs to Phase 10.

## Planned backend contract

Prefer narrow caller-bound reporting RPCs over new report tables. Initial contract should cover:

- reporting summary/dimensions;
- paginated transaction detail;
- paginated audit-event projection;
- optional branch/sales-point filters constrained by caller scope;
- bounded date ranges and page sizes.

Public RPC wrappers should follow the established security pattern: public caller surface with private guarded implementation, explicit role checks, deterministic validation and no widened direct-table authority.

## Required regression coverage

Backend tests must prove at minimum:

- Admin/Owner can read the permitted report boundary;
- ordinary customer cannot read privileged reports;
- caller branch scope cannot be widened by request input;
- report date/page validation fails closed;
- voucher + promotion discount components reconcile to total discount;
- accepted order totals reconcile to immutable line totals;
- cancelled/nonaccepted states follow explicitly documented report semantics;
- shift/cash aggregates reconcile to source ledger rows;
- inventory movement aggregates reconcile to source ledger rows;
- audit results are source-backed, ordered and paginated deterministically;
- report RPCs do not grant mutation authority.

## Dashboard replacement boundary

Production mode must remove authoritative dependence on preview fixtures from:

- `AdminOverviewPage`;
- `AdminSalesPerformancePage`;
- `AdminTransactionsPage`;
- `AdminAuditPage`.

Synthetic trend percentages, fake refund values/reasons and fixture transaction/payment claims must not appear as live production facts.

Preview mode may continue to use presentation fixtures, but browser regression must prove it does not call privileged reporting endpoints.

## Closure gate

Phase 8 is `COMPLETE` only after:

1. canonical migration/RPC contract committed;
2. SQL reporting/audit regressions green;
3. existing Phase 1–7 database/concurrency regressions remain green;
4. Dashboard BFF/client/parser/UI regressions green;
5. preview isolation remains green;
6. production Dashboard build green;
7. affected customer release gates remain green if the shared repo head changes;
8. canonical Phase 8 migrations deployed to live AIDA Supabase;
9. fresh live security and performance advisors reviewed;
10. mirrored documentation and closeout evidence synchronized;
11. Astra audit completed before Phase 9 starts.

## Phase 8 starting baseline

```text
Aida_System             8f37d838fc4659a1e1d3a5dcae43887a796ca2be
Aida_System-Dashboard   c70fc8cd39f447eb68a0470e657d121db5c0f90f
Backend database audit #234   COMPLETE
Customer release audit #314   COMPLETE
Dashboard CI #149             COMPLETE
```

These are the validated Phase 7 closure heads from which Phase 8 branches start.