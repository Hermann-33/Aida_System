# Phase 6 Closeout — Loyalty, Rewards and Vouchers

**Task:** `TASK-OPS-006`  
**Verdict:** `COMPLETE`  
**Date:** 2026-09-15  
**Dependency:** Phase 5 inventory/recipes is `COMPLETE`.

## Scope and authority

Phase 6 makes loyalty earning, balances, rewards, issued vouchers and voucher application server-authoritative on top of accepted Phase 5 orders.

```text
trusted member
 -> loyalty program config
 -> completed-order award anchor
 -> point/stamp ledgers + server balances
 -> reward catalogue
 -> atomic redemption / milestone issuance
 -> member voucher
 -> authoritative quote discount
 -> atomic order voucher consumption
 -> immutable commercial voucher snapshot
```

Customers submit only reward/voucher intent. POS submits member code/voucher intent under a trusted employee session, enrolled terminal and open shift. Clients never author authoritative points, stamp balance, voucher status, eligibility, discount, or resulting order total.

## Canonical migration set

Canonical executable Phase 6 migrations remain only in `Aida_System/supabase/migrations/`:

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
20260914235500_restore_privacy_anonymization_boundary.sql
20260914235600_harden_pos_order_authority_boundary.sql
20260915000500_reconcile_loyalty_account_deletion.sql
20260915002000_reconcile_partial_phase6_live_schema.sql
20260915002800_index_loyalty_foreign_keys.sql
```

The guarded reconciliation migration was required because the live AIDA project contained two obsolete partial loyalty migrations. Before replacement, live customer loyalty accounts, point/stamp ledgers and member vouchers were all zero rows; the reconciliation refuses destructive replacement if customer loyalty data exists.

## Security and privacy boundary

- Phase 6 trusted tables use RLS + FORCE RLS.
- `authenticated` has no direct INSERT/UPDATE/DELETE on loyalty accounts, ledgers, program config, vouchers, reward catalogue, order-award anchors or voucher applications.
- Customer wallet/redeem RPCs are caller-bound to `auth.uid()` and trusted membership.
- Admin/Owner configuration/support operations bind actor identity to the employee session and preserve adjustment reason/actor history.
- POS member lookup requires staff-or-above, the server-held terminal credential and the caller's open shift.
- Dashboard keeps employee access/refresh and terminal credential HttpOnly and forwards the caller JWT with the publishable key; no service role is used for normal flows.
- Whole-account deletion removes customer-owned loyalty state and detaches identifying loyalty references from retained commercial snapshots.
- Preview loyalty/member state remains non-authoritative.

## Customer implementation

The customer app uses the live loyalty repository for wallet, points, stamps, rewards and vouchers. Reward redemption is atomic and refreshes the complete wallet state. Checkout exposes only caller-owned active vouchers, submits `voucherId` as intent, re-quotes server-side and displays the resulting server-derived discount.

The release audit now treats full-screen goldens as blocking. Phase 6 supplied deterministic loyalty fixtures so the suite does not fall through to live Supabase during visual testing.

## Dashboard/POS implementation

Dashboard provides live Admin/Owner loyalty program/reward management, member-code support lookup and audited point/stamp adjustments. Live POS performs terminal/open-shift-bound member lookup, exposes only trusted active vouchers and invalidates an earlier quote whenever member/voucher intent changes.

Dashboard CI #126 includes a blocking live-POS browser authority regression in addition to lint, typecheck, unit tests and production build.

## Live Supabase validation

Project `eswovqxqzfevcdwwcmuh` is `ACTIVE_HEALTHY`. The full canonical Phase 6 chain is deployed.

Security advisor result: no Phase 6 WARN/ERROR. The only WARN is the pre-existing Auth setting `auth_leaked_password_protection` being disabled. RLS-enabled/no-policy notices are INFO and intentional for RPC-only tables whose direct client grants are revoked.

Performance advisor initially identified six Phase 6 foreign keys without covering indexes. `20260915002800_index_loyalty_foreign_keys.sql` added them; the rerun has no missing-FK finding. Remaining performance notices are INFO-level unused-index observations.

## Final validation

Implementation heads before this documentation closeout:

```text
Aida_System             9273ba8f6c2f3d42404d9f6a34005bdde3df69e0
Aida_System-Dashboard   9979df27ed663b779c3d5c79670de4f19367b01c
```

```text
Backend database audit #190   COMPLETE
Customer release audit #281   COMPLETE
Dashboard CI #126             COMPLETE
Supabase security advisor     COMPLETE for Phase 6
Supabase performance advisor  COMPLETE for Phase 6
Live migration deployment     COMPLETE
```

## Deferred / non-goals

- generalized promotions, promo codes, stacking/targeting — Phase 7;
- reporting/tax/accounting — Phase 8;
- payment capture/refunds/external settlement — later phase;
- employee Auth-user/credential lifecycle;
- printer/KDS/payment-device integration;
- supplier purchasing, lots/expiry, forecasting/procurement;
- deployment-heavy production infrastructure.

## App Store impact

Loyalty and vouchers apply only to physical café goods/services. Phase 6 adds no StoreKit/IAP path, tracking/advertising SDK, protected-device permission or external payment processor. Phase 3 account deletion now also removes customer-owned loyalty state while retaining only non-identifying legitimate commercial snapshots.

## Handoff

Phase 6 is `COMPLETE`. Phase 7 is the next dependency boundary but is **not started** by this closeout. Phase PRs remain draft/unmerged unless explicitly authorized.