# Current Handoff

Updated: 2026-08-12

## Setup phase status

The initial AIDA project setup/governance phase is COMPLETE and integrated into both default branches. No implementation task is currently active.

Completed setup work:

- `TASK-WF-001` — customer frontend audit and governance baseline.
- `TASK-DB-001` — Supabase identity/membership foundation with version-controlled migrations and RLS.
- `TASK-WF-002` — POS/Admin dashboard import and audit.
- `TASK-WF-003` — synchronized dual-repository project context, architecture, ADRs, security, workflow and shared backend contract.
- `TASK-WF-004` — post-merge setup finalization and permanent session bootstrap.

## Current system reality

- Customer repo: `Hermann-33/Aida_System`, default branch `master`, Flutter/Dart/Riverpod prototype, no Supabase client wiring yet.
- Dashboard repo: `Hermann-33/Aida_System-Dashboard`, default branch `main`, React/TypeScript/Vite employee/POS/admin preview, no durable backend wiring yet.
- Shared backend: Supabase **Aida System**, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`.
- Canonical executable migrations: `Hermann-33/Aida_System/supabase/` until superseded by ADR.
- Project-level governance docs are mirrored in both repositories.

## Supabase foundation currently implemented

- `public.user_profiles`
- `public.members`
- `public.student_verifications`
- trusted application-role/member/student-verification enums and helpers
- Auth provisioning trigger
- forced RLS on the three foundation tables
- hardened private role helpers
- security advisor baseline: 0 lints after hardening

No catalogue, order/payment, loyalty, inventory, marketing/reporting or POS operational persistence exists yet.

## Setup merge record

Merged successfully:

- Dashboard PR #1 — `TASK-WF-002` import.
- Customer PR #2 — `TASK-DB-001` foundation.
- Customer PR #3 — `TASK-WF-003` synchronized project context.
- Dashboard PR #2 — `TASK-WF-003` synchronized project context.

`TASK-WF-004` finalizes the default-branch wording after those merges.

## Permanent new-session entry point

Use `docs/context/SESSION_BOOTSTRAP.md`. It contains the constant prompt to paste into a new ChatGPT/Codex chat and directs the agent to read repository-resident context before making changes.

The repository docs, not prior chat history, are authoritative.

## Known outstanding technical debt

Customer baseline:

- one unused `_stockChocolate` analyzer warning;
- four golden comparison failures;
- no real auth/session/profile/menu/order/loyalty adapter yet.

Dashboard baseline:

- lint passes with 5 warnings;
- dependency audit reported 1 moderate and 4 high findings;
- API-backed E2E is blocked until a real backend environment exists;
- transaction, payment, inventory, employee/admin mutation and reporting behavior remains preview/local.

Database/testing:

- seeded customer/cross-user/staff/admin RLS scenarios still need local/CI execution;
- broader domain migrations are not implemented.

## Open product/architecture decisions

Payment/provider/device model, student wallet semantics, scheduled-order rules, employee/staff authorization model, terminal credential lifecycle, manager approval, student-verification evidence policy, inventory accounting/depletion, retention/account deletion, reporting business-day semantics and marketing approval workflow remain unresolved until bounded tasks decide them.

## Exact next implementation task

`TASK-DB-002: shared menu/catalogue foundation`

Create fresh task branches from `master` and `main` as required. Inspect customer and dashboard catalogue requirements together, define one published catalogue contract and security model, create canonical migrations only in the customer repo's `supabase/` workspace, update mirrored docs in both repos, and avoid frontend wiring unless explicitly included in scope.
