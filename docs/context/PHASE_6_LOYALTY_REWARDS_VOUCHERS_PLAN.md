# Phase 6 Plan — Loyalty, Rewards and Vouchers

**Task:** `TASK-LOYALTY-001`  
**Verdict:** `PARTIAL`  
**Date:** 2026-09-15  
**Dependency:** Phase 5 inventory and recipes is `COMPLETE`.

## Goal

Replace preview/client loyalty state with server-authoritative member points, stamps, reward redemption and voucher lifecycle while preserving order/commercial authority.

Trusted chain:

```text
trusted member identity
 -> completed qualifying order
 -> append-only loyalty ledger
 -> server-derived points + stamp state
 -> reward catalogue
 -> atomic points redemption
 -> issued customer voucher
 -> trusted voucher application/consumption
```

## Product rules already established by the project

The Dashboard preview explicitly states that its labels mirror the master PRD. Phase 6 therefore starts with these server defaults:

- RM 1 of qualifying completed order value = 1 point;
- 1 stamp per qualifying completed purchase;
- 10 stamps = one free-drink voucher, then the stamp counter rolls over;
- RM 5 voucher = 100 points;
- RM 10 voucher = 180 points;
- free pastry voucher = 150 points.

These values move to server-owned configuration. Client preview fixtures stop being authority.

## Earning authority

Points/stamps are earned only when an order with a trusted `member_id` first transitions to `completed`.

- points earned = floor(authoritative completed order `total_sen` / 100) under the default 1 point/RM rule;
- stamp earned = 1 per completed qualifying order under the default rule;
- award is idempotent per order;
- cancellation before completion earns nothing;
- later repeated writes of `completed` cannot duplicate earning;
- historical earning uses the rule snapshot recorded on the ledger event.

Refund/clawback policy is intentionally deferred with external refund authority. Phase 6 does not invent processor/refund behavior.

## Planned schema

```text
public.loyalty_program_config
public.member_loyalty_accounts
public.loyalty_point_ledger
public.loyalty_stamp_ledger
public.reward_catalogue
public.member_vouchers
public.voucher_order_applications
```

Key properties:

- account rows are derived convenience state; append-only ledgers are audit history;
- points and stamps are integers, never floating point;
- reward catalogue records stable server-owned cost/type/value and expiry policy;
- vouchers snapshot reward title/type/value at issuance so later reward edits do not rewrite historical entitlements;
- voucher lifecycle is `active | used | expired | void` with immutable issued ownership;
- one voucher may be consumed at most once;
- order application stores the voucher/discount snapshot applied to that order.

## Reward and voucher types

Phase 6 supports project-established entitlement types:

- fixed amount off in integer sen;
- free item constrained to a server-owned catalogue target/category rule where configured.

General percentage/campaign promotion logic is Phase 7 and is not smuggled into Phase 6.

## Customer contract

Authenticated customer RPCs will provide:

- current points/stamps/program rule snapshot;
- active reward catalogue with eligibility;
- caller-owned voucher wallet;
- atomic points-to-voucher redemption.

Customer cannot submit an authoritative points balance, stamp balance, reward cost, voucher value/status, member ID or expiry.

## Voucher application/consumption

Voucher use must be server-authoritative and tied to the trusted order/member relationship.

For customer ordering, voucher ID is intent only. Quote validates caller ownership/eligibility and returns the authoritative voucher adjustment. Placement revalidates and atomically consumes the voucher with the order.

For POS, the attached trusted member and server-held terminal/shift authority are required. A browser-supplied voucher ID is only intent; the server validates ownership and consumption state.

Fixed-amount voucher discount cannot exceed the eligible order amount. Free-item entitlement is validated against server-owned accepted order-line catalogue snapshots. Final order `total_sen` and applied-voucher snapshot are server-derived.

## Stamp free-drink issuance

When completed qualifying purchases reach the configured stamp goal, Phase 6 automatically issues one free-drink voucher for each full goal and leaves only the remainder as active stamp progress. The voucher is server-owned and receives the configured expiry policy. No client-side unlock flag is authoritative.

## Dashboard scope

Replace the preview loyalty-program administration surface with live server-backed Admin/Owner controls and reporting for:

- program earning configuration;
- stamp goal and free-drink voucher expiry;
- reward catalogue CRUD/activation;
- member points/stamp/voucher lookup for support/audit;
- no direct balance editing except explicit audited adjustment RPC if implemented.

All privileged flows remain behind the same-origin HttpOnly BFF with caller-JWT forwarding. Preview member/reward fixtures remain preview-only.

## Security requirements

- no service-role secret in customer or Dashboard clients;
- no browser-readable employee bearer token/terminal credential;
- caller/member identity derived from trusted Auth/member state;
- public customer RPCs caller-bound to `auth.uid()` and accept no arbitrary member target;
- Admin/Owner configuration mutation checks trusted `user_profiles.app_role`/disabled state;
- RLS + FORCE RLS on exposed loyalty/voucher tables;
- ordinary direct ledger/account/voucher DML denied;
- exposed public RPCs remain invoker-side where practical; narrow private definer helpers use empty search paths and explicit grants/checks;
- points redemption and voucher consumption lock authoritative rows before mutation;
- duplicate order completion, duplicate redemption request and duplicate voucher use fail closed/idempotently;
- commercial order snapshots remain stable.

## Regression plan

Add `supabase/tests/loyalty_rewards_vouchers_integration.sql` covering at minimum:

- FORCE RLS/grants and direct-DML denial;
- default server program config;
- one-time earning on order completion;
- no earning before completion/cancelled-before-complete;
- RM-to-points calculation from authoritative total;
- stamp rollover and automatic free-drink voucher issuance at 10;
- reward catalogue values and Admin mutation authority;
- atomic points redemption and insufficient-points rejection;
- caller-owned voucher wallet isolation;
- voucher quote/application/consumption exactly once;
- fixed amount capped at eligible order value;
- free-item eligibility based on server-owned catalogue/order data;
- customer inability to redeem another member's points/voucher;
- no regression to Phase 1–5 topology/shift/scheduling/inventory/privacy invariants.

Backend clean-database CI must execute Phase 1–6 regressions. Affected customer and Dashboard tests/builds must be green. Supabase security/performance advisors must be rerun before `COMPLETE`.

## Documentation completion gate

Before Phase 6 can be `COMPLETE`, both repositories must synchronize:

1. this plan/scope/dependency rationale;
2. architecture/contracts/schema/security changes;
3. implementation status and exact validation evidence;
4. deferred/non-goals;
5. handoff/current context;
6. App Store impact.

## Deferred / non-goals

- generalized promotions/campaigns/percentage discount engine — Phase 7;
- referral reward business rules unless separately documented/approved;
- external payment capture/refund/clawback/settlement;
- accounting/tax/reporting expansion — Phase 8;
- push/marketing delivery provider;
- deployment-heavy integrations.

## App Store impact

Loyalty points, stamps and vouchers are benefits tied to physical café purchases, not digital goods. Phase 6 must not introduce StoreKit/IAP. Loyalty wallet data is customer-linked account data and therefore must be removed with the customer account under the existing Phase 3 deletion contract, while legitimate retained commercial order snapshots may keep non-identifying applied-discount facts.
