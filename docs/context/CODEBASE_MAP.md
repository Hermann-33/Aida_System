# AIDA Café Codebase Map

Updated: 2026-08-12

## Customer repository — `Hermann-33/Aida_System`

- `apps/customer/`: Flutter customer app.
- `apps/customer/lib/features/`: auth, home, rewards, membership card, menu, cart/order, history, profile and shell.
- `apps/customer/lib/application/providers.dart`: Riverpod binding and session/local application state.
- `apps/customer/lib/domain/`: models and `MemberRepository` port.
- `apps/customer/lib/data/repository/mock_member_repository.dart`: active hardcoded adapter.
- `apps/customer/test/`: domain/widget/golden tests.
- `supabase/`: canonical Supabase config, migrations and SQL checks.
- `docs/screenshots/`, `docs/superpowers/specs/`, unified PRD: customer-specific evidence/specification inputs.

Customer fragile boundaries are detailed in `docs/frontend/FRAGILE_BOUNDARIES.md`.

## Dashboard repository — `Hermann-33/Aida_System-Dashboard`

- `src/main.tsx`, `src/App.tsx`: React root, Query provider and route tree.
- `src/auth/`: employee identity/session, permission and terminal adapter boundaries.
- `src/layouts/`: employee, POS and admin layouts.
- `src/features/pos/`: counter cart/modifiers/member/reward/payment/receipt/orders/shifts/terminal/help workflows.
- `src/features/admin/`: overview, reports, transactions, members, locations, terminals, shifts, employees, menu, inventory, loyalty, marketing, audit, integrations, settings and table preview.
- `src/preview/`: preview mode, deterministic fixtures and local/session repositories.
- `e2e/`: preview closure and API-backed test suites.
- `scripts/`: build/security assertions and screenshot tooling.
- `docs/screenshots/`, `docs_screenshots/`: dashboard-specific UI evidence.
- `DASHBOARD_IMPORT_AUDIT.md`: source import audit from `TASK-WF-002`.

Dashboard fragile boundaries are detailed in `docs/dashboard/FRAGILE_BOUNDARIES.md`.

## Shared backend workspace

Canonical migration source currently exists only in customer repo:

- `supabase/config.toml`
- `supabase/migrations/20260811101100_create_identity_membership_foundation.sql`
- `supabase/migrations/20260811102200_harden_foundation_role_helpers.sql`
- `supabase/migrations/20260811102700_optimize_foundation_rls_policies.sql`
- `supabase/tests/rls_foundation.sql`

## Toolchains and checks

Customer:

```powershell
cd apps/customer
flutter analyze
flutter test
```

Dashboard:

```powershell
npm run lint
npm run typecheck
npm test
npm run build
npm run test:e2e
```

Supabase:

```bash
supabase start
supabase db reset
supabase db lint
```

## Repository-specific evidence exception

The mirrored project docs coexist with source-specific screenshots/specs. Do not delete or clone large screenshot evidence merely to make repository trees identical; only the canonical governance paths in `docs/README.md` must mirror.