# Supabase Status

**Status date:** 2026-08-11
**Implementation state:** database foundation created; Flutter frontend not connected
**Remote project:** Aida System
**Project ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`

## Verdict

`TASK-DB-001` verified the reset project, created the first version-controlled Supabase migration foundation, and applied it to the remote Aida System project.

The frontend still does **not** connect to Supabase. No Flutter behavior, dependency, environment file, or client configuration was changed.

## Pre-migration reset verification

Before applying the foundation migrations, the remote project was verified as clean:

| Area | Verified result |
|---|---|
| `public` base tables | 0 |
| `public` enum types | 0 |
| `public` functions | 0 |
| `menu-images` bucket | absent |
| `marketing-assets` bucket | absent |

No old proof/demo schema or storage bucket remains.

## Migration ledger

| Migration | Remote applied | Purpose |
|---|---:|---|
| `20260811101100_create_identity_membership_foundation.sql` | Yes | Creates identity/profile/member/student-verification foundation, triggers, grants and first RLS policies |
| `20260811102200_harden_foundation_role_helpers.sql` | Yes | Moves role helper functions into non-exposed `private` schema |
| `20260811102700_optimize_foundation_rls_policies.sql` | Yes | Adds reviewed-by index and optimizes RLS calls to avoid auth init-plan warnings |

Repository files live under:

```text
supabase/migrations/
supabase/config.toml
supabase/tests/rls_foundation.sql
docs/database/SCHEMA_FOUNDATION.md
```

## Current database objects

### Tables

```text
public.user_profiles
public.members
public.student_verifications
```

### Enums

```text
public.app_user_role
public.member_type
public.student_verification_status
```

### Functions

Public operational/trigger functions:

```text
public.set_updated_at
public.generate_member_code
public.handle_new_auth_user
```

Private RLS helper functions:

```text
private.current_app_role
private.is_staff_or_above
```

The role helper functions were intentionally moved out of the exposed `public` API schema.

## Access and RLS posture

- RLS is enabled and forced on all foundation tables.
- Anonymous users have no direct table grants.
- Authenticated customers can select their own profile/member records.
- Authenticated customers can update only basic profile columns through column-level grants.
- Authenticated customers can insert pending student-verification submissions only for their own member record.
- Staff/admin/owner access uses trusted `user_profiles.app_role`, not user-editable Auth metadata.
- Student-verification review updates require staff/admin/owner role.
- New Supabase Auth users trigger creation of a `user_profiles` row and a server-issued `members.member_code`.

## Advisor findings

Security advisor after hardening:

```text
0 security lints
```

Performance advisor after optimization:

```text
No auth RLS init-plan warnings remain.
Only unused-index INFO lints remain, expected because the schema has no traffic yet.
```

## Frontend connection status

The customer frontend still has no Supabase dependency, client initialization, auth session bootstrap, database query, storage access, realtime subscription, or Edge Function call.

`MemberRepository` remains bound to `MockMemberRepository`. The database is ready for the next implementation phase, but no UI path is wired to it.

## Local development notes

Use Supabase CLI locally. Do not commit secrets.

```bash
supabase start
supabase db reset
supabase migration list
supabase db lint
supabase gen types typescript --local > supabase/types/database.types.ts
```

Remote linking is local-only:

```bash
supabase login
supabase link --project-ref eswovqxqzfevcdwwcmuh
```

## Current non-goals

This foundation does not implement:

- menu/catalogue schema;
- cart, quote, or order schema;
- loyalty ledger, rewards, or voucher schema;
- POS/staff/admin workflows;
- payment processing;
- storage buckets;
- reporting or marketing tables;
- Flutter integration.

## Next required work

Recommended next database task:

`TASK-DB-002: Design and migrate the published menu/catalogue foundation with public read policy, admin ownership boundary, and image/storage decision.`

Do not wire Flutter before the relevant schema, RLS, and adapter contract are reviewed.