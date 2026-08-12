# Current Handoff

Updated: 2026-08-12

## Current task

`TASK-AUTH-002 — trusted staff/admin session and member-directory API`

**Verdict:** PARTIAL.

Branches in both repositories:

`codex/task-auth-002-admin-session-member-api`

These branches are stacked on the TASK-AUTH-001 branches; do not merge them ahead of their prerequisites.

## Implemented

### Customer + membership foundation inherited from TASK-AUTH-001

- Supabase Auth customer sign-up/sign-in/recovery/session restore/logout.
- Owner-scoped live profile/member reads.
- Server-created `user_profiles` + `members` with server-generated member code.
- Student self-declaration can only become `pending`.
- Admin/owner-only `public.list_admin_members()` under RLS and `SECURITY INVOKER`.
- Admin Members browser client has no fixture fallback.

### Dashboard BFF added by TASK-AUTH-002

- `server/employeeBff.ts`: password login, Auth user validation, profile/role/disabled check, access-token refresh, logout, admin member directory.
- `api/v1/auth/employee/login.ts`
- `api/v1/auth/employee/session.ts`
- `api/v1/auth/employee/logout.ts`
- `api/v1/admin/members.ts`
- HttpOnly `aida_employee_access` and `aida_employee_refresh` cookies; no privileged browser token storage.
- Admin member RPC is called using the employee/admin caller JWT, never service-role credentials.
- Same-origin checks protect state-changing cookie endpoints; authenticated responses are `no-store`.
- New `/admin/login` route removes the incorrect dependency on POS terminal enrolment.
- `server/viteBffPlugin.ts` mounts the identical BFF handlers in Vite dev/preview.
- `vercel.json` preserves Vite SPA deep links while root `/api` functions remain same-origin deployment adapters.
- ADR-0008 records the accepted BFF architecture in both repos.

## Verification

- Live Supabase: member RPC remains `SECURITY INVOKER`; anon execute false; authenticated execute true; security advisor 0 lints; retained data counts 0.
- BFF core compile/runtime harness passed the critical session/admin-member cases.
- GitHub Actions did not execute because the GitHub account refused to allocate a runner due billing/spending limits. This is infrastructure failure, not a code test result.

## Why the full feature is still PARTIAL

The source implementation that was missing in TASK-AUTH-001 now exists, but ADR-0004 requires executable end-to-end proof. There is no connected AIDA deployment and no real admin/owner account to authenticate, and the repository's full npm lint/typecheck/test/build chain could not run because GitHub Actions never started.

Do not bypass these gates by exposing a service-role key, opening member data anonymously, or storing privileged tokens in browser storage.

## Exact next task

`TASK-AUTH-003 — dashboard deployment + admin bootstrap + live auth/member E2E closure`.

Exit criterion: deploy the dashboard/BFF same-origin with only the Supabase publishable key, create or assign a real trusted admin/owner identity through an approved operator path, run the full repository checks, create a real customer through the app, and prove that customer appears in Admin Members while staff/customer/disabled access remains rejected.
