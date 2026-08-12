# AIDA Café Security Review

Updated: 2026-08-12
**Verdict:** secured identity/member foundation plus implemented customer auth and dashboard BFF source; product not yet production-ready.

## Current positive controls

- Foundation tables use forced RLS; anonymous foundation-table grants are absent.
- Trusted app roles live in `user_profiles`, not editable Auth metadata.
- Customer signup cannot self-promote role, verification or member code.
- `public.list_admin_members()` is `SECURITY INVOKER`, anon execute false, with explicit admin/owner check plus RLS.
- Dashboard employee/admin BFF stores Supabase access/refresh tokens only in HttpOnly, SameSite=Lax cookies.
- Browser JSON/storage never receives privileged bearer tokens or service-role credentials.
- BFF validates Auth identity plus caller-owned trusted `user_profiles.app_role`/`disabled_at`.
- Customer identities are rejected from employee sessions; disabled employee profiles are rejected.
- Admin member directory denies ordinary staff before the RPC call and invokes the RPC with the caller JWT.
- State-changing cookie endpoints require same origin; authenticated responses are `Cache-Control: no-store`.
- Admin login is separate from POS terminal identity.
- Live Supabase security advisor: 0 lints.

## Remaining security/product gaps

- A real deployment has not been exercised, so cookie/proxy/hosting behavior still needs live verification.
- No production admin/owner identity exists in the current empty Supabase project; operator bootstrap/role assignment needs an approved path and audit policy.
- Badge/PIN auth, branch assignments, terminal credential lifecycle, manager approval and employee administration remain unimplemented production domains.
- Catalogue/order/payment/loyalty/inventory/reporting business authority is still mostly preview/not implemented.
- Full privacy/retention/account-deletion and audit policy remain open.
- Full dashboard dependency/build checks are blocked until GitHub runner billing or another repository-capable toolchain is available.

## Secret handling

Never expose Supabase secret/service-role keys, DB passwords, employee passwords/PINs, terminal credentials, payment/provider secrets or private certificates in clients or repository docs. TASK-AUTH-002 server configuration requires only the Supabase URL and publishable key; employee tokens are per-session HttpOnly cookies.

## Required auth/member closure gates

- deploy same-origin dashboard+BFF;
- prove Secure/HttpOnly cookie issuance/refresh/logout in the deployed environment;
- bootstrap a trusted admin/owner without public self-promotion;
- create a real customer through the app and prove Admin Members receives that DB row;
- prove staff/customer/disabled denial;
- run dashboard lint/typecheck/tests/build and customer applicable checks.
