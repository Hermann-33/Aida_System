# Current Handoff

Updated: 2026-09-16

## Current boundary

Phases 1–7 are `COMPLETE` against their defined authority/validation/deployment boundaries. Phase 8 is `PARTIAL` and actively implementing read-only reporting/accounting/audit projections. Phase 9–10 remain frozen.

## Final Phase 7 evidence

```text
Aida_System             8f37d838fc4659a1e1d3a5dcae43887a796ca2be
Aida_System-Dashboard   c70fc8cd39f447eb68a0470e657d121db5c0f90f
Backend database audit #234   COMPLETE
Customer release audit #314   COMPLETE
Dashboard CI #149             COMPLETE
```

The final Dashboard gate includes lint, typecheck, unit tests, live POS browser regression, preview-isolation browser regression and production build.

## Phase 7 live Supabase state

Project `eswovqxqzfevcdwwcmuh` remains the shared AIDA backend.

Canonical Phase 7 repository migrations:

```text
20260915100000_create_promotion_discount_authority.sql
20260915101000_integrate_promotions_with_order_authority.sql
20260915101100_normalize_phase7_nullable_voucher_quote.sql
```

Live applied-history entries:

```text
20260915120917_create_promotion_discount_authority
20260915121057_integrate_promotions_with_order_authority
20260915121119_normalize_phase7_nullable_voucher_quote
```

Do not rewrite already-applied migration-service timestamps.

## Phase 8 branch baseline

```text
Aida_System             codex/phase-8-reporting-accounting-audit
  starts from 8f37d838fc4659a1e1d3a5dcae43887a796ca2be

Aida_System-Dashboard   codex/phase-8-reporting-accounting-audit
  starts from c70fc8cd39f447eb68a0470e657d121db5c0f90f
```

The detailed plan is `docs/context/PHASE_8_REPORTING_ACCOUNTING_AUDIT_PLAN_2026-09-16.md`.

## Phase 8 implementation order

1. Establish narrow caller-bound reporting/audit RPCs over trusted Phase 1–7 facts.
2. Add blocking SQL authorization/reconciliation/pagination regressions.
3. Preserve all existing Phase 1–7 database and contention gates.
4. Add Dashboard same-origin reporting BFF + strict client/parser contract.
5. Replace production fixture use in Executive Dashboard, Sales & Performance, Transactions and Audit pages.
6. Preserve preview fixture isolation and prove no privileged reporting calls in preview.
7. Deploy canonical Phase 8 migrations only after repository gates are green.
8. Run fresh live Supabase security/performance advisors and synchronize closeout docs.
9. Run Astra audit before Phase 9.

## Reporting semantics

Phase 8 is operational reporting/reconciliation, not invented statutory accounting.

Use persisted facts for accepted order totals, separate voucher/promotion discounts, topology, shifts/cash, loyalty applications and inventory movements. Do not manufacture VAT/SST, profit, COGS, processor settlement or refund facts that are not authoritatively stored.

Any missing audit/report fact must be represented as unavailable/incomplete rather than inferred from preview data.

## Security invariants

- reporting is read-only;
- Admin/Owner and branch scope are server-enforced;
- Dashboard keeps HttpOnly employee session + same-origin BFF + caller JWT forwarding;
- no service-role browser path;
- no browser-readable reusable employee/terminal credential;
- no widened direct table grants for convenience;
- preview never contacts privileged report RPCs;
- avoid unnecessary customer PII in reports.

## Apple boundary

Phase 8 does not introduce digital entitlements, StoreKit/IAP, tracking SDKs or protected-device permissions. It reports operational facts for physical café goods. Phase 9 owns payment/refund integrations; final App Store submission remains Phase 10.

## Merge governance

Phase 7 PRs remain draft/unmerged. Phase 8 work must also remain draft/unmerged until explicit owner authorization. Phase 8 completion does not itself authorize Phase 9 or merge.

## Immediate next action

Implement and test the first Phase 8 reporting/audit Supabase RPC contract before wiring Dashboard production pages.