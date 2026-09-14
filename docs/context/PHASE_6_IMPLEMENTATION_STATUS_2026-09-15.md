# Phase 6 — Loyalty, Rewards and Vouchers — Implementation Status

**Date:** 2026-09-15  
**Verdict:** `PARTIAL`  
**Dependency:** Phase 5 `COMPLETE`  
**Next phase:** Phase 7 remains blocked until this document can be superseded by a `COMPLETE` closeout.

## Scope and dependency rationale

Phase 6 depends on Phase 5 because reward/voucher eligibility is evaluated against the trusted shared catalogue and accepted orders. It owns loyalty earning, balances, reward redemption, issued vouchers, voucher application, Admin/Owner loyalty configuration, customer loyalty consumption, and POS member/voucher attachment. Campaign promotions and generalized discounts remain Phase 7.

## Implemented backend authority

- Singleton server-owned loyalty program configuration.
- Append-only points and stamp ledgers plus server-maintained current balances.
- Idempotent loyalty earning on the first qualifying transition of an order to `completed`.
- Configured 1-stamp-per-order model and automatic stamp-milestone voucher issuance with rollover.
- Server-owned reward catalogue.
- Caller-bound atomic customer point redemption and voucher issuance.
- Server-owned voucher ownership/status/expiry/eligibility checks.
- Authoritative voucher quote/application/consumption integrated with accepted customer and POS orders.
- Immutable voucher commercial snapshot retained with the order while customer-owned loyalty state is removed by whole-account deletion.
- Admin/Owner reward management, support balance adjustment and loyalty-program configuration RPCs.
- Shift/terminal-bound POS member loyalty lookup. Staff cannot use it without an enrolled terminal and an open shift owned by the authenticated employee.

Canonical migrations currently extend through:

```text
20260914183500_create_loyalty_rewards_voucher_authority.sql
20260914183600_harden_loyalty_authority_foundation.sql
20260914183800_integrate_vouchers_with_order_authority.sql
20260914183900_make_voucher_consumption_trigger_internal.sql
20260914184000_preserve_loyalty_privacy_deletion.sql
20260914184100_expose_voucher_commercial_snapshot.sql
20260914184200_separate_voucher_quote_from_consumption_lock.sql
20260914184300_add_loyalty_admin_authority.sql
20260914184400_add_loyalty_program_configuration_authority.sql
20260914184500_add_pos_loyalty_lookup_authority.sql
```

## Dashboard security/contracts

Implemented Dashboard surfaces preserve the existing Phase 1–5 trust boundary:

- privileged browser traffic stays same-origin;
- employee access JWT and terminal credential remain HttpOnly-cookie state and are read only server-side;
- the BFF forwards the caller JWT plus the publishable Supabase key;
- no service-role credential is used for normal loyalty operations;
- Admin/Owner actor identity is bound to the caller session rather than accepted from browser JSON;
- POS member lookup sends the reusable terminal credential only BFF-to-Supabase and does not return it to browser JavaScript;
- live Admin program/reward management and audited member adjustment consume server-authoritative RPCs;
- UI Preview loyalty state is not used as a live backend fallback.

## Customer implementation

Implemented:

- live `SupabaseLoyaltyRepository` using `get_my_loyalty_wallet` and `redeem_my_reward`;
- points, stamp, reward and voucher providers resolve from the live loyalty repository rather than legacy preview values;
- authentication changes invalidate all customer loyalty providers;
- Rewards UI performs live atomic point redemption and refreshes points, rewards, vouchers and stamp state after success;
- checkout exposes caller-owned active issued vouchers, sends only `voucherId` intent, requotes through the authoritative order RPC, and revalidates/consumes the voucher on placement;
- checkout displays the resulting server-derived discount as `subtotal - total`; the client never computes an authoritative discount value.

## POS implementation

Implemented:

- server `get_pos_member_loyalty` is bound to `auth.uid()`, staff-or-above role, trusted terminal credential and an open shift;
- same-origin Dashboard BFF and typed client exist;
- BFF tests assert caller-JWT forwarding, terminal-secret containment and fail-closed behavior without terminal enrolment;
- live POS checkout performs shift-bound member lookup through that BFF, exposes only vouchers returned for the trusted member, and sends `memberCode`/`voucherId` as intent to the existing authoritative order BFF;
- changing/removing a member or voucher invalidates the prior trusted quote, so placement requires a fresh authoritative quote;
- preview-only `MemberPanel` remains isolated from the live checkout authority.

## Admin implementation

Implemented:

- points-per-RM configuration;
- stamp-goal and stamp-reward configuration;
- reward create/edit/enable/disable flow;
- member-code loyalty lookup;
- audited points/stamp support adjustments with required reason.

## Regression evidence in repository

Phase 6 adds/extends:

```text
supabase/tests/loyalty_rewards_vouchers_integration.sql
supabase/tests/loyalty_program_configuration_integration.sql
supabase/tests/pos_loyalty_lookup_contract.sql
server/loyaltyBff.test.ts
server/posLoyaltyBff.test.ts
```

The backend audit workflow runs the Phase 1–5 suites before all Phase 6 SQL regressions so clean-database reconstruction remains cumulative.

## Validation status

Current validation verdict is `PARTIAL`.

The current Phase 6 implementation surface is feature-complete against the documented Phase 6 scope, but the completion gates are not proven.

Latest observed GitHub Actions attempts still fail before a runner is allocated:

- customer release audit on backend head `e3d7c649f0570299bcaed95be659bfd609bad20d`: job contained `steps: []` and `runner_id: 0`;
- Dashboard CI on Dashboard head `1e998f69da71aa5b951a0737a2405638d080b53b`: job contained `steps: []` and `runner_id: 0`;
- backend database audit on the active Phase 6 branch is subject to the same Actions startup condition.

Those runs are infrastructure startup failures and do not count as either code-pass or code-fail evidence. A real executed backend database audit, customer release audit and Dashboard CI run are still mandatory before `COMPLETE`.

The connected Supabase account still does not expose the existing AIDA project `eswovqxqzfevcdwwcmuh`; the connector currently exposes only an unrelated project. Therefore canonical Phase 6 migrations cannot be deployed from this execution context and security/performance advisors cannot be rerun. No replacement project may be created.

## Deferred / non-goals

- Refund/clawback loyalty reversal remains deferred to the dedicated refund/commercial-authority phase.
- External payment processor work remains deferred.
- General promotion campaigns, promo codes, percentage/fixed campaign discounts, stacking rules and campaign targeting are Phase 7.
- No StoreKit/IAP work is introduced: loyalty applies to physical café goods/services.

## Handoff

Resume Phase 6, not Phase 7. Do not add more feature scope unless an executed validation failure demonstrates a real defect.

Priority order:

1. Once GitHub Actions allocates runners, execute backend database audit, customer release audit and Dashboard CI against the exact current Phase 6 heads; fix only real executed failures.
2. Restore connector access to existing AIDA Supabase project `eswovqxqzfevcdwwcmuh`, verify/apply canonical Phase 6 migrations in order, then run security and performance advisors.
3. If all validation is `COMPLETE`, synchronize the exact final heads/evidence into architecture/contracts/App Store/handoff docs and write the Phase 6 `COMPLETE` closeout.
4. Only then create Phase 7 branches.
