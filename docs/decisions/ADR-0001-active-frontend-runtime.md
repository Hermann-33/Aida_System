# ADR-0001: Active frontend runtime

- **Status:** Accepted
- **Date:** 2026-08-11
- **Decision owners:** AIDA project direction and repository evidence

## Context

The repository contains several historical product/runtime narratives, but only one application source tree is present. `apps/customer/pubspec.yaml` defines Flutter/Dart; `lib/main.dart` starts a Material application inside Riverpod `ProviderScope`; platform folders exist for Android, iOS, and web. No POS, staff, admin, backend, or alternative frontend source is present.

The unified PRD describes legacy browser/Node/Neon and Next.js assets. Those assets are not in this checkout and cannot define its active runtime.

## Decision

The active frontend runtime is the Flutter customer application under `apps/customer`:

- Flutter Material 3 UI;
- Riverpod state management;
- Android, iOS, and web runner source;
- root `AuthGate`, five-tab customer shell, and imperative `Navigator` routes;
- domain/data/application/feature folder boundaries as currently implemented.

Only the customer application is active. POS/staff/admin are product scope but not active repository applications. There is no active backend or Supabase runtime in this repository.

## Consequences

- Frontend work must target `apps/customer` unless a separate app task is approved.
- Historical deployments and previews remain reference material, not current implementation evidence.
- A future POS/admin app requires an explicit repository/app-structure decision.
- `go_router` being declared does not make it active; routing remains imperative until a separately accepted migration.
- Native Windows is not a committed target merely because Flutter detects the host device.

## Evidence

- `apps/customer/pubspec.yaml`
- `apps/customer/lib/main.dart`
- `apps/customer/lib/features/shell/app_shell.dart`
- repository inventory in `docs/context/CODEBASE_MAP.md`
