# Phase 7 Promotions and Discounts Closeout — 2026-09-15

## Verdict

**`COMPLETE`**

Phase 7 is complete against its defined implementation, regression, affected-client, live AIDA deployment, advisor and documentation boundary. Phase 8–10 remain frozen pending explicit owner authorization.

## Scope delivered

Phase 7 adds generalized server-owned promotions/discounts while preserving Phase 6 voucher authority as a separate commercial component.

Delivered authority includes:

- promotion definitions with fixed or percent discount shape;
- active windows, minimum subtotal, optional maximum discount and priority;
- exclusive/stackable behavior;
- explicit voucher coexistence policy;
- optional member requirement;
- global and per-member usage limits;
- branch/product/variant/add-on scopes with strict catalogue validation;
- caller-bound Admin/Owner configuration RPCs;
- automatic server-side promotion selection during quote;
- placement-time locked re-evaluation and usage-limit serialization;
- immutable applied-promotion snapshots;
- distinct voucher/promotion discount components that reconcile to total order discount;
- strict Flutter and Dashboard Phase 7 quote/order parsing;
- live Dashboard campaign management via same-origin BFF/caller JWT;
- POS presentation of server-accepted promotions;
- preview isolation from privileged promotion authority.

## Canonical migrations

```text
20260915100000_create_promotion_discount_authority.sql
20260915101000_integrate_promotions_with_order_authority.sql
20260915101100_normalize_phase7_nullable_voucher_quote.sql
```

Canonical executable migration ownership remains `Hermann-33/Aida_System/supabase/migrations/` only.

## Live migration-history mapping

The canonical SQL was applied to AIDA project `eswovqxqzfevcdwwcmuh` through the Supabase migration service. The live history entries are:

```text
20260915120917_create_promotion_discount_authority
20260915121057_integrate_promotions_with_order_authority
20260915121119_normalize_phase7_nullable_voucher_quote
```

These deployment timestamps map in order to the three canonical repository files. They are valid live migration history and must not be rewritten merely to match canonical filename timestamps.

## Backend authority

The promotion foundation introduces `promotions`, branch/item/variant/add-on scope tables and `promotion_order_applications`. Promotion tables use RLS + FORCE RLS with direct client grants revoked.

Quote evaluation starts from the authoritative base quote and optional voucher adjustment, then resolves active eligible promotions from server configuration. Accepted promotion IDs/amounts are not client input.

Placement locks candidate promotion rows deterministically, recomputes the authoritative quote, creates the order and finalizes voucher/promotion applications. Usage-limit checks happen under the locked placement transaction. Persisted promotion application totals must reconcile exactly to `promotionDiscountSen` and to the order's total `discount_sen` together with the voucher component.

A Phase 7 regression proves final-use contention: two simultaneous orders competing for one remaining promotion use produce exactly one accepted promotion application.

## Customer Flutter

The customer order model fails closed on Phase 7 commercial fields. Quote/order parsing requires separate voucher and promotion discount components and validates promotion snapshots, total-discount arithmetic and line/subtotal consistency. Unknown/malformed authority is rejected rather than silently defaulted.

The customer release workflow also validates stacked phase PRs targeting the Phase 1–6 integration branch.

## Dashboard / POS / Admin

Dashboard includes:

- strict Phase 7 order quote/snapshot parsing;
- separate voucher/promotion commercial reconciliation;
- same-origin promotion BFF handlers forwarding the caller JWT with publishable-key architecture;
- live `/admin/rewards/campaigns` configuration UI;
- branch/product/variant/add-on targeting controls;
- activation/deactivation through authoritative `save_promotion` behavior;
- POS display of accepted promotion discounts/snapshots;
- preview fixtures that never contact privileged promotion endpoints;
- unit and browser regressions covering these boundaries.

No service-role secret or browser-readable employee bearer credential was introduced.

## Repository validation

Validated implementation heads:

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
```

Validation:

```text
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Backend #231 covers ordinary Phase 1–7 SQL regressions, Phase 4–6 true multi-session contention and the Phase 7 final-promotion-use contention gate.

Customer #311 covers Flutter static analysis, non-golden regression suite, golden regression suite, release APK build and release artifact upload.

Dashboard #147 covers lint, typecheck, unit tests, live POS browser regression, preview-isolation browser regression and production build.

## Live AIDA verification

After migration deployment:

- project `eswovqxqzfevcdwwcmuh` is `ACTIVE_HEALTHY`;
- all six Phase 7 promotion tables have RLS + FORCE RLS;
- no direct `anon` or `authenticated` CRUD privileges exist on those tables;
- expected promotion Admin, quote and placement functions/RPCs are present with intended execute grants;
- the old Phase 6 pending-voucher trigger is absent;
- promotion and promotion-application row counts were both zero immediately after verification, so no production test fixture data was introduced.

Fresh security advisor findings contain only the expected INFO `rls_enabled_no_policy` notices on RPC-only promotion/loyalty tables plus the pre-existing Auth WARN that leaked-password protection is disabled. That Auth setting is not a Phase 7 schema defect. Remediation reference: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

Fresh performance advisor findings are INFO `unused_index` notices only; no blocking missing-index or other performance warning was reported.

The SQL connector runs as `supabase_read_only_user` and cannot switch to application role `anon`; therefore it cannot directly execute an end-user `quote_order` smoke call. Intended app-role grants were separately verified, repository SQL/client/browser gates exercise runtime RPC behavior, and live verification intentionally avoided creating production promotion/order test data.

## App Store impact

Phase 7 adds discounts for physical café goods only. It adds no StoreKit/IAP, digital entitlement, subscription, tracking SDK or protected-device permission. Café food/drink payment remains outside In-App Purchase under Apple's physical-goods rule. Server-authoritative promotion calculation keeps accepted price/discount presentation consistent with backend commercial state.

Final App Store submission remains Phase 10.

## Governance

Backend PR #27 and Dashboard PR #24 remain draft/unmerged. Phase 8–10 are excluded from this closeout and must not begin until the owner explicitly authorizes continuation. Phase 7 completion does not itself authorize PR merge.
