# Active Context

**As of:** 2026-08-12
**Current task:** `TASK-WF-003` — synchronized dual-repository project context and governance

## Repository state

### Customer

- Repo: `Hermann-33/Aida_System`
- Default branch: `master`
- Latest implementation baseline branch: `codex/task-db-001-supabase-foundation`
- Current documentation branch: `codex/task-wf-003-cross-repo-context-sync`
- Scrap branch `team1/aida-pos-admin-ui` is explicitly ignored.

### Dashboard

- Repo: `Hermann-33/Aida_System-Dashboard`
- Default branch: `main`
- Imported/audited baseline branch: `codex/task-wf-002-dashboard-import`
- Current documentation branch: `codex/task-wf-003-cross-repo-context-sync`

## Current runtime reality

- Customer: Flutter/Dart + Material 3 + Riverpod. `MockMemberRepository` remains the active adapter; auth, cart, favourites, profile edits and order history are local/session simulation.
- Dashboard: React 19 + TypeScript 6 + Vite 8 + React Router. Employee, POS and admin surfaces are broad but use preview fixtures, React/module state and session storage. TanStack Query is configured but not currently the live data layer.
- Neither frontend currently connects to Supabase.

## Shared Supabase reality

Project: **Aida System** (`eswovqxqzfevcdwwcmuh`, `ap-southeast-1`).

`TASK-DB-001` created and remotely applied:

- `public.user_profiles`
- `public.members`
- `public.student_verifications`
- enums `app_user_role`, `member_type`, `student_verification_status`
- auth provisioning trigger and helper functions
- forced RLS on the three foundation tables

Security advisor after hardening: 0 lints. Performance advisor has only expected unused-index INFO findings on the no-traffic foundation.

Canonical migration workspace is currently `Aida_System/supabase/`.

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

## Immediate priorities

1. Merge task dependencies in order: dashboard import PR, customer DB foundation PR, then the two stacked WF-003 documentation PRs.
2. Run local Supabase reset/lint/RLS scenarios from a developer checkout.
3. Begin `TASK-DB-002` only after using both customer and dashboard catalogue requirements to define the shared menu contract.
4. Keep frontend wiring out of the menu-foundation task unless explicitly expanded.
5. Track customer analyzer/golden cleanup and dashboard dependency findings as separate bounded work.

## Open decisions

- Final payment/provider/device model, including student wallet semantics.
- Scheduled-order rules and capacity/cutoff behavior.
- Staff/admin role assignment, manager approval and branch-scope administration.
- Terminal credential lifecycle and production employee authentication method.
- Full student-verification review/evidence policy.
- Inventory accounting/depletion model.
- Account deletion/anonymization and retention.
- Production reporting/business-day semantics and marketing approval workflow.

## Scope protection

Do not claim either frontend is backend-connected. Do not treat preview fixture IDs, branch IDs, prices, receipt/order numbers, rewards, payments, manager approvals, inventory or report totals as production truth. Do not create a second database migration history in the dashboard repo.