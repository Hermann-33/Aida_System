# AIDA Café Security Review

Updated: 2026-09-15

**Current verdict:** Phases 1–7 `COMPLETE` against the defined implementation/live-verification boundary. Phase 8–10 remain frozen pending explicit owner authorization.

## Core trust controls

- Supabase Auth is authentication identity; trusted role/disabled state comes from server-owned profile state.
- Customer-editable Auth metadata and preview fixtures are never authorization authority.
- Dashboard privileged traffic uses same-origin HttpOnly employee/terminal cookies and caller-JWT forwarding.
- No normal Flutter/browser/BFF flow uses a service-role secret or exposes a reusable employee bearer/terminal credential to browser JavaScript.
- Controlled RPCs plus RLS/FORCE RLS own protected operational/commercial/customer state.

## Operational controls

Employee branch scope, terminal enrolment/revocation, topology attribution, shift ownership/state and cash reconciliation are server-validated. New POS placement requires current terminal/caller authority and an open shift. Matching idempotent retries may resolve after lock/close without creating new authority.

Branch scheduling/capacity is server-owned; inventory consumption is transactional/non-negative with compensating cancellation reversals.

## Loyalty and voucher controls

Phase 6 authority tables use RLS + FORCE RLS and deny direct authenticated mutation. Customer wallet/redemption is caller-bound. Admin/Owner loyalty configuration/support rechecks trusted role and actor. POS member lookup requires staff-or-above, valid server-held terminal credential and open caller shift. Voucher ownership/status/expiry/eligibility and discount are validated server-side and consumption is placement-atomic.

## Phase 7 promotion controls

Promotion configuration and immutable application tables use RLS + FORCE RLS with direct `anon`/`authenticated` table access revoked. Admin/Owner promotion management is exposed only through caller-bound RPCs that recheck trusted role and session actor.

Clients do not submit authoritative promotion IDs, promotion discount amounts or order totals. `quote_order` resolves promotions from trusted configuration. Placement locks candidate promotion rows in deterministic order before re-evaluation so global/per-member usage counts cannot be oversubscribed by concurrent orders.

Promotion scope validation enforces product/add-on catalogue kind and trusted branch/catalogue foreign keys. Fixed discounts use integer sen; percentage discounts use bounded basis points. Window, subtotal, maximum discount, stacking mode, voucher coexistence and usage-limit constraints are server-validated.

Accepted promotion facts persist as immutable code/name/type/value/discount/priority/stacking/voucher-coexistence snapshots and reconcile to `orders.discount_sen`. Voucher and promotion discount components remain distinct.

The Phase 7 contention regression proves that two concurrent orders competing for the final permitted promotion use produce exactly one accepted promotion application.

## Privacy controls

Whole-account deletion accepts no target user ID. It deletes customer-owned loyalty accounts/ledgers/vouchers, detaches identifying loyalty/member references from retained commercial snapshots, scrubs retained order-line/event free text, replaces the original customer payload digest, anonymizes retained customer order identity, then removes Auth/member-owned state. Staff/POS audit identity and non-identifying commercial facts remain.

Promotion application history may retain legitimate non-identifying accepted commercial facts; nullable member/promotion references prevent configuration or identity deletion from rewriting historic price truth.

## Repository validation

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Customer #311 covers static analysis, non-golden regressions, goldens, release APK build and artifact upload. Dashboard #147 covers lint, typecheck, unit tests, live POS browser authority, preview isolation and production build. Backend #231 replays all migrations/regressions through Phase 7 and includes the final-promotion-use contention gate.

## Live Supabase verification

Project `eswovqxqzfevcdwwcmuh` is `ACTIVE_HEALTHY` after deployment of the canonical Phase 7 SQL. Live history records:

```text
20260915120917_create_promotion_discount_authority
20260915121057_integrate_promotions_with_order_authority
20260915121119_normalize_phase7_nullable_voucher_quote
```

Post-deployment checks confirmed all six Phase 7 tables have RLS + FORCE RLS, with no direct anon/authenticated CRUD privileges. Required public/private Phase 7 functions are present with intended execute grants, and the old `orders_consume_pending_voucher` trigger is retired. Verification inserted no production promotion or order fixture data.

Fresh security advisor findings:

- INFO `rls_enabled_no_policy` for RPC-only Phase 7 promotion tables and existing RPC-only loyalty tables. This is intentional because direct table privileges are revoked.
- The sole WARN remains `auth_leaked_password_protection`: Supabase Auth leaked-password protection is disabled. This predates Phase 7 and is not a Phase 7 schema regression.
- Remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

Fresh performance advisor findings are INFO `unused_index` observations only, including newly deployed Phase 7 indexes before production usage accumulates. No blocking missing-index/performance warning was reported.

The connected SQL inspection role is `supabase_read_only_user` and cannot assume `anon`, so a direct app-role RPC smoke call cannot be executed through that connector. This is a connector-role limitation, not an application grant defect; intended app-role execute grants were independently verified and runtime behavior is covered by the blocking repository regressions.

## Deferred security domains

Reporting/accounting, external payment/refund settlement, employee Badge/PIN credential lifecycle, hardware integrations and final production/App Store release operations remain Phase 8–10 or separately deferred. Do not begin them without explicit owner authorization.
