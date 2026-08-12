# AIDA Café Security Review

Updated: 2026-08-12
**Verdict:** secured identity/member foundation plus partial client integration; not production-ready.

## Current positive controls

- Foundation tables use forced RLS.
- Anonymous foundation-table access is absent.
- Trusted app roles live in database records, not user-editable metadata.
- Customer sign-up cannot self-assign staff/admin/owner, verified student status or member code.
- Member code is server-generated.
- Customer profile/member reads are owner-scoped.
- Bulk profile/member reads are admin/owner only; ordinary staff no longer inherit a bulk customer directory from the generic staff helper.
- `public.list_admin_members()` is authenticated-only, explicit admin/owner checked and `SECURITY INVOKER`, preserving RLS.
- Final live Supabase security advisor: 0 lints.
- Customer app runtime accepts only a public/publishable Supabase client key; no service-role secret is committed.
- Dashboard Members adapter uses a same-origin cookie-authenticated API contract and has no fixture fallback or browser privileged credential.

## TASK-AUTH-001 tamper tests

Rolled-back live tests verified:

- forged `app_role=owner` signup metadata does not escalate role;
- forged `student_status=verified` does not verify a student;
- forged `member_code` is ignored and server code is generated;
- student self-declaration creates only pending status;
- authenticated admin can list members;
- ordinary customer cannot execute the directory successfully;
- no synthetic test user/member data remains after rollback.

## Remaining customer risks

- Other domains still use preview data: catalogue/pricing, loyalty, orders/payments, promotions and related outcomes.
- Profile-edit persistence remains a separate task.
- Static member QR remains lookup material and can be shared; authorized POS lookup is not implemented.
- Full cache/revocation/device abuse testing is still required.

## Remaining dashboard risks

- Production staff/admin BFF/session runtime is absent.
- Route guards and preview roles are not backend authorization.
- Branch IDs, employees, manager approval, terminal status/enrolment, POS prices/rewards/tenders, receipts/orders, inventory and reports remain preview/local.
- `/api/v1/admin/members` is a browser client contract only until TASK-AUTH-002 implements the trusted same-origin endpoint.
- Never fill this gap with service-role keys in Vite, localStorage staff tokens or anonymous member policies.

## Secret handling

Never expose Supabase secret/service-role keys, database passwords, provider secrets, employee credentials, PINs or terminal credentials in either client repo/bundle. Public/publishable client credentials may be supplied through runtime/build configuration; secret credentials stay server-side.

## Required release security gates

- migration-reviewed RLS tests for anonymous/customer/cross-user/staff/admin/branch cases;
- auth/session/revocation/shared-device tests;
- terminal/manager-approval abuse tests;
- quote/order/payment/loyalty idempotency/concurrency tests;
- dependency and secret/bundle scanning;
- Supabase security/performance advisor checks;
- privacy/retention/account-deletion decisions;
- updated threat review before UAT/release.
