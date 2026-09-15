# Current Handoff

Updated: 2026-09-15

## Current boundary

Phases 1–7 are `COMPLETE` against their defined authority/validation/deployment boundaries. Phase 8–10 remain frozen and require explicit owner authorization before implementation begins.

## Phase 7 implementation evidence

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Backend #231 proves the full ordinary Phase 1–7 database suite, Phase 4–6 concurrency invariants and the Phase 7 final-promotion-use contention case. Customer #311 validates Flutter static analysis, non-golden tests, goldens, release APK build and artifact upload. Dashboard #147 validates lint, typecheck, unit tests, live POS E2E, preview-isolation E2E and production build.

## Phase 7 live Supabase evidence

Project `eswovqxqzfevcdwwcmuh` is `ACTIVE_HEALTHY`.

Canonical repository migrations:

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

Do not rewrite the applied live timestamps. They are the migration-service history mapping for the canonical repository files.

Post-deployment checks confirmed RLS + FORCE RLS on all Phase 7 tables, no direct anon/authenticated CRUD grants, expected RPC/function presence and grants, and retirement of the old pending-voucher trigger. No production promotion/test order data was created during verification.

Fresh advisors after deployment:

- security: expected INFO `rls_enabled_no_policy` notices for RPC-only promotion/loyalty tables; only WARN is the pre-existing leaked-password-protection Auth setting;
- performance: INFO unused-index observations only, with no blocking lint.

The read-only SQL connector cannot assume the application `anon` role, so direct application-RPC invocation was not used as a live smoke. Runtime behavior is covered by the blocking repository SQL/browser/client gates; live verification covered migration history, schema, grants and advisors.

## Phase 7 authority delivered

- server-owned fixed/percent promotions with optional cap, windows, subtotal threshold and priority;
- branch/product/variant/add-on targeting;
- member requirement plus global/per-member usage limits;
- exclusive/stackable and voucher-coexistence rules;
- automatic promotion evaluation in quote;
- deterministic placement locks + usage revalidation;
- immutable promotion application snapshots;
- separate voucher/promotion discount components;
- strict Flutter/Dashboard parsing;
- live Dashboard campaign management through caller-bound BFF paths;
- preview isolation.

## App Store boundary

Phase 7 remains aligned with Apple's physical-goods rule: café food/drink purchases stay outside IAP. Promotions add no StoreKit entitlement, tracking SDK or protected permission. Final App Store submission remains Phase 10.

## PRs

```text
Aida_System             draft PR #27
Aida_System-Dashboard   draft PR #24
```

Do not merge without explicit owner authorization.

## Next action

No Phase 8 work should start automatically. Await explicit owner authorization before reporting/accounting/audit implementation begins.
