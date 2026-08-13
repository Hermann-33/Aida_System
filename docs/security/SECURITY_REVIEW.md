# AIDA Café Security Review

Updated: 2026-08-14

**Current verdict:** the implemented identity/member, employee-session, catalogue and order backend boundaries are hardened and have live evidence; the current tranche remains `PARTIAL` until Dashboard order frontend integration, clean Android build reproducibility and final cross-client order E2E/merge checks pass.

## Identity and membership

- Supabase Auth is the authentication authority.
- `user_profiles.app_role` plus `disabled_at` are trusted employee/Admin authorization state.
- `members` is trusted customer membership state.
- Public signup is forced to customer role and cannot self-promote to staff/admin/owner.
- User-editable metadata cannot assign member code or verified student status.
- Member code generation is server-owned.
- Customer profile/member reads are owner-scoped.
- Employee identities and customer membership are separate concepts.

Dated 2026-08-14 closeout evidence shows 9 Auth users/profiles, 6 customer members and one profile each for owner/admin/staff. The three employee identities are not member rows.

The user physically validated customer signup from the installed Android release app and subsequent member visibility through the protected Dashboard Admin/owner member-directory path.

## Dashboard privileged session boundary

ADR-0008 remains authoritative:

- same-origin browser/BFF boundary;
- HttpOnly employee access/refresh cookies;
- Secure cookies on HTTPS;
- trusted profile role/disabled-state validation;
- caller JWT forwarded to Supabase;
- same-origin enforcement for state-changing requests;
- no service-role key in Vite/browser code;
- no browser-readable employee bearer-token persistence.

TASK-AUTH-005 fixed the preview/live session loop without weakening this model. Preview identity is local/non-authoritative; preview Members makes no privileged member request; preview Menu is public-catalogue read-only; real session expiry still clears the real employee session.

## Shared catalogue controls

- Catalogue tables use RLS/FORCE RLS as designed.
- Public/customer reads are publication-scoped.
- Admin/owner writes use protected BFF + caller JWT + controlled RPCs.
- Prices are integer sen and backend authority.
- Variants and compatible add-ons are server relationships.
- Mutation produces audit evidence and catalogue revision invalidation.
- Customer runtime has no production hardcoded catalogue fallback.
- Dashboard live Admin mutations do not use preview identity as authority.

The user physically validated a real Owner price mutation propagating to the installed customer app. Closeout baseline catalogue revision was 15.

## Android client/network security

TASK-AUTH-006 fixed release network access by declaring the standard Android INTERNET permission in the main manifest. The fix does not weaken TLS, use hardcoded IPs, enable cleartext HTTP or add a network-security bypass.

Customer production configuration contains only the public Supabase project URL/publishable key. Service-role/secret keys remain prohibited.

The user subsequently installed the fixed release app and successfully reached Supabase signup, closing the prior host-resolution transport failure.

Android release build reproducibility remains an engineering gate because the prior successful APK used local AGP/Gradle compatibility settings. Closeout must commit a supported reproducible build-tool configuration; no machine-specific path or secret may be introduced.

## Order/scheduling controls

All order/scheduling commercial authority remains server-side.

Controls include:

- RLS/FORCE RLS on order/scheduling tables;
- no ordinary authenticated direct INSERT/UPDATE grants on commercial order tables;
- `quote_order(jsonb)` re-prices from current catalogue truth and ignores client totals;
- item/variant/add-on compatibility revalidation;
- trusted customer/member derivation from the authenticated session;
- staff-or-above requirement for POS placement and status mutation;
- server-owned order UUID/number, commercial snapshots, totals, initial status and timestamps;
- immutable commercial fields;
- required `clientRequestId` idempotency;
- server schedule validation against timezone/lead/interval/horizon;
- admin/owner-only schedule-policy mutation;
- allow-listed fulfilment transitions with expected `statusVersion`;
- append-only order events;
- owner-scoped customer order visibility.

Canonical order regression previously proved forged totals ignored, direct order DML denial, incompatible add-on/invalid schedule rejection, ownership, idempotency, staff queue/POS capability, admin schedule policy and stale/illegal transition failures.

The remaining order risk is frontend integration, not a missing backend trust boundary: Dashboard React must stop treating preview transactions/client totals/local receipt state as live trusted order authority and must use the existing same-origin order BFF.

## Realtime/token boundary

Customer Flutter can use its own owner-scoped Supabase session for `orders` and catalogue invalidation and then refetch authorized state.

Dashboard employee JWTs remain HttpOnly. React must not expose a staff token merely to open a direct Supabase Realtime connection. The current accepted dashboard order-board strategy is short same-origin BFF polling/refetch plus immediate invalidation after local mutations.

## Payment boundary

No real payment processor or trusted settlement/refund state exists in this tranche.

The authoritative demo order path must use explicit **Pay at counter / unpaid** semantics. It must not claim Card, E-wallet, Student Wallet, cash settlement, refund or processor success.

Order completion currently means fulfilment completion, not verified payment settlement.

## Current Supabase advisor state

Historical migrations/tasks recorded `0 lints` at their validation time. That is no longer the current advisor state.

Current security advisor warning:

- `auth_leaked_password_protection` — leaked-password protection disabled.

This is a hosted Supabase Auth configuration warning. The remediation is a project Auth setting, not an application RLS/schema workaround. Source code must not weaken passwords/authentication to silence the warning.

Performance advisor currently reports unused-index INFO notices on low-volume/new indexes. Those are not security defects and should not trigger speculative index removal during closeout.

## Secrets and test identities

Repository source/documentation must not contain:

- service-role or `sb_secret_` credentials;
- employee passwords/PINs;
- terminal enrolment secrets;
- bearer access/refresh tokens;
- payment secrets/private certificates.

Dated counts and non-secret test identity existence may be recorded as evidence, but plaintext test passwords must remain outside version control.

## Deferred trusted domains

Separate bounded tasks remain required for:

- payment capture/refunds;
- loyalty earning/redemption;
- inventory depletion;
- promotions/discounts;
- tax/accounting;
- revenue/reporting;
- branch-scoped staff/order access;
- branch hours/capacity;
- delivery.

These domains must consume authoritative order/payment state rather than frontend preview values.

## Remaining closeout gates

Before the current tranche may be called `COMPLETE`:

1. Android release build must be reproducible from committed Git.
2. Dashboard live POS/order surfaces must consume the order BFF and remove preview transaction authority from live order flows.
3. Customer placement -> staff status transition -> customer authorized refresh must be proven end-to-end.
4. Final client tests, secret scans, live advisor review and mirrored documentation reconciliation must pass.
