# Supabase Status

**Status date:** 2026-09-15  
**Project:** Aida System  
**Ref:** `eswovqxqzfevcdwwcmuh`  
**Region:** `ap-southeast-1`  
**Last verified project state:** `ACTIVE_HEALTHY`  
**Implementation verdict:** Phases 1–6 `PARTIAL` while the audit-remediation boundary is being revalidated.

Canonical executable migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Trusted authority through Phase 6

Supabase owns identity/role/membership, operational topology, terminal credentials, shift/cash, catalogue/orders, privacy/account deletion, branch scheduling/capacity, inventory/recipes/depletion, and loyalty/reward/voucher/discount authority.

## Phase 6 resources

```text
public.loyalty_program_config
public.member_loyalty_accounts
public.loyalty_order_awards
public.loyalty_point_ledger
public.loyalty_stamp_ledger
public.reward_catalogue
public.member_vouchers
public.voucher_order_applications
public.orders.discount_sen
```

Public RPCs include customer wallet/redeem, Admin/Owner loyalty state/reward/program/support operations and shift-bound POS member loyalty lookup. Voucher quote/application/consumption is integrated into authoritative quote/place flows.

## Live reconciliation and migration-history mapping

The live project contained two earlier partial loyalty draft migrations. Before reconciliation:

```text
member_loyalty_accounts  0
loyalty_point_ledger     0
loyalty_stamp_ledger     0
member_vouchers          0
```

Only seed configuration/rewards existed. The canonical repository migrations are:

```text
20260915083000_reconcile_partial_phase6_live_schema.sql
20260915083500_index_loyalty_foreign_keys.sql
```

The live project historically recorded the equivalent deployment steps under these already-applied timestamps:

```text
20260915002000_reconcile_partial_phase6_live_schema.sql
20260915002800_index_loyalty_foreign_keys.sql
```

That live migration history must not be rewritten. Documentation maps the historical applied timestamps to the canonical repository filenames instead. The guarded reconciliation fails closed if customer loyalty data or an unknown schema shape exists; it safely removed the unused draft so the canonical Phase 6 authority could be deployed. No replacement Supabase project was created.

## Security boundary

All eight Phase 6 authority tables are RLS + FORCE RLS and deny direct authenticated INSERT/UPDATE/DELETE. The generic private order writer is not executable by `authenticated`. Intended customer/POS/Admin RPCs retain their narrow execute grants; anonymous privileged loyalty/POS functions are denied.

At the original Phase 6 closeout, the security advisor reported no Phase 6 WARN/ERROR. The only WARN was the pre-existing `auth_leaked_password_protection` setting. INFO `rls_enabled_no_policy` notices are intentional because these tables are RPC-only and direct client table grants are revoked.

## Performance boundary

The original Phase 6 performance advisor identified six unindexed loyalty foreign keys. Canonical migration `20260915083500_index_loyalty_foreign_keys.sql` added covering indexes. The original rerun contained no missing-FK finding; remaining notices were INFO-level unused indexes on the then-small/new dataset.

## Validation state

Original Phase 6 closeout evidence remains historical evidence only:

```text
Backend database audit #190   COMPLETE
Customer release audit #281   COMPLETE
Dashboard CI #126             COMPLETE
Live Phase 6 deployment       COMPLETE
Security advisor              COMPLETE for Phase 6
Performance advisor           COMPLETE for Phase 6
```

The cumulative Phase 1–6 audit-remediation branch adds stricter Dashboard parsing/isolation, strict Flutter Phase 6 commercial parsing and true concurrent-session scheduling/inventory/points/voucher regressions. Exact-head backend/customer CI, final cross-repository documentation parity and a fresh live advisor check are required before restoring the combined Phase 1–6 verdict to `COMPLETE`.

The current connected Supabase project list does not expose AIDA ref `eswovqxqzfevcdwwcmuh`, so the fresh live advisor check cannot be independently rerun from the present connector session. This is a validation blocker only; it does not justify changing or recreating the live project.

## Deferred authority

Generalized promotions/discounts, reporting/accounting, external payment/refund settlement, employee credential lifecycle, hardware integrations, supplier/lot/procurement expansion and deployment-heavy production work remain later boundaries. Phase 7–10 implementation stays frozen until the Phase 1–6 remediation boundary is `COMPLETE`.
