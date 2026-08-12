# Current Handoff

Updated: 2026-08-12

## Current task

`TASK-AUTH-001 — customer auth + member integration`

**Verdict:** PARTIAL.

Task branches in both repositories:

`codex/task-auth-001-auth-member-integration`

## Implemented

### Customer

- Added Supabase Flutter integration for email/password sign-up, sign-in, password recovery, persisted session bootstrap and logout.
- Replaced the local auth boolean as identity authority with Supabase Auth session state.
- Replaced mock member identity reads with owner-scoped `user_profiles` + `members` reads.
- Removed local signup generation of member IDs/codes from the implemented auth path.
- Student checkbox is now only a backend `pending` declaration; it never creates verified status.
- Runtime requires a public/publishable Supabase client key through `AIDA_SUPABASE_PUBLISHABLE_KEY`; no service-role or secret key is committed.
- Non-auth domains still use preview data until their own tasks.

### Shared Supabase

Applied three canonical TASK-AUTH-001 migrations from `Hermann-33/Aida_System/supabase/`:

1. `20260812191500_integrate_customer_auth_member_directory.sql`
2. `20260812192500_fix_signup_member_code_generation.sql`
3. `20260812195500_make_admin_member_directory_security_invoker.sql`

They harden signup provisioning, preserve server-issued member codes, restrict profile/member bulk reads to admin/owner, and expose authenticated admin member-directory RPC `public.list_admin_members()` under RLS.

Live verification passed for:

- standard signup provisioning;
- student pending provisioning;
- forged role/member-code/verified-status metadata rejection;
- server member-code format;
- authenticated admin directory read;
- ordinary customer directory rejection;
- security advisor 0 lints;
- rollback/no retained synthetic users.

### Dashboard

- Admin Members removed `PREVIEW_MEMBERS` as its data source.
- Added a capability-specific client for same-origin `GET /api/v1/admin/members` using cookie credentials.
- No fixture fallback exists for the Members tab.
- Points/stamps/reward values were removed from the Members tab because trusted loyalty persistence does not exist yet.
- Rewards Activity remains explicitly preview-only pending the loyalty task.

## Why the task is not COMPLETE

The dashboard repository has no production staff/admin server/BFF and no AIDA deployment providing the required same-origin HttpOnly employee session. Therefore `/api/v1/admin/members` is not implemented server-side and a customer signup cannot yet be demonstrated end-to-end in the production Admin Members screen.

Do not bypass this with:

- Supabase service-role keys in the browser;
- browser-stored privileged tokens;
- anonymous bulk member policies;
- customer-auth tokens treated as staff/admin authority.

## Verification/tooling debt

- Live Supabase SQL authorization/provisioning checks passed.
- Flutter dependency lock regeneration, analyzer/tests and a real signup/sign-in smoke test still require a Flutter-capable checkout/runtime.
- Dashboard unit/typecheck/build checks still require execution from a checkout/toolchain; source tests were added for the member-directory client.

## Exact next task

`TASK-AUTH-002: trusted staff/admin session and member-directory API`

Exit criterion: a real customer signup provisions the member in Supabase, a real authorized admin session can call `GET /api/v1/admin/members`, the dashboard renders that member from the API with no fixture fallback, unauthorized users are rejected, and relevant client/server/security checks pass.
