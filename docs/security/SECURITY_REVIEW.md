# AIDA Café Security Review

Updated: 2026-09-15

**Current verdict:** Phases 1–6 `COMPLETE`; Phase 7 repository implementation validated, formal Phase 7 `PARTIAL` pending live AIDA deployment/advisor verification.

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

Phase 6 authority tables are RLS + FORCE RLS and deny direct authenticated mutation. Customer wallet/redemption is caller-bound. Admin/Owner loyalty configuration/support rechecks trusted role and actor. POS member lookup requires staff-or-above, valid server-held terminal credential and open caller shift. Voucher ownership/status/expiry/eligibility and discount are validated server-side and consumption is placement-atomic.

## Phase 7 promotion controls

Promotion configuration tables and immutable application history use RLS + FORCE RLS with direct client table access revoked. Admin/Owner promotion management is exposed only through caller-bound RPCs that recheck trusted role and session actor.

Clients do not submit authoritative promotion IDs, promotion discount amounts or order totals. `quote_order` resolves promotions from trusted server configuration. Placement locks eligible promotion candidates in deterministic order before re-evaluation so global/per-member usage counts cannot be oversubscribed by concurrent orders.

Promotion scope validation enforces product/add-on catalogue kind and trusted branch/catalogue foreign keys. Fixed discounts use integer sen; percentage discounts use bounded basis points. Window, subtotal, maximum discount, stacking mode, voucher coexistence and usage-limit constraints are validated server-side.

Accepted promotion facts are persisted as immutable code/name/type/value/discount/priority/stacking/voucher-coexistence snapshots and reconciled to `orders.discount_sen`. Voucher and promotion discount components remain distinct so one authority cannot silently overwrite the other.

The Phase 7 contention regression proves that two concurrent orders competing for the final permitted promotion use yield exactly one accepted promotion application.

## Privacy controls

Whole-account deletion accepts no target user ID. It deletes customer-owned loyalty accounts/ledgers/vouchers, detaches identifying loyalty/member references from retained commercial snapshots, scrubs retained order-line/event free text, replaces the original customer payload digest, anonymizes retained customer order identity, then removes Auth/member-owned state. Staff/POS audit identity and non-identifying commercial facts remain.

Promotion application history may retain legitimate non-identifying accepted commercial facts; nullable member/promotion references prevent configuration or identity deletion from rewriting historic price truth.

## Client validation controls

Validated implementation heads before documentation synchronization:

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Customer #311 covers static analysis, non-golden regressions, goldens, release APK build and artifact upload. Dashboard #147 covers lint, typecheck, unit tests, live POS browser authority, preview isolation and production build. Backend #231 replays all migrations/regressions through Phase 7 plus the final-promotion-use contention gate.

## Live Supabase advisor status

Earlier Phase 1–6 advisor checks on 2026-09-15 found no implementation-created blocking security issue; one pre-existing Auth warning remained for leaked-password protection, and performance findings were INFO-level after FK index remediation.

Fresh Phase 7 advisors have **not** been run because the Supabase connection currently available does not expose AIDA project `eswovqxqzfevcdwwcmuh`. This is the remaining security-verification blocker. Do not substitute advisors from an unrelated Supabase project.

## Deferred security domains

Reporting/accounting, external payment/refund settlement, employee Badge/PIN credential lifecycle, hardware integrations and final production/App Store release operations remain Phase 8–10 or separately deferred. Phase 8–10 remain frozen while Phase 7 is `PARTIAL`.
