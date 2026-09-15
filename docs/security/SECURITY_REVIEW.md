# AIDA Café Security Review

Updated: 2026-09-15

**Current verdict:** Phases 1–6 `COMPLETE`; valid Phase 1–3 Codex findings remediated `COMPLETE`.

## Core trust controls

- Supabase Auth is authentication identity; trusted role/disabled state comes from server-owned profile state.
- Customer-editable Auth metadata and preview fixtures are never authorization authority.
- Dashboard privileged traffic uses same-origin HttpOnly employee/terminal cookies and caller-JWT forwarding.
- No normal Flutter/browser/BFF flow uses a service-role secret or exposes a reusable employee bearer/terminal credential to browser JavaScript.
- Controlled RPCs plus RLS/FORCE RLS own protected operational/commercial/customer state.

## Operational controls

Employee branch scope, terminal enrolment/revocation, topology attribution, shift ownership/state and cash reconciliation are server-validated. New POS placement requires current terminal/caller authority and an open shift. Matching idempotent retries may resolve after lock/close without creating new authority.

Branch scheduling/capacity is server-owned; inventory consumption is transactional/non-negative with compensating cancellation reversals.

## Phase 6 loyalty controls

Eight Phase 6 authority tables are RLS + FORCE RLS and deny direct authenticated INSERT/UPDATE/DELETE. Customer wallet/redemption is caller-bound. Admin/Owner loyalty configuration/support rechecks trusted role and actor. POS member lookup requires staff-or-above, valid server-held terminal credential and open caller shift. Voucher ownership/status/expiry/eligibility and discount are validated server-side and consumption is placement-atomic.

The generic private order writer is not executable by `authenticated`. Anonymous privileged loyalty and POS lookup execution is denied.

## Privacy controls

Whole-account deletion accepts no target user ID. It deletes customer-owned loyalty accounts/ledgers/vouchers, detaches identifying loyalty references from retained commercial snapshots, scrubs retained order-line/event free text, replaces the original customer payload digest, anonymizes retained customer order identity, then removes Auth/member-owned state. Staff/POS audit identity and non-identifying commercial facts remain.

## Client validation controls

Customer release audit #281 is blocking for static analysis, 58 non-golden tests, four full-screen golden tests, release APK build and artifact upload. Dashboard CI #126 is blocking for lint, typecheck, unit tests, live-POS browser authority regression and production build. Backend audit #190 replays every migration/regression through Phase 6.

## Live Supabase advisor result

Security advisor: no Phase 6 WARN/ERROR. One pre-existing warning remains: leaked-password protection is disabled. INFO RLS-with-no-policy notices on RPC-only Phase 6 tables are expected because direct client table grants are revoked.

Performance advisor: the six Phase 6 missing-FK-index notices were fixed; remaining notices are INFO unused-index observations.

## Deferred security domains

General promotions/discount stacking/targeting, reporting/accounting, external payment/refund settlement, employee credential lifecycle, hardware integrations and deployment-heavy production operations remain later boundaries.