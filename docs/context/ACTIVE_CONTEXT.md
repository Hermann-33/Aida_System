# Active Context

**As of:** 2026-09-15  
**Current boundary:** Phase 7 — promotions and discounts  
**Current verdict:** `COMPLETE` against the defined Phase 7 implementation, live-deployment, advisor and documentation boundary. Phase 8–10 remain frozen until explicit owner authorization.

## Product topology

- customer/backend: `Hermann-33/Aida_System`
- Dashboard/Admin/POS: `Hermann-33/Aida_System-Dashboard`
- shared Supabase project: `Aida System`, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`
- canonical executable migrations: `Hermann-33/Aida_System/supabase/migrations/` only

## Authority completed through Phase 7

```text
Phase 1 COMPLETE  branch -> sales point -> terminal -> employee branch scope -> POS attribution
Phase 2 COMPLETE  terminal + employee -> shift -> POS order / cash ledger
Phase 3 COMPLETE  customer -> privacy/account deletion -> anonymized retained history
Phase 4 COMPLETE  branch calendar/policy -> pickup capacity -> authoritative quote/place
Phase 5 COMPLETE  recipe -> branch inventory -> transactional depletion/reversal
Phase 6 COMPLETE  member -> loyalty -> reward/voucher -> authoritative voucher discount/consumption
Phase 7 COMPLETE  promotion config -> server evaluation -> locked placement -> immutable promotion snapshots
```

Phase 7 keeps commercial authority on the server. Clients do not submit accepted promotion IDs, promotion discounts or totals. Active promotions are resolved from trusted configuration with branch/product/variant/add-on scope, windows, subtotal thresholds, member rules, usage limits, stacking and voucher-coexistence policy.

Accepted orders expose distinct `voucherDiscountSen` and `promotionDiscountSen` components that reconcile to `discountSen`. Placement serializes candidate promotion configuration/usage, and accepted promotion applications persist immutable commercial snapshots.

Dashboard promotion management remains behind the same-origin HttpOnly employee session/BFF and caller-JWT forwarding. Flutter and POS parse promotion authority fail-closed. Preview mode makes no privileged promotion requests.

## Validated implementation heads

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

## Live Phase 7 deployment

Canonical repository migrations:

```text
20260915100000_create_promotion_discount_authority.sql
20260915101000_integrate_promotions_with_order_authority.sql
20260915101100_normalize_phase7_nullable_voucher_quote.sql
```

Live Supabase applied-history entries created by the migration service on 2026-09-15:

```text
20260915120917_create_promotion_discount_authority
20260915121057_integrate_promotions_with_order_authority
20260915121119_normalize_phase7_nullable_voucher_quote
```

These live timestamps map to the three canonical repository files above. Do not rewrite already-applied live migration history merely to match repository filename timestamps.

Live verification after deployment:

- project `eswovqxqzfevcdwwcmuh`: `ACTIVE_HEALTHY`;
- all six promotion tables: RLS enabled + FORCE RLS;
- no direct `anon` or `authenticated` CRUD grants on promotion tables;
- Admin promotion, quote and placement RPCs/functions present with intended execute grants;
- retired Phase 6 pending-voucher trigger absent;
- no production promotions or promotion applications were inserted during deployment verification;
- fresh security advisor: Phase 7 tables appear only as expected INFO `rls_enabled_no_policy`; sole WARN remains the pre-existing leaked-password-protection Auth setting;
- fresh performance advisor: INFO unused-index findings only; no blocking performance lint.

The database connector itself runs as `supabase_read_only_user` and cannot impersonate the app `anon` role, so a direct end-user RPC call was not made through that connector. Repository SQL/E2E gates validate the runtime RPC behavior; live verification validated deployment history, schema, grants and advisors without creating production order/test data.

## PR boundaries

```text
Aida_System             draft PR #27
Aida_System-Dashboard   draft PR #24
```

Both remain draft/unmerged. Phase completion does not authorize merge.

## Next phase rule

Phase 8–10 remain frozen. Do not begin Phase 8 or resume a later-phase scheduler unless the owner explicitly authorizes continuation.
