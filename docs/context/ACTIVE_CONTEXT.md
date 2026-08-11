# Active Context

**As of:** 2026-08-11
**Repository:** `Hermann-33/Aida_System`
**Default branch:** `master`
**Active task branch:** `codex/task-db-001-supabase-foundation`
**Current task:** `TASK-DB-001`—Supabase migration and database foundation

## Current reality

- One active source application exists: `apps/customer`, a Flutter/Dart customer app.
- `main.dart` starts `ProviderScope` and a Material 3 `MaterialApp`.
- Riverpod owns app/session state. Navigation is an `AuthGate`, five-tab `IndexedStack`, and imperative `Navigator`/`MaterialPageRoute` pushes.
- `go_router` is declared but no `GoRouter` usage or route configuration exists.
- Customer app data remains bound to `MockMemberRepository`.
- No POS, staff, or admin app source is present.
- `TASK-DB-001` adds the first real Supabase database foundation, but the Flutter frontend is still not wired to it.

## Latest completed/active work

`TASK-WF-001` established repository governance and frontend audit documentation.

`TASK-DB-001` now establishes:

- Supabase CLI/config foundation under `supabase/`;
- remote verification for Aida System project `eswovqxqzfevcdwwcmuh`;
- version-controlled migrations for profile/member/student-verification foundation;
- RLS policies and role-helper hardening;
- RLS/schema check script;
- database documentation under `docs/database/SCHEMA_FOUNDATION.md`.

## Verified database state

Remote project:

- Name: Aida System
- Project ref: `eswovqxqzfevcdwwcmuh`
- Region: `ap-southeast-1`

Pre-migration reset state was verified:

- `public` base tables: 0
- `public` enum types: 0
- `public` functions: 0
- old proof buckets `menu-images` and `marketing-assets`: absent

Current foundation state:

- tables: `user_profiles`, `members`, `student_verifications`
- enums: `app_user_role`, `member_type`, `student_verification_status`
- RLS: enabled and forced on all foundation tables
- security advisor: 0 security lints after hardening
- performance advisor: only unused-index INFO lints remain, expected on a new schema with no traffic

## Current test/build state

Repository-side Flutter checks were not rerun by this GitHub/Supabase connector task because no checked-out runtime was available. Previous frontend audit baseline remains:

- Flutter: 3.44.7 stable; Dart 3.12.2.
- `flutter analyze --no-pub`: failed with one warning—unused `_stockChocolate` in `mock_member_repository.dart:213`.
- Full `flutter test --no-pub`: 24 tests passed and four golden comparisons failed.
- Non-golden command `flutter test --no-pub test\domain test\widgets test\widget_test.dart`: all 24 tests passed.

Supabase checks performed remotely:

- clean reset queries before migration;
- migration application;
- table/type/function/policy inventory queries;
- security advisor;
- performance advisor.

## Immediate priorities

1. Review and merge PR for `TASK-DB-001` after checking migration files.
2. Run local Supabase CLI validation from a checkout: `supabase db reset`, `supabase db lint`, and `supabase/tests/rls_foundation.sql`.
3. Decide the next narrow foundation task before Flutter wiring. Recommended: menu/catalogue schema and published read policy.
4. Separately fix the existing `_stockChocolate` analyzer warning and review golden diffs; that is frontend cleanup, not database foundation.

## Assumptions and unknowns

- **Assumption:** Supabase remains the selected platform for auth, database and storage.
- **Unknown:** final launch payment model, scheduled-order rules, full student-verification review process, account-deletion policy, and POS/admin ownership.
- **Unknown:** whether `staff`, `admin`, and `owner` roles will be managed manually, by an admin app, or by a controlled function in a later task.
- **Unknown:** whether current golden differences are intended UI evolution or environment/font rendering drift.

## Scope protection

Until an accepted task changes this context:

- do not claim the frontend is connected to Supabase;
- do not claim menu, cart, order, loyalty, reward, payment, POS, or admin persistence exists;
- do not expose service-role keys or database credentials;
- do not trust client-generated prices, member codes, order numbers, verification status, role claims, or loyalty values;
- do not wire Flutter features before the relevant database contract and RLS behavior are reviewed.