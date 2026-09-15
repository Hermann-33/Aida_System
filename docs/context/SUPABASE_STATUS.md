# Supabase Status

**Status date:** 2026-09-15  
**Project:** Aida System  
**Ref:** `eswovqxqzfevcdwwcmuh`  
**Region:** `ap-southeast-1`  
**Current state:** `ACTIVE_HEALTHY`  
**Current verdict:** Phase 7 live deployment/advisor boundary `COMPLETE`.

Canonical executable migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Phase 7 live deployment

Canonical repository migrations:

```text
20260915100000_create_promotion_discount_authority.sql
20260915101000_integrate_promotions_with_order_authority.sql
20260915101100_normalize_phase7_nullable_voucher_quote.sql
```

Migration-service live history:

```text
20260915120917_create_promotion_discount_authority
20260915121057_integrate_promotions_with_order_authority
20260915121119_normalize_phase7_nullable_voucher_quote
```

The live versions are historical deployment identifiers generated when the canonical SQL was applied. Do not rewrite applied migration history to force timestamp equality with repository filenames.

## Live verification

Post-deployment verification confirmed:

- `promotions`, `promotion_branches`, `promotion_items`, `promotion_variants`, `promotion_addons`, `promotion_order_applications` exist;
- every Phase 7 table has RLS enabled and FORCE RLS enabled;
- `anon` has no direct SELECT/INSERT privilege on Phase 7 tables;
- `authenticated` has no direct SELECT/INSERT/UPDATE/DELETE privilege on Phase 7 tables;
- `get_promotion_admin_state`, `save_promotion`, `quote_order`, customer placement and POS placement functions are present;
- expected authenticated/anon execute grants are present on public RPC boundaries;
- the old `orders_consume_pending_voucher` trigger is retired;
- zero promotion rows and zero promotion application rows existed immediately after deployment verification, so no production fixture data was introduced.

The SQL inspection connector runs as `supabase_read_only_user` and cannot switch to `anon`, so it cannot directly execute the public app RPC despite the app-role grants being present. Runtime RPC behavior remains covered by the blocking local database and client/browser regressions; live verification intentionally avoided creating production test orders/promotions.

## Fresh advisors after Phase 7 DDL

### Security

- INFO `rls_enabled_no_policy` appears on the six Phase 7 RPC-only promotion tables and the existing RPC-only loyalty tables. This is intentional because direct table grants are revoked and access is through controlled RPCs.
- The only WARN is the existing `auth_leaked_password_protection` setting being disabled. This pre-dates Phase 7 and is a Supabase Auth configuration item, not a Phase 7 schema defect.
- Remediation reference: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

### Performance

- Advisor output contains INFO `unused_index` findings only, including newly created Phase 7 indexes before production usage accumulates.
- No blocking missing-index or other performance warning was reported.

## Repository validation paired with live state

```text
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Phases 1–7 are now `COMPLETE` against the defined boundary. Phase 8–10 remain frozen pending explicit owner authorization.
