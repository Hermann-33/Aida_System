# POS/Admin Backend Integration Plan

Updated: 2026-08-12

## Implemented auth/member slice

- Same-origin BFF source for Supabase Auth password login, session validation/refresh and logout.
- HttpOnly employee tokens; no browser bearer-token persistence.
- Trusted `user_profiles.app_role`/`disabled_at` check on employee/admin access.
- Separate `/admin/login`; admin browser access does not require POS terminal enrolment.
- `GET /api/v1/admin/members` uses authenticated admin/owner caller JWT -> `public.list_admin_members()` under RLS.
- Admin Members has no fixture fallback and does not invent loyalty values.
- Same handlers run through Vite dev/preview middleware and root `/api` deployment adapters.

## Still required for auth/operations

- production deployment/E2E and admin bootstrap;
- badge/PIN authentication;
- terminal enrolment/revocation backend;
- branch assignments/global-manager/dual-role policy beyond the narrow current role mapping;
- employee role/status administration and audit;
- manager approval.

## Other backend domains

Shared catalogue -> quote/order/payment -> loyalty/member operations -> inventory -> marketing/reporting/integrations remain future tasks. Do not create dashboard-only authority for those domains.
