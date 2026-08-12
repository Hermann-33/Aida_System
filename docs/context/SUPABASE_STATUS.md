# Supabase Status

**Status date:** 2026-08-12
**Remote project:** Aida System
**Project ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`
**Implementation state:** identity/membership foundation live; customer auth/member client integration implemented on task branch; admin member-directory DB capability live; dashboard server transport not yet implemented

## Applied canonical migrations

Foundation:

1. `20260811101100_create_identity_membership_foundation.sql`
2. `20260811102200_harden_foundation_role_helpers.sql`
3. `20260811102700_optimize_foundation_rls_policies.sql`

TASK-AUTH-001:

4. `20260812191500_integrate_customer_auth_member_directory.sql`
5. `20260812192500_fix_signup_member_code_generation.sql`
6. `20260812195500_make_admin_member_directory_security_invoker.sql`

Canonical files live only in `Hermann-33/Aida_System/supabase/`.

The remote migration ledger also contains historical residue from pre-reset experimentation. Current catalog objects and canonical repository migrations, not old ledger names, determine project reality.

## Current objects

Tables:

- `public.user_profiles`
- `public.members`
- `public.student_verifications`

Enums:

- `public.app_user_role`
- `public.member_type`
- `public.student_verification_status`

Functions/helpers:

- `public.set_updated_at`
- `public.generate_member_code`
- `public.handle_new_auth_user`
- `public.list_admin_members()` — authenticated execute only, explicit admin/owner check, `SECURITY INVOKER`
- `private.current_app_role`
- `private.is_staff_or_above`
- `private.is_admin_or_owner`

## Signup/member contract

- Auth trigger creates/maintains `user_profiles` and inserts `members`.
- Application role is always `customer` at public signup.
- `member_code` is server-generated.
- `is_student=false` -> `standard` / `not_submitted`.
- `is_student=true` -> `student` / `pending`; verification is not granted by signup metadata.
- Forged role, member-code or verified-status metadata is ignored.

## RLS/access posture

- RLS enabled and forced on all foundation tables.
- Anonymous users have no direct foundation table access.
- Customer profile/member reads are owner-scoped.
- Bulk `user_profiles`/`members` reads are admin/owner only.
- Student verification submission is owner/pending constrained; trusted review remains staff/admin/owner as previously defined.
- Admin directory RPC runs as invoker, so table RLS remains active.

## Live verification on 2026-08-12

- Standard signup provisioning: PASS.
- Student pending provisioning: PASS.
- Signup metadata privilege/tamper attempts: PASS (rejected/ignored).
- Server member-code generation: PASS.
- Admin directory read: PASS.
- Ordinary customer directory read: PASS (rejected).
- Security advisor: **0 lints** after final hardening.
- Synthetic test transactions rolled back.
- Final retained counts after tests: 0 Auth users, 0 profiles, 0 members, 0 student verifications.

## Client connection state

### Customer

Task branch includes Supabase Flutter auth/session/member wiring. Other domains remain preview-backed until their tasks. A public/publishable client credential must be supplied at build/run time; no secret/service-role credential belongs in the app.

### Dashboard

Members UI targets same-origin `GET /api/v1/admin/members` and no longer reads member fixtures. The required production staff/admin BFF/session runtime does not yet exist, so this path is not end-to-end executable.

## Next backend task

`TASK-AUTH-002: trusted staff/admin session and member-directory API`.
