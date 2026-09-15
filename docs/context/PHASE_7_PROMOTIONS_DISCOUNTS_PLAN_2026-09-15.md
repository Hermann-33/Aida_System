# Phase 7 Plan — Promotions and Discounts

**Task:** `TASK-OPS-007`  
**Status:** `PARTIAL` — plan established; implementation not yet started  
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

## Required backend authority

Phase 7 will define canonical migration-backed promotion configuration and application records, Admin/Owner mutation RPCs, quote integration, placement-time revalidation and immutable accepted snapshots. Direct ordinary client writes remain denied. Money remains integer sen.

The design must support deterministic precedence/stacking with Phase 6 vouchers. A quote is not durable promotion authority: placement recomputes/revalidates all applicable promotion state in the same trusted order transaction.

## Eligibility/scope baseline

The implementation may support branch, catalogue item/variant/add-on, member/customer segment and effective-window constraints only where the schema/contracts make the rule deterministic. It must not invent external marketing segmentation, legal/tax rules or payment-provider behavior.

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

Dashboard gains live Admin/Owner promotion configuration and operational visibility. POS consumes server-calculated promotion effects and invalidates stale quote authority when promotion-relevant intent changes. Preview fixtures remain isolated.

## Concurrency and idempotency

Placement must remain deterministic under concurrent promotion use, especially if a promotion introduces global/member usage limits. Usage counters/anchors must be transactionally serialized or atomically constrained. Retry of an already accepted idempotent order must not consume promotion usage twice.

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

Generalized discounts on physical cafe goods do not introduce StoreKit/IAP. Phase 7 must not add tracking/advertising SDKs or protected-device permissions without a separately documented approved requirement.
