# AIDA Café Security Review

Updated: 2026-08-12
**Verdict:** prototype/front-end preview plus narrow secured database foundation; not production-ready.

## Current positive controls

- Supabase foundation tables have forced RLS.
- Anonymous table grants are absent for foundation data.
- Trusted app roles live in database records rather than user-editable metadata.
- Publicly executable role-helper RPC exposure was removed; security advisor reports 0 lints.
- Customer money model uses integer sen and repository comments identify server authority.
- Dashboard production build rejects preview/auth-bypass configuration; preview E2E includes browser-storage secret assertions.

These controls do not yet secure unimplemented order/payment/loyalty/POS/admin operations.

## Customer risks

- Any mock sign-in succeeds; auth gate is local.
- Client generates/uses mock identity, prices, totals, order number/status and loyalty values.
- Logout does not explicitly clear every session-local store.
- Static member QR can be shared and is not proof of identity.
- Password reset/social sign-in/offline cache are not real integrations.

Required: Supabase Auth lifecycle, owner RLS, per-user cache isolation, server quote/order/loyalty operations and authorized QR lookup.

## Dashboard risks

- Route guards/preview roles are client-side usability controls, not authorization.
- Branch IDs, employees, manager approval, terminal status and enrolment are preview/local assumptions.
- POS prices/rewards/tenders and receipt/order IDs are client calculated/generated.
- Non-cash payments are simulated; void/refund/cancel only affect local preview state.
- Inventory transfers, employee/menu/location edits, marketing publication and report/audit data are non-durable preview state.
- API-backed E2E cannot yet run against the intended shared backend.
- Dependency audit reported 1 moderate and 4 high findings; remediation must be separately reviewed rather than blindly upgraded.

Required: trusted employee/session/terminal/branch authorization, controlled high-risk operations, idempotent payment/order actions, durable audit and dependency remediation.

## Shared threat boundaries

| Area | Required control |
|---|---|
| Roles/branch scope | server/RLS checks from trusted records; role removal/revocation tests |
| QR/member lookup | staff authorization, rate limits, minimal returned data, audit |
| Price/order | server quote, allowed modifiers, atomic/idempotent create, legal transitions |
| Payments/refunds | provider/device boundary, no raw credentials, trusted status/reference, approval/audit |
| Loyalty/vouchers | ledger, server time, atomic redemption/consume, replay/concurrency tests |
| Terminal enrolment | short-lived enrolment, HttpOnly/secure credential, revocation, branch binding, audit |
| Manager approval | trusted manager identity/credential, rate limits, action/reason binding, audit |
| Inventory | location scope, validated units, atomic movements, approval/audit for adjustments |
| Marketing | privileged publication, validation/versioning/expiry, safe media handling |
| Reports/exports | admin/branch scope, privacy minimization, export audit |
| Audit | append-only/equivalently protected records; clients cannot forge/delete operational history |

## Secret handling

Never expose Supabase secret/service-role keys, database passwords, provider secrets, employee credentials, PINs or terminal credentials in either client repo/bundle. `.env` files remain local/managed-secret configuration and must not be copied into mirrored docs.

## Privacy

Expected personal data includes names, emails, phone numbers, birthdays, campus IDs, member/order/loyalty history and possibly images. Retention, access/export, correction, account deletion/anonymization, staff visibility, verification evidence retention, backups and audit retention require explicit policy before production.

## Payment scope

Raw card/e-wallet credentials stay with approved providers/devices. AIDA stores only necessary provider references, trusted status, amounts and reconciliation metadata under a later approved payment architecture.

## Required release security gates

- migration-reviewed schema and RLS tests for anonymous/customer/cross-user/staff/admin/branch cases;
- auth/session/revocation/shared-device tests;
- terminal and manager-approval abuse tests;
- quote/order/payment/loyalty idempotency and concurrency tests;
- inventory authorization tests;
- dependency and secret/bundle scanning;
- Supabase security/performance advisors;
- controlled audit/logging and incident/recovery plans;
- privacy/retention decisions;
- updated threat review before UAT/release.