# Supabase Status

**Status date:** 2026-08-12
**Project:** Aida System
**Ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`

## Implemented identity/membership objects

Tables:

- `public.user_profiles`
- `public.members`
- `public.student_verifications`

Key functions/helpers:

- `public.generate_member_code`
- `public.handle_new_auth_user`
- `public.list_admin_members()`
- private trusted role helpers

All foundation tables use forced RLS. Customer reads are owner-scoped. Bulk profile/member access and the member-directory RPC are admin/owner controlled.

## TASK-AUTH-001 migrations

1. `20260812191500_integrate_customer_auth_member_directory.sql`
2. `20260812192500_fix_signup_member_code_generation.sql`
3. `20260812195500_make_admin_member_directory_security_invoker.sql`

Canonical files remain in `Hermann-33/Aida_System/supabase/`.

## TASK-AUTH-002

No schema migration was required. The dashboard BFF authenticates via Supabase Auth using only a project publishable key, validates the caller's own `user_profiles` record, and calls `list_admin_members()` with the caller access token. It does not use a service-role bypass.

Latest live verification:

- `list_admin_members()` is `SECURITY INVOKER`.
- anon execute: false.
- authenticated execute: true, subject to function/RLS admin/owner checks.
- security advisor: 0 lints.
- retained counts: 0 Auth users, 0 profiles, 0 members, 0 student verifications.

## Client connection state

- Customer auth/member path: real Supabase integration on TASK-AUTH-001 stack.
- Dashboard admin auth/member path: same-origin BFF source implemented on TASK-AUTH-002 stack; Vite dev/preview middleware and serverless `/api` adapters share one core.

## Remaining operational gate

No real admin/owner Auth identity or connected AIDA deployment exists yet, so deployed browser E2E remains unproven. This is not a reason to weaken RLS or expose privileged credentials.
