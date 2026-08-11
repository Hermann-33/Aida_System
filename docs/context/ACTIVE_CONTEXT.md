# Active Context

**As of:** 2026-08-11
**Repository:** `C:\code\Aida_System`
**Branch at audit:** `master`, tracking `origin/master`
**Current task:** `TASK-WF-001`—frontend audit and governance documentation baseline

## Current reality

- One active source application exists: `apps/customer`, a Flutter/Dart customer app.
- `main.dart` starts `ProviderScope` and a Material 3 `MaterialApp`.
- Riverpod owns app/session state. Navigation is an `AuthGate`, five-tab `IndexedStack`, and imperative `Navigator`/`MaterialPageRoute` pushes.
- `go_router` is declared but no `GoRouter` usage or route configuration exists.
- All repository-backed reads and auth calls resolve through `MemberRepository`; the provider binds `MockMemberRepository` only.
- No backend, Supabase client, Supabase config, schema, or migrations are present in this checkout.
- Customer checkout/order tracking is a UI simulation. No order leaves the process.
- No POS, staff, or admin app source is present.

## External project context

The task owner states that Supabase is the intended implementation platform and that its database was reset/cleaned for actual implementation. This is not verifiable from repository files or a connected database in this task. Treat the schema as empty/unknown until a dedicated foundation task verifies the project and introduces reviewed migrations.

## Verification baseline

- Flutter: 3.44.7 stable; Dart 3.12.2.
- `flutter analyze --no-pub`: failed with one warning—unused `_stockChocolate` in `mock_member_repository.dart:213`.
- Full `flutter test --no-pub`: 24 tests passed and four golden comparisons failed (home, home scrolled, menu selected, membership card).
- Non-golden command `flutter test --no-pub test\domain test\widgets test\widget_test.dart`: all 24 tests passed.
- Secret-pattern inventory found no `.env`, key, credential, migration, or Supabase files. This is a filename/text audit, not a credential-scanner guarantee.

## Immediate priorities

1. Review this documentation diff and the generated golden failure artifacts; do not commit yet.
2. Run a dedicated Supabase/database foundation task that verifies the target project and establishes versioned schema/migration and RLS conventions without wiring UI features prematurely.
3. After the foundation is accepted, integrate real authentication/profile/membership through a concrete repository implementation and durable session/member-code storage.

## Assumptions and unknowns

- **Assumption:** Supabase is now selected, based on the current task context; older specs still describe the choice as open.
- **Unknown:** Supabase project reference, regions, enabled providers, current extensions, Data API exposure, and actual post-reset objects.
- **Unknown:** launch payment model, scheduling rules, student-verification method, voucher expiry/retention rules, and account-deletion policy.
- **Unknown:** whether POS and admin will live in this repository or separate repositories.
- **Unknown:** whether current golden differences are intended UI evolution or environment/font rendering drift.

## Scope protection

Until an accepted task changes this context, do not claim any mock/session feature is persisted, any schema exists, any old proof table survives, or any POS/admin operation is implemented.
