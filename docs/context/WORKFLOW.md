# Repository Workflow

## Task startup

1. Read root `AGENTS.md` and its mandatory documents.
2. Inspect `git status`, branch, recent history, and relevant files before planning.
3. State scope, non-goals, files/boundaries, expected checks, and database/security impact.
4. Identify whether the task is documentation, diagnosis, frontend behavior, database, security, or cross-stack work.
5. Confirm unknowns only when they materially change the solution; otherwise proceed with labeled assumptions.

## Mandatory reads

Always read `ACTIVE_CONTEXT.md`, `PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `SUPABASE_STATUS.md`, `CODEBASE_MAP.md`, `ROADMAP.md`, `WORKFLOW.md`, `HANDOFF.md`, and relevant ADRs. Read feature specs, models, providers, repositories, screens, tests, and migrations relevant to the task.

## Conflict handling

Apply the authority order in `AGENTS.md`. Do not silently reconcile a conflict. Record:

- the conflicting statements and evidence paths;
- the higher-authority source;
- the practical effect on scope;
- whether an ADR or owner decision is required.

Historical PRD statements do not establish current code or infrastructure state.

## Task scoping

- Keep one outcome per task where practical.
- Declare UI-only versus full-stack intent explicitly.
- Do not expand a customer task into POS/admin/backend work without authority.
- For database work, identify schema workflow, migrations, RLS, test data, rollback, and affected clients before editing.
- Preserve existing user changes and unrelated files.

## Implementation rules

- Inspect first; implement against current evidence.
- Keep business authority on the trusted server/database boundary.
- Frontend code may format and stage intent, but must not authorize roles, trust QR payloads, or finalize price/loyalty/order outcomes.
- Use repository/service ports for external behavior and typed success/failure results.
- Keep secrets out of clients and source control.
- Do not add dependencies without a demonstrated need and lockfile review.
- Do not hide placeholders behind production-sounding completion claims.

## Tests and checks

Choose checks proportionate to the change and run repository-discovered commands. Typical customer-app checks:

```powershell
cd apps/customer
flutter analyze
flutter test
```

During scoped audits, `--no-pub` may be used to prevent dependency changes. Do not run `dart fix --apply`, `flutter test --update-goldens`, migrations, destructive database commands, or deploys unless the task explicitly authorizes them. Record commands, versions, exit status, failures, and skipped checks.

## Audit rules

- Every material claim must point to inspected code, config, test, spec, migration, tool output, or clearly labeled owner context.
- Separate verified fact, assumption, plan, and unknown.
- Search for mocks, hardcoded values, session state, placeholders, secret/config files, integration clients, and unimplemented actions.
- Treat comments/specs as intent; verify implementation separately.
- Do not equate passing UI tests with production readiness.

## Documentation updates

- Update active context and handoff after material work.
- Append audits to `AUDIT_LOG.md`.
- Update the codebase map for structural changes.
- Update Supabase status only from verified repository/database evidence.
- Update roadmap phase status only when completion criteria are met.
- Add/update ADRs when a durable decision changes; never rewrite accepted history without superseding it.

## ADR triggers

Create an ADR when a decision is cross-cutting, durable, security-relevant, expensive to reverse, or changes an accepted boundary. Examples: runtime/app split, persistence platform, auth/session model, money/quote authority, QR trust model, migration workflow, offline cache, or role architecture.

Do not create an ADR for styling tweaks, routine implementation details, or unconfirmed ideas.

## Completion verdicts

- `COMPLETE`: every scoped outcome and applicable gate is verified; docs/handoff updated; no known required work remains.
- `PARTIAL`: useful work is complete but a stated blocker, failed gate, missing area, or external dependency prevents full completion.
- `FAIL`: the requested outcome was not achieved or verification shows it is unsafe/incorrect.

UI-only work may be complete as a UI task, but must not be called a complete product feature when service, persistence, security, or operations remain absent.

## Handoff format

Every final handoff should state:

1. Verdict.
2. Scope and starting state.
3. Files created/modified/removed.
4. Behavior and data/infrastructure changes.
5. Key findings or implementation outcome.
6. Checks and exact results.
7. Branch and Git status.
8. Assumptions, unknowns, and risks.
9. Exact next action.
10. Commit/push/deploy status.
