# Active Context

**As of:** 2026-08-12
**Setup status:** COMPLETE on task branches; merge stack pending
**Next implementation task:** `TASK-DB-002 — shared menu/catalogue foundation`

## Project topology

### Customer application

- Repo: `Hermann-33/Aida_System`
- Default branch: `master`
- Runtime: Flutter / Dart / Material 3 / Riverpod
- Current integration state: frontend prototype; `MockMemberRepository` is still active and no Flutter Supabase client is wired.
- Canonical Supabase migration workspace: `supabase/` in this repository.

### POS/Admin dashboard

- Repo: `Hermann-33/Aida_System-Dashboard`
- Default branch: `main`
- Runtime: React 19 / TypeScript 6 / Vite 8 / React Router
- Current integration state: broad employee/POS/admin frontend preview using fixtures, component/module state and session storage; no Supabase SDK or durable transactional backend is wired.

### Shared backend

- Platform: Supabase
- Project: **Aida System**
- Ref: `eswovqxqzfevcdwwcmuh`
- Region: `ap-southeast-1`

Both frontends are consumers of one backend contract. Neither frontend is authoritative for identity, roles, branch scope, member verification, catalogue pricing, order/payment state, loyalty, inventory, reporting, audit or other trusted business outcomes.

## Completed setup tasks

- `TASK-WF-001` — customer frontend audit and repository governance baseline.
- `TASK-DB-001` — version-controlled Supabase identity/membership foundation.
- `TASK-WF-002` — POS/Admin dashboard source import and audit.
- `TASK-WF-003` — synchronized dual-repository context, ADRs, security review, shared backend contract, workflow and handoff.
- `TASK-WF-003` closeout — permanent `SESSION_BOOTSTRAP.md` added so new chats can recover project context from repository truth.

## Supabase implementation reality

`TASK-DB-001` created and remotely applied:

- `public.user_profiles`
- `public.members`
- `public.student_verifications`
- enums `app_user_role`, `member_type`, `student_verification_status`
- Auth provisioning trigger and supporting functions
- forced RLS on all three foundation tables
- private trusted role helpers

Security advisor after hardening: 0 lints. Performance advisor had only expected unused-index INFO findings on the new no-traffic schema.

No catalogue, quote/order, payment, loyalty, inventory, marketing/reporting or POS operational persistence exists yet.

## Documentation state

Project-level governance is mirrored across both repositories. The canonical mirrored set includes:

- root `AGENTS.md`
- `docs/README.md`
- `docs/context/`
- `docs/decisions/`
- `docs/contracts/`
- `docs/frontend/`
- `docs/dashboard/`
- `docs/database/`
- `docs/security/`

Repository-local screenshots, old design specs, generated evidence and import/audit artifacts may differ.

`docs/context/SESSION_BOOTSTRAP.md` contains the permanent new-chat prompt.

## Open PR stack

Merge in this dependency order:

1. Dashboard PR #1 — `TASK-WF-002` dashboard import -> `main`.
2. Customer PR #2 — `TASK-DB-001` Supabase foundation -> `master`.
3. Customer PR #3 — `TASK-WF-003` synchronized project docs, stacked on DB-001.
4. Dashboard PR #2 — `TASK-WF-003` synchronized project docs, stacked on WF-002.

After predecessor merges, retarget/rebase the stacked WF-003 PRs if GitHub does not resolve the base automatically. Future implementation work should branch from the updated default branches only after this stack is integrated.

## Verification baselines

Customer audit baseline:

- Flutter 3.44.7 / Dart 3.12.2.
- `flutter analyze --no-pub`: one unused `_stockChocolate` warning.
- Non-golden tests: 24/24 passed.
- Full test run: four golden comparison failures.

Dashboard import baseline:

- `npm run lint`: passed with 5 warnings.
- `npm run typecheck`: passed.
- `npm test`: 14 files / 62 tests passed.
- `npm run build`: passed with bundle-size warning.
- Preview E2E: 6/6 passed.
- API-backed E2E: not run because backend environment is unavailable.
- Dependency audit: 1 moderate and 4 high findings; no automated upgrades applied.

## Open architectural/product decisions

- Final payment/provider/device model, including student-wallet semantics.
- Scheduled-order rules, capacity and cutoff behavior.
- Staff/admin role assignment, manager approval and branch-scope administration.
- Terminal credential lifecycle and production employee authentication method.
- Full student-verification evidence/review policy.
- Inventory accounting and depletion model.
- Account deletion/anonymization and retention.
- Production reporting/business-day semantics and marketing approval workflow.

## Next action after setup merge

Start `TASK-DB-002: shared menu/catalogue foundation` only after reading both customer and dashboard backend-integration docs and the shared backend contract. Do not mechanically map either preview fixture model into database tables, and do not wire either frontend in that schema-foundation task unless its scope is explicitly expanded.
