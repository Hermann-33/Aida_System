# Phase 7 Plan — Promotions and Discounts

**Task:** `TASK-OPS-007`  
**Status:** `PARTIAL` — authority foundation implemented; quote/place/Admin UI integration remains  
**Date:** 2026-09-15  
**Dependency:** Phases 1–6 `COMPLETE`.

## Objective

Add generalized server-authoritative promotions and discounts without weakening Phase 6 loyalty/voucher authority. Clients may present promotion information and submit eligible intent, but Supabase/server owns eligibility, stacking, precedence, discount calculation, quote/place revalidation and accepted commercial snapshots.

## Trusted chain

```text
active promotion
 -> effective branch-local window
 -> scope / eligibility
 -> catalogue/member/branch constraints
 -> stacking + precedence
 -> authoritative quote calculation
 -> placement-time revalidation
 -> immutable accepted promotion/discount snapshot
```

## Implemented foundation

Canonical migration `20260915055000_create_promotion_discount_authority.sql` now establishes the Phase 7 data/security foundation:

- `promotions` with fixed-sen or percentage-basis-point discount shape, minimum subtotal, optional cap, effective window, deterministic priority, stacking mode, voucher compatibility, member requirement and optional global/per-member usage limits;
- branch, catalogue-item, variant and add-on scope junctions bound to the canonical Phase 1 catalogue/branch tables;
- `promotion_order_applications` for immutable accepted promotion snapshots, with customer/member identity nullable so Phase 3 deletion can later detach identity without deleting commercial history;
- FK-supporting indexes for all scope/application reverse lookups;
- RLS + FORCE RLS on all Phase 7 authority tables;
- no direct `anon`/`authenticated` table privileges;
- caller-bound Admin/Owner guard and `get_promotion_admin_state()` SECURITY INVOKER wrapper.

This migration is committed canonically in `Aida_System` only. It has **not** been deployed to live Supabase yet because Phase 7 quote/place integration and transactional regressions are not complete. Live production remains at the Phase 6 boundary.

## Remaining backend authority

Subsequent Phase 7 migrations must add Admin/Owner mutation RPCs, deterministic eligibility/discount evaluation, voucher stacking/precedence, quote integration, placement-time revalidation, usage-limit serialization/idempotency and order snapshot exposure. Direct ordinary client writes remain denied. Money remains integer sen.

A quote is not durable promotion authority: placement must recompute/revalidate all applicable promotion state in the trusted order transaction.

## Eligibility/scope baseline

Supported deterministic scope is branch, catalogue item, variant, add-on, member requirement and effective window. External marketing segmentation, tax/legal rules and payment-provider behavior remain out of scope.

## Security boundary

- RLS/FORCE RLS and grants follow existing authority patterns.
- Admin/Owner mutations remain caller-bound.
- Dashboard privileged writes remain same-origin BFF -> caller employee JWT + publishable key.
- No service-role browser path.
- Customer/POS clients cannot author authoritative discount amounts or resulting totals.
- Accepted order promotion facts are immutable commercial history.

## Customer scope

Customer surfaces may display server-provided promotion effects and eligibility. Checkout must treat local display calculations as estimates and use the authoritative quote/place response.

## Dashboard/POS scope

Dashboard will gain live Admin/Owner promotion configuration and operational visibility. POS consumes server-calculated promotion effects and invalidates stale quote authority when promotion-relevant intent changes. Preview fixtures remain isolated.

## Concurrency and idempotency

Placement must remain deterministic under concurrent promotion use, especially for global/member usage limits. Usage must be transactionally serialized or atomically constrained. Retry of an already accepted idempotent order must not consume promotion usage twice.

## Validation gate

Before `COMPLETE`:

- canonical migration replay succeeds;
- transactional SQL regressions cover RLS/grants, eligibility, precedence/stacking, quote/place revalidation, immutable snapshots, concurrency/usage limits and idempotency;
- customer static analysis/tests/blocking goldens/release build pass where affected;
- Dashboard lint/typecheck/unit/live browser regression/build pass where affected;
- live Supabase deployment matches canonical migrations;
- security/performance advisors contain no Phase 7 actionable blocker;
- both repositories' affected docs are synchronized with exact validation heads/evidence.

## Deferred / non-goals

- reporting/accounting/audit expansion — Phase 8;
- external processor capture/refunds/settlement — Phase 9;
- App Store final release gate — Phase 10;
- external ad/marketing automation and third-party campaign providers;
- tax/accounting policy invention.

## App Store impact

Generalized discounts on physical cafe goods do not introduce StoreKit/IAP. Phase 7 adds no tracking/advertising SDK or protected-device permission.
