# Current Handoff

Updated: 2026-08-11

## Current task

`TASK-DB-001: Verify the reset Supabase project and establish the version-controlled migration, local-development, schema, and RLS testing foundation—without frontend feature wiring.`

## Starting state

- Repository transferred to `Hermann-33/Aida_System`; default branch `master`.
- Scrap branch `team1/aida-pos-admin-ui` exists and was ignored.
- Governance docs from `TASK-WF-001` were present on `master`.
- Frontend was still a Flutter customer prototype bound to `MockMemberRepository`.
- Supabase project was expected to be reset/clean, but repository docs still treated it as unverified.

## Completed work

- Created task branch `codex/task-db-001-supabase-foundation`.
- Verified the remote Aida System Supabase reset state before migration.
- Applied three Supabase migrations to remote project `eswovqxqzfevcdwwcmuh`.
- Added version-controlled Supabase CLI/config and migration files.
- Added RLS/schema posture check script.
- Added `docs/database/SCHEMA_FOUNDATION.md`.
- Updated architecture, active context, Supabase status, codebase map, roadmap, audit log and this handoff.
- Added `ADR-0005: Database migration and identity foundation`.

## Behavior changed

No Flutter behavior changed. No frontend package, lockfile, UI, route, provider, screen, model or asset was changed.

## Database and infrastructure changes

Remote Supabase project changed from clean/reset state to initial foundation state.

Created:

- `public.user_profiles`
- `public.members`
- `public.student_verifications`
- `public.app_user_role`
- `public.member_type`
- `public.student_verification_status`
- `public.set_updated_at()`
- `public.generate_member_code()`
- `public.handle_new_auth_user()`
- `private.current_app_role()`
- `private.is_staff_or_above()`
- Auth trigger `on_auth_user_created_aida_profile`

Security/RLS:

- RLS enabled and forced on all foundation tables.
- Anonymous users have no direct table grants.
- Customer access is owner-scoped.
- Staff/admin/owner access uses trusted `user_profiles.app_role` through private RLS helpers.
- Public RPC role helpers were removed from the exposed public schema.

## Verification evidence

Remote Supabase checks:

- Pre-migration `public` base table inventory: empty.
- Pre-migration `public` enum inventory: empty.
- Pre-migration `public` function inventory: empty.
- Old proof buckets `menu-images` and `marketing-assets`: absent.
- Post-migration tables: `members`, `student_verifications`, `user_profiles`.
- Post-migration enums: `app_user_role`, `member_type`, `student_verification_status`.
- Post-migration public functions: `generate_member_code`, `handle_new_auth_user`, `set_updated_at`.
- Post-migration policies: six foundation policies across the three tables.
- Supabase security advisor after hardening: 0 lints.
- Supabase performance advisor: only unused-index INFO lints remain, expected on a new no-traffic schema.

Repository checks:

- GitHub connector verified admin/write access to `Hermann-33/Aida_System`.
- Branch list inspected; `team1/aida-pos-admin-ui` ignored as instructed.
- Migration/config/docs created on task branch.

Not run:

- Flutter tests/analyze, because no local checkout/runtime execution was available through this connector task.
- Local `supabase db reset`, because this task used the connected remote Supabase project and GitHub API rather than a local CLI checkout.

## Branch and PR

- Branch: `codex/task-db-001-supabase-foundation`
- Base: `master`
- PR: opened by this task if connector PR creation succeeded.

## Exact next action

Review the PR diff, especially:

1. `supabase/migrations/`
2. `docs/context/SUPABASE_STATUS.md`
3. `docs/database/SCHEMA_FOUNDATION.md`
4. `docs/decisions/ADR-0005-database-migration-and-identity-foundation.md`

Then run local validation from a checkout if available:

```bash
supabase start
supabase db reset
supabase db lint
```

Recommended next implementation task after merge:

`TASK-DB-002: Design and migrate the published menu/catalogue foundation with public read policy, admin ownership boundary, and image/storage decision.`

## Known risks

- Existing Flutter analyzer warning `_stockChocolate` and golden failures remain unresolved because this was a database task.
- RLS behavior needs local/CI tests with seeded auth users in a later task.
- Staff/admin role assignment has no UI or controlled admin operation yet.
- Menu/order/loyalty schemas are intentionally absent.
- Flutter is not wired to Supabase yet.

## Do-not-touch boundaries

Do not wire Flutter directly to the foundation tables until auth/session adapter contracts, typed failures, local cache/logout behavior, and RLS tests are reviewed. Do not add menu/order/loyalty/POS tables without separate bounded tasks.