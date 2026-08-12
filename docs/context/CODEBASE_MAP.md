# AIDA Café Codebase Map

Updated: 2026-08-12

## Customer repository — `Hermann-33/Aida_System`

- `apps/customer/`: Flutter customer app.
- `apps/customer/lib/features/auth/login_screen.dart`: real Supabase email/password sign-up/sign-in UI path on TASK-AUTH-001 branch.
- `apps/customer/lib/application/providers.dart`: Riverpod bindings; auth state now follows Supabase session on TASK-AUTH-001 branch.
- `apps/customer/lib/data/repository/supabase_member_repository.dart`: real auth/session/member adapter; delegates only not-yet-integrated feature families to preview repository.
- `apps/customer/lib/data/repository/mock_member_repository.dart`: still preview authority for catalogue/loyalty/promotions and other domains not covered by TASK-AUTH-001; no longer auth/member authority on the task branch.
- `apps/customer/lib/domain/`: models and `MemberRepository` port.
- `apps/customer/test/`: domain/widget/golden tests.
- `supabase/`: canonical Supabase config, migrations and SQL checks.

TASK-AUTH-001 migrations/tests:

- `supabase/migrations/20260812191500_integrate_customer_auth_member_directory.sql`
- `supabase/migrations/20260812192500_fix_signup_member_code_generation.sql`
- `supabase/migrations/20260812195500_make_admin_member_directory_security_invoker.sql`
- `supabase/tests/auth_membership_integration.sql`

## Dashboard repository — `Hermann-33/Aida_System-Dashboard`

- `src/auth/`: employee/session boundaries; production same-origin HttpOnly session contract exists conceptually but server runtime is not implemented.
- `src/features/admin/AdminMembersLoyaltyReportPage.tsx`: Members tab now renders backend-shaped member data and no longer imports `PREVIEW_MEMBERS`; Rewards Activity remains preview-only.
- `src/features/admin/memberDirectory.ts`: same-origin `GET /api/v1/admin/members` client with `credentials: include`; no fixture fallback.
- `src/features/admin/memberDirectory.test.ts`: adapter contract/error/authorization tests.
- `src/preview/`: remaining preview fixtures/repositories for unintegrated domains.
- `e2e/`: preview and API-backed suites.

## Shared backend ownership

Canonical migrations remain only in the customer repository's `supabase/` workspace. Do not create dashboard-local migration history without a superseding ADR.

## Standard checks

Customer:

```bash
cd apps/customer
flutter pub get
flutter analyze
flutter test
```

Dashboard:

```bash
npm run lint
npm run typecheck
npm test
npm run build
```

Supabase:

```bash
supabase db reset
supabase db lint
```

Live remote checks are supplemental; local reset/lint remains required before a database task is considered release-ready.
