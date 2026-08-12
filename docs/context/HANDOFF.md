# Current Handoff

Updated: 2026-08-12

## Current task

`TASK-WF-003: Establish synchronized dual-repository AIDA project context and governance documentation.`

## Starting state

- Customer governance existed only in `Hermann-33/Aida_System` and described POS/Admin as absent.
- Customer DB foundation branch `codex/task-db-001-supabase-foundation` contains the first real Supabase migrations.
- Dashboard source was imported to `Hermann-33/Aida_System-Dashboard`; task branch `codex/task-wf-002-dashboard-import` contains a 299-line import audit.
- Both applications are still frontend previews and neither is connected to Supabase.

## WF-003 outcome

- Created `codex/task-wf-003-cross-repo-context-sync` in both repos, stacked on the latest relevant task branch.
- Established one project topology: customer repo + dashboard repo + shared Supabase.
- Added project-wide architecture/system map, cross-repo workflow and shared backend contract.
- Added dashboard audit/screen/data/mock/backend/fragility docs to the mirrored governance set.
- Preserved customer frontend docs and database decision history.
- Defined canonical database migration ownership in `Aida_System/supabase/` until superseded.
- Defined mirrored-doc governance: canonical project docs must remain synchronized; source-specific screenshots/specs are exempt.
- Added ADR-0006 and ADR-0007 for the cross-repo/backend and documentation decisions.

## Behavior/data/infrastructure changes

None in WF-003. No customer or dashboard runtime code, dependencies, Supabase objects, migrations, policies, buckets or environment values are changed by this task.

## Pre-existing implementation state

Supabase currently has `user_profiles`, `members`, `student_verifications` and associated enums/functions/RLS from TASK-DB-001. Security advisor was 0 lints after hardening.

Dashboard import checks passed lint (with 5 warnings), typecheck, 62 tests, build and 6/6 preview E2E; API E2E remains blocked by missing backend. Customer baseline still has one analyzer warning and four golden failures.

## Branch/PR dependency order

1. Dashboard `TASK-WF-002` import PR -> `main`.
2. Customer `TASK-DB-001` PR -> `master`.
3. WF-003 customer documentation PR, stacked on DB-001.
4. WF-003 dashboard documentation PR, stacked on WF-002.

After predecessor merges, retarget/rebase as needed without rewriting accepted task evidence.

## Exact next action

Review and merge the predecessor and WF-003 PRs in dependency order. Then begin `TASK-DB-002` from updated default branches, using both client requirement docs before designing the catalogue schema.

## Known risks

- Both clients currently calculate or simulate sensitive outcomes locally.
- Dashboard dependency audit has unresolved 1 moderate / 4 high findings.
- Customer analyzer/golden issues remain.
- Seeded cross-user/staff/admin RLS tests still need local/CI execution.
- Payment, staff/terminal role model, inventory and retention rules remain undecided.