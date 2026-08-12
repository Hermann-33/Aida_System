# AIDA Café Codebase Map

Updated: 2026-08-12

## Customer — `Hermann-33/Aida_System`

- `apps/customer/`: Flutter customer app.
- `apps/customer/lib/application/providers.dart`: Riverpod state/session bindings.
- `apps/customer/lib/data/repository/supabase_member_repository.dart`: live Auth/profile/member adapter.
- `apps/customer/lib/data/repository/mock_member_repository.dart`: remaining non-auth preview domains.
- `supabase/`: canonical migrations/tests.
- `docs/`: mirrored project context, frontend/dashboard context, contracts, security and ADRs.

## Dashboard — `Hermann-33/Aida_System-Dashboard`

Client:

- `src/auth/employeeSession.ts`: cookie-only employee session client.
- `src/auth/ProtectedRoute.tsx`: UI route gating; admin unauthenticated path goes to `/admin/login`.
- `src/pages/AdminLoginPage.tsx`: terminal-independent administrator password login.
- `src/features/admin/memberDirectory.ts`: live same-origin member-directory client with no fixture fallback.
- `src/features/admin/AdminMembersLoyaltyReportPage.tsx`: trusted member directory rendering; loyalty activity remains separately preview-marked.

Server/BFF:

- `server/employeeBff.ts`: Supabase Auth session, refresh/logout, role/disabled validation and admin member RPC.
- `server/employeeBff.test.ts`: server security/authorization tests.
- `server/viteBffPlugin.ts`: mounts the same handlers in Vite dev/preview.
- `api/v1/auth/employee/{login,session,logout}.ts`: same-origin deployment adapters.
- `api/v1/admin/members.ts`: admin member-directory deployment adapter.
- `tsconfig.server.json`: server/API typecheck scope.
- `vercel.json`: Vite SPA rewrite for supported same-origin serverless hosting.

## Checks

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
```

The TASK-AUTH-002 GitHub Actions attempt did not run any command because GitHub blocked runner allocation for account billing/spending limits. Do not record that as a code-test failure.
