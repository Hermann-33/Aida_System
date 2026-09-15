# Current Handoff

Updated: 2026-09-15

## Current boundary

Phases 1–6 remain `COMPLETE`. Phase 7 promotions/discounts is `PARTIAL`: code, tests and both clients are validated, but the live AIDA Supabase migration/advisor gate is not yet executable from the currently connected Supabase account. Phase 8–10 remain frozen.

## Validated implementation heads

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
```

## Repository validation

```text
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Backend #231 proves the complete ordinary Phase 1–7 database suite, prior Phase 4–6 concurrency invariants and the Phase 7 final-promotion-use contention case. Customer #311 validates Flutter static analysis, non-golden tests, goldens, release APK build and artifact upload. Dashboard #147 validates lint, typecheck, unit tests, live POS E2E, preview-isolation E2E and production build.

## Phase 7 authority implemented

Canonical migrations:

```text
20260915100000_create_promotion_discount_authority.sql
20260915101000_integrate_promotions_with_order_authority.sql
20260915101100_normalize_phase7_nullable_voucher_quote.sql
```

Implemented behavior includes:

- server-owned promotion configuration with fixed/percent discounts, active windows, minimum subtotal, optional maximum discount, priority, exclusive/stackable policy, voucher coexistence, member requirements and usage limits;
- branch/product/variant/add-on targeting with strict catalogue-kind validation;
- caller-bound Admin/Owner promotion state and mutation RPCs;
- quote-time automatic promotion evaluation without client-supplied authoritative promotion IDs/amounts;
- placement-time candidate locking, usage-limit revalidation and immutable `promotion_order_applications` snapshots;
- distinct `voucherDiscountSen`, `promotionDiscountSen`, total `discountSen` and persisted promotion snapshots;
- strict Flutter and Dashboard parsing/reconciliation for voucher + promotion commercial authority;
- live Dashboard `/admin/rewards/campaigns` management via same-origin BFF/caller JWT;
- preview-mode isolation from privileged promotion endpoints.

## Live Supabase status

Project ref: `eswovqxqzfevcdwwcmuh`.

Earlier Phase 1–6 checks on 2026-09-15 recorded the project `ACTIVE_HEALTHY` and completed scoped advisors. The current Supabase connector account does not expose this project and lists unrelated projects only. Consequently:

- Phase 7 migrations have not been deployed by this continuation;
- no Phase 7 live smoke test has been run;
- no fresh Phase 7 security/performance advisor result exists.

Do not deploy to another Supabase project merely to satisfy the gate.

## App Store boundary

Phase 7 remains compatible with the physical-goods payment model. Café food/drink purchases are physical goods consumed outside the app, so AIDA must continue using non-IAP payment methods for those purchases. Promotions are server-priced commercial adjustments and add no StoreKit entitlement, tracking SDK or protected-device permission.

## PRs

```text
Aida_System             draft PR #27
Aida_System-Dashboard   draft PR #24
```

Do not merge while Phase 7 remains `PARTIAL` unless the owner explicitly changes the governance rule.

## Next action

Restore authorized access to AIDA Supabase, deploy/reconcile the three Phase 7 migrations, run live smoke checks and fresh advisors, resolve any blocking findings, then record final live evidence and revalidate the documentation heads. Only after that may Phase 7 be declared `COMPLETE` and Phase 8 be considered.
