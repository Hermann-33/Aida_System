# Phase 7 Promotions and Discounts Closeout — 2026-09-15

## Verdict

**`PARTIAL`**

The Phase 7 repository implementation is complete and all blocking repository CI gates are green. Formal Phase 7 closure is withheld because the current Supabase connection does not expose the documented AIDA project `eswovqxqzfevcdwwcmuh`, so the live migration/reconciliation, live smoke test and fresh advisor gates cannot be completed safely in this session.

Phase 8–10 remain frozen.

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

## Backend authority

The promotion foundation introduces `promotions`, branch/item/variant/add-on scope tables and `promotion_order_applications`. Promotion tables use RLS + FORCE RLS with direct client grants revoked.

Quote evaluation starts from the authoritative base quote and optional voucher adjustment, then resolves active eligible promotions from server configuration. Accepted promotion IDs/amounts are not client input.

Placement locks candidate promotion rows deterministically, recomputes the authoritative quote, creates the order and finalizes voucher/promotion applications. Usage-limit checks happen under the locked placement transaction. Persisted promotion application totals must reconcile exactly to `promotionDiscountSen` and to the order's total `discount_sen` together with the voucher component.

A Phase 7 regression proves final-use contention: two simultaneous orders competing for one remaining promotion use produce exactly one accepted promotion application.

## Customer Flutter

The customer order model was extended to fail closed on Phase 7 commercial fields. Quote/order parsing now requires separate voucher and promotion discount components and validates promotion snapshots, total discount arithmetic and line/subtotal consistency. Unknown/malformed authority remains rejected rather than silently defaulted.

The customer release workflow was also corrected so stacked phase PRs targeting the Phase 1–6 remediation branch receive the full release audit instead of skipping it.

## Dashboard / POS / Admin

Dashboard now includes:

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

## Validated implementation heads

These implementation heads were fully green before documentation synchronization:

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

## App Store impact

Phase 7 adds discounts for physical café goods only. It adds no StoreKit/IAP, digital entitlement, subscription, tracking SDK or protected-device permission. Under Apple's physical-goods rule, café food/drink payment remains outside In-App Purchase. Server-authoritative promotion calculation also ensures price/discount presentation reflects accepted backend commercial state.

Final App Store submission remains Phase 10.

## Live Supabase blocker

The project ref for AIDA is `eswovqxqzfevcdwwcmuh`. Earlier Phase 1–6 closeout checks on 2026-09-15 recorded that project `ACTIVE_HEALTHY` and completed scoped security/performance advisors.

During this Phase 7 continuation, the available Supabase account/project listing does not expose AIDA; it exposes unrelated projects only. Therefore this continuation intentionally did not:

- deploy Phase 7 migrations to a different project;
- claim Phase 7 migrations are live;
- run security/performance advisors against an unrelated database;
- mark Phase 7 `COMPLETE` without live evidence.

This is the sole remaining formal closure blocker currently known.

## Closure conditions

Phase 7 may move from `PARTIAL` to `COMPLETE` only after:

1. authorized access to `eswovqxqzfevcdwwcmuh` is restored;
2. the three canonical Phase 7 migrations are deployed/reconciled on that project;
3. live quote/place/promotion admin behavior is smoke-tested;
4. fresh Supabase security and performance advisors are run;
5. any new blocking findings are remediated;
6. final documentation heads are revalidated in CI and the live evidence is appended without reopening implementation defects.

## Governance

Backend PR #27 and Dashboard PR #24 remain draft/unmerged. Phase 8–10 are excluded from this closeout and must not begin until Phase 7 is formally `COMPLETE` and the owner explicitly authorizes continuation.
