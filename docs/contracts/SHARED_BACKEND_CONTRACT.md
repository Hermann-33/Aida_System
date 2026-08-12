# Shared Backend Contract

Updated: 2026-08-12

## Authority

- Shared authority: Supabase Auth/Postgres/RLS plus controlled server/BFF operations.
- Canonical migrations: `Hermann-33/Aida_System/supabase/` until superseded by ADR.
- Frontend fixture/model shapes are not database authority.

## Customer identity and membership

- Customer identity comes from Supabase Auth.
- Auth signup provisions `user_profiles` + `members` server-side.
- Public signup cannot self-assign app role, verified student status or member code.
- Member code is server-generated/stable.
- Customer profile/member reads are owner scoped.

## Dashboard employee/admin session contract

Accepted in ADR-0008:

- Browser calls same-origin BFF with `credentials: include`.
- Password login: `POST /api/v1/auth/employee/login`.
- Session restore/refresh: `GET /api/v1/auth/employee/session`.
- Logout: `POST /api/v1/auth/employee/logout`.
- Access/refresh tokens are HttpOnly cookies and never application-storage/browser JSON fields.
- BFF revalidates Supabase Auth identity and the caller's trusted `user_profiles.app_role`/`disabled_at`.
- `customer` cannot become an employee session by authenticating successfully.
- Disabled employees are rejected.
- Terminal credentials are separate from employee/admin identity.

## Admin member directory

`GET /api/v1/admin/members` requires an authenticated admin/owner BFF session. The BFF calls `public.list_admin_members()` with the caller Supabase JWT. The RPC is `SECURITY INVOKER`; RLS and trusted role checks remain active. Ordinary staff and customers cannot list the member directory.

Returned fields are limited to trusted member/profile directory data: IDs, member code, display name, email, member type, student verification status, active status and creation time. Loyalty balances are not fabricated into this response.

## Secrets

Service-role keys, DB passwords, employee passwords/PINs, terminal credentials and provider secrets never enter Flutter/browser bundles or mirrored docs. The BFF needs only `AIDA_SUPABASE_URL` and a public/publishable Supabase key plus caller session cookies.

## Other shared domains

Catalogue/pricing, quotes/orders, payments, loyalty/vouchers, inventory, branches/terminals/employees, marketing/reporting/audit and realtime behavior remain governed by the existing shared-authority rules and require their own bounded tasks.

## Completion gate

A shared feature is not `COMPLETE` merely because source code exists. Applicable authorization, tests, deployment/executable path and cross-client behavior must be proven under ADR-0004.
