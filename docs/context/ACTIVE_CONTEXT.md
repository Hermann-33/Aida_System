# Active Context

**As of:** 2026-09-16  
**Current boundary:** Phase 8 — reporting, accounting and audit  
**Current verdict:** `PARTIAL` — implementation substantially complete; live deployment/advisors and independent audit still pending. Phase 7 is `COMPLETE`; Phase 9–10 remain frozen.

## Product topology

- customer/backend: `Hermann-33/Aida_System`
- Dashboard/Admin/POS: `Hermann-33/Aida_System-Dashboard`
- shared Supabase project: `Aida System`, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`
- canonical executable migrations: `Hermann-33/Aida_System/supabase/migrations/` only

## Completed authority through Phase 7

```text
Phase 1 COMPLETE  operational topology
Phase 2 COMPLETE  shifts and cash authority
Phase 3 COMPLETE  customer privacy/account deletion
Phase 4 COMPLETE  branch scheduling/pickup capacity
Phase 5 COMPLETE  inventory and recipes
Phase 6 COMPLETE  loyalty/rewards/vouchers
Phase 7 COMPLETE  promotions and discounts
Phase 8 PARTIAL   read-only operational reporting/reconciliation/audit projections
```

## Phase 7 closure baseline

```text
Aida_System             8f37d838fc4659a1e1d3a5dcae43887a796ca2be
Aida_System-Dashboard   c70fc8cd39f447eb68a0470e657d121db5c0f90f
Backend database audit #234   COMPLETE
Customer release audit #314   COMPLETE
Dashboard CI #149             COMPLETE
```

## Phase 8 backend state

Canonical migration:

```text
supabase/migrations/20260916100000_create_reporting_audit_authority.sql
```

It exposes narrow caller-bound Admin/Owner read RPCs for:

- operational summary/reconciliation;
- paginated transaction detail;
- source-backed audit events.

Trusted reporting includes accepted order value, separate voucher/promotion discounts, paid POS cash, shift/cash reconciliation, product/branch/sales-point attribution, loyalty/application counts and inventory movements.

It deliberately does **not** invent statutory accounting, tax, COGS/profit, processor settlement or refund facts.

Backend database audit #239 passed the complete Phase 1–8 regression chain. A later documentation head also passed backend audit #243.

## Phase 8 Dashboard state

The production reporting boundary is now wired through the same-origin HttpOnly employee BFF and caller JWT for:

- `AdminOverviewPage`;
- `AdminSalesPerformancePage`;
- `AdminTransactionsPage`;
- `AdminAuditPage`.

Live pages consume strict parsed reporting RPC output. Preview mode remains fixture-only and a dedicated Playwright regression asserts that all four preview reporting surfaces make zero privileged `/api/v1/admin/reporting/*` requests.

Production labels use **accepted order value**, not captured/settled sales. Refund/processor state is explicitly unavailable until Phase 9.

## Current validation boundary

Dashboard CI #156 previously failed at Typecheck because the reporting test fetch mock was inferred as zero-argument. That defect is fixed. The reporting client has since been made strict, all four production pages were converted, parser tests hardened and the reporting preview-isolation test added to the blocking preview E2E command.

The current Dashboard implementation batch now requires a fresh exact-head CI pass before acceptance.

## Remaining Phase 8 closure

1. Exact-head Dashboard lint/typecheck/unit/live-POS/preview-isolation/build green.
2. Final backend/customer exact-head gates green after synchronized docs.
3. Deploy canonical Phase 8 migration to live AIDA Supabase.
4. Verify live RPC/grant state and migration history.
5. Run fresh Supabase security and performance advisors.
6. Synchronize Phase 8 closeout evidence across both repositories.
7. Complete or explicitly accept the required independent/Astra audit boundary before Phase 9.

## Branch / merge governance

```text
Aida_System             codex/phase-8-reporting-accounting-audit
Aida_System-Dashboard   codex/phase-8-reporting-accounting-audit
```

Phase 8 PRs remain draft/unmerged. Completion does not authorize merge. Phase 9 must not begin while Phase 8 remains `PARTIAL`.

## Next action

Run and repair the fresh Dashboard exact-head validation for the complete Phase 8 reporting UI batch. If green, proceed to live Phase 8 migration/advisor verification and synchronized closeout/audit evidence.
