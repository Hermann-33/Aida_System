# Active Context

**As of:** 2026-09-15  
**Current boundary:** Phase 7 — promotions and discounts  
**Current verdict:** `PARTIAL` — implementation and repository validation are complete; live AIDA Supabase deployment/advisor verification remains blocked by project access in the current connection. Phase 8–10 remain frozen.

## Product topology

- customer/backend: `Hermann-33/Aida_System`
- Dashboard/Admin/POS: `Hermann-33/Aida_System-Dashboard`
- shared Supabase project ref: `eswovqxqzfevcdwwcmuh`
- canonical executable migrations: `Hermann-33/Aida_System/supabase/migrations/` only

## Completed authority through the current code boundary

```text
Phase 1 COMPLETE  branch -> sales point -> terminal -> employee branch scope -> POS attribution
Phase 2 COMPLETE  terminal + employee -> shift -> POS order / cash ledger
Phase 3 COMPLETE  customer identity -> privacy preferences / whole-account deletion -> anonymized retained history
Phase 4 COMPLETE  branch calendar/policy -> pickup slot capacity -> authoritative quote/place
Phase 5 COMPLETE  recipe -> branch inventory -> transactional depletion/reversal
Phase 6 COMPLETE  member -> loyalty ledgers/balances -> reward/voucher -> authoritative voucher discount/consumption
Phase 7 CODE COMPLETE  promotion config -> server evaluation -> quote/place -> immutable promotion snapshots
```

Phase 7 keeps commercial authority on the server. Clients do not submit accepted promotion IDs, promotion discounts or totals. Active promotions are selected from server configuration and may be scoped by branch, product, variant or add-on, with optional member requirements, windows, subtotal thresholds, global/member usage limits, stacking mode and voucher coexistence rules.

Accepted orders expose distinct `voucherDiscountSen` and `promotionDiscountSen` components that reconcile to `discountSen`. Promotion applications persist immutable commercial snapshots. Placement serializes candidate promotion configuration/usage so final-use contention has one accepted winner rather than oversubscription.

Dashboard privileged promotion management remains behind the same-origin HttpOnly employee session/BFF and caller-JWT forwarding. Flutter and POS consume authoritative quote/order promotion snapshots with fail-closed parsing. Preview mode does not make privileged promotion requests.

## Validated implementation heads

These are the implementation heads validated before the documentation synchronization commit:

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
```

```text
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Backend #231 includes the complete Phase 1–7 SQL regression suite, Phase 4–6 true-contention coverage and the Phase 7 final-promotion-use contention gate. Customer #311 includes static analysis, non-golden regressions, golden regressions, release APK build and artifact upload. Dashboard #147 includes lint, typecheck, unit tests, live POS browser regression, preview isolation and production build.

## Canonical Phase 7 migrations

```text
20260915100000_create_promotion_discount_authority.sql
20260915101000_integrate_promotions_with_order_authority.sql
20260915101100_normalize_phase7_nullable_voucher_quote.sql
```

## Live Supabase boundary

The AIDA project ref is documented as `eswovqxqzfevcdwwcmuh`. Earlier Phase 1–6 verification on 2026-09-15 recorded it `ACTIVE_HEALTHY` with scoped security/performance advisors complete.

The Supabase connection available during the current Phase 7 continuation does not list or expose that AIDA project; it exposes unrelated projects only. Therefore this session did **not** deploy Phase 7 migrations to any live project and did **not** run fresh Phase 7 security/performance advisors. It would be unsafe to deploy to an unrelated database.

## PR boundaries

```text
Aida_System             draft PR #27  codex/phase-7-promotions-discounts
Aida_System-Dashboard   draft PR #24  codex/phase-7-promotions-discounts
```

Both remain draft/unmerged. Completion of repository implementation does not authorize merge.

## Remaining Phase 7 closure gate

To change Phase 7 from `PARTIAL` to `COMPLETE`:

1. restore authorized access to Supabase project `eswovqxqzfevcdwwcmuh`;
2. deploy/reconcile the three canonical Phase 7 migrations on that project without rewriting valid historical migration records;
3. run live Phase 7 smoke verification plus fresh security and performance advisors;
4. confirm no new blocking findings and record the live evidence;
5. revalidate the final documentation heads.

Do not begin Phase 8–10 until this Phase 7 closure gate is complete and the owner explicitly authorizes the next phase.
