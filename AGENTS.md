# AIDA Café Repository Instructions

This repository currently contains the AIDA Café customer frontend and product documentation. Before implementation, read these files in order:

1. `docs/context/ACTIVE_CONTEXT.md`
2. `docs/context/PROJECT_BRIEF.md`
3. `docs/context/ARCHITECTURE.md`
4. `docs/context/SUPABASE_STATUS.md`
5. `docs/context/CODEBASE_MAP.md`
6. `docs/context/ROADMAP.md`
7. `docs/context/WORKFLOW.md`
8. `docs/context/HANDOFF.md`
9. Relevant `docs/decisions/ADR-*.md`

## Authority order

When sources conflict, use this order:

1. Accepted ADRs
2. `ACTIVE_CONTEXT.md`
3. `ARCHITECTURE.md`
4. `SUPABASE_STATUS.md`
5. `PROJECT_BRIEF.md`
6. `CODEBASE_MAP.md`
7. `ROADMAP.md`
8. Current task instruction
9. Chat history

Product specs and the unified PRD are evidence and requirements inputs, but their historical “Live” or “Complete” claims are not proof of the contents of this checkout or of current infrastructure.

## Before changing anything

Provide a short pre-change summary containing:

- the task scope and explicit non-goals;
- files and runtime boundaries likely to change;
- current implementation evidence;
- tests/checks to run;
- database, security, and migration impact;
- unresolved assumptions requiring confirmation.

Do not begin implementation until the relevant current-context files and ADRs have been read. If a requested change conflicts with a higher-authority source, stop and report the conflict.

## Do-not-touch boundaries

- Do not treat `MockMemberRepository` data as production data or silently convert UI calculations into business authority.
- Do not trust client-computed prices, totals, points, stamps, reward eligibility, roles, verification state, member codes, order numbers, or voucher validity.
- Do not add or infer a Supabase schema from the old PRD. The reset database has no assumed production schema until migrations in this repository prove one.
- Do not expose or commit secrets, service-role keys, access tokens, passwords, private URLs, or credentials. A public frontend may use only the approved public/publishable client configuration.
- Do not casually change `lib/application/providers.dart`, `lib/domain/repository/member_repository.dart`, money/cart models, navigation in `main.dart` and `features/shell/app_shell.dart`, or QR semantics. These are integration and trust boundaries.
- Do not add POS, staff, admin, backend, schema, or migration work to a customer-frontend task without explicit scope.
- Do not update golden baselines merely to make a failing test green; review the visual differences first.

## Completion gate

A feature is not complete because its UI exists. Where applicable, completion requires:

- customer/staff/admin UI and client state;
- service or repository integration;
- authoritative persistence and business rules;
- authentication, authorization, RLS, and abuse controls;
- success, failure, retry, and offline behavior;
- automated tests and reviewed visual changes;
- updated context, handoff, audit log, and any decision record.

Use only these verdicts: `COMPLETE`, `PARTIAL`, or `FAIL`. Never claim production readiness or full-stack completion without evidence for every applicable layer.

## Documentation updates

- Update `ACTIVE_CONTEXT.md` and `HANDOFF.md` after every material task.
- Append a dated entry to `AUDIT_LOG.md` for audits and verification baselines.
- Update `CODEBASE_MAP.md` when files, apps, routes, models, services, tests, or fragile boundaries change.
- Update `SUPABASE_STATUS.md` with each verified schema/migration/security milestone.
- Update `ROADMAP.md` only when phase status or scope changes.
- Create an ADR for a durable, cross-cutting, costly-to-reverse decision; do not use ADRs as task diaries.
- Keep current reality separate from planned architecture, and label assumptions and unknowns.

## Git discipline

- Inspect `git status` before and after work. Preserve unrelated user changes.
- Keep changes scoped; do not mix documentation, generated artifacts, dependency updates, and behavior changes without explicit approval.
- Do not commit, push, rewrite history, or update a pull request unless requested after the diff is reviewed.
- Commit lockfiles when dependencies are intentionally changed. Do not change dependencies during documentation-only tasks.
- Report the branch, changed/untracked files, checks, failures, and whether commit/push occurred.

## Security rules

- Never copy secret values into code, docs, logs, screenshots, fixtures, or chat.
- Frontends must never receive Supabase secret/service-role keys.
- Enable RLS on every exposed table and authorize by ownership or explicit operational role, not merely by an authenticated role.
- Do not use user-editable profile metadata for authorization.
- Treat QR payloads as shareable identifiers, not proof of identity or authorization.
- Validate prices, modifiers, totals, loyalty changes, voucher use, order transitions, and staff/admin actions on a trusted boundary.
