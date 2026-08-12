# AIDA Café Session Bootstrap

Updated: 2026-08-12

Use this file when starting a new ChatGPT/Codex session. The repository documentation is the durable source of truth; chat history is not.

## Constant new-chat prompt

```text
You are working on the AIDA Café project.

AIDA Café is one product implemented across two repositories and one shared Supabase backend:

1. Customer app
   GitHub: https://github.com/Hermann-33/Aida_System
   Runtime: Flutter / Dart / Riverpod
   Default branch: master

2. POS + Admin dashboard
   GitHub: https://github.com/Hermann-33/Aida_System-Dashboard
   Runtime: React / TypeScript / Vite
   Default branch: main

3. Shared backend
   Supabase project: Aida System
   Project ref: eswovqxqzfevcdwwcmuh
   Region: ap-southeast-1

Both frontends use the same backend and must remain contract-compatible. Neither frontend is authoritative for identity, roles, branch scope, catalogue pricing, order state, payment state, loyalty, vouchers, inventory, reporting, audit, or other trusted business outcomes.

Before doing any implementation:

1. Inspect the current Git state/branches/PRs for both repositories relevant to the task.
2. Read AGENTS.md.
3. Read these mirrored project docs in order:
   - docs/context/ACTIVE_CONTEXT.md
   - docs/context/PROJECT_BRIEF.md
   - docs/context/ARCHITECTURE.md
   - docs/context/SYSTEM_MAP.md
   - docs/context/SUPABASE_STATUS.md
   - docs/contracts/SHARED_BACKEND_CONTRACT.md
   - docs/context/CODEBASE_MAP.md
   - docs/context/ROADMAP.md
   - docs/context/WORKFLOW.md
   - docs/context/HANDOFF.md
   - relevant docs/decisions/ADR-*.md
   - relevant customer docs under docs/frontend/
   - relevant dashboard docs under docs/dashboard/
   - docs/security/SECURITY_REVIEW.md when security or trusted data is affected
4. Treat accepted ADRs and current repository evidence as higher authority than chat history or old PRD status claims.
5. If Supabase state matters and a Supabase connection is available, verify the live state before changing it. Never infer live database state only from old chat.
6. Work in a dedicated branch for every bounded task. Do not implement directly on master/main.
7. If a task affects both repos, use the same task ID/branch slug in both repos and review both clients before changing the shared contract.
8. Canonical executable Supabase migrations currently live only in Hermann-33/Aida_System/supabase/. Do not create a second migration history in the dashboard repo unless a later ADR explicitly changes ownership.
9. Keep the mirrored governance documentation synchronized in both repositories whenever a project-level fact changes.
10. Never commit secrets, service-role keys, access tokens, employee PINs/passwords, terminal credentials, payment secrets, or private certificates.
11. Do not trust client-calculated prices/totals, generated order/member IDs, QR possession, loyalty balances, reward eligibility, payment simulation, manager approval, inventory values, or preview report totals as production truth.
12. Use COMPLETE / PARTIAL / FAIL exactly as defined by the project completion gate. A polished UI or preview is not full-stack completion.

Before making changes, give me a short pre-change summary containing:
- task scope;
- explicit non-goals;
- repositories and files likely to change;
- current implementation evidence;
- tests/checks you will run;
- Supabase/database/security impact;
- unresolved assumptions that actually require confirmation.

Then proceed with the task without asking questions that the repository, connected GitHub data, or Supabase state can answer.

At task completion:
- run relevant checks;
- inspect the final diff/status;
- update ACTIVE_CONTEXT.md, HANDOFF.md and AUDIT_LOG.md;
- update other shared docs/ADRs when their facts changed;
- synchronize the mirrored docs to both repos for project-level changes;
- commit and push only when the task instruction authorizes it;
- report branch, commit/PR, files changed, verification results, remaining risks, and exact next task.
```

## Stable project rules

- Two source repositories, one backend contract.
- Supabase is the authoritative persistence/security boundary.
- `Hermann-33/Aida_System/supabase/` is the canonical migration workspace until superseded by ADR.
- Project-level governance documentation is mirrored across both repos.
- Repository-local screenshots/specs/generated evidence may differ.
- Shared identifiers and lifecycle semantics must be compatible across customer, POS and admin workflows.
- Client previews are requirements evidence, not database authority.

## Current setup closeout

The setup/governance phase is complete on its task branches. The repositories now contain customer context, dashboard context, shared architecture, database foundation status, security rules, ADR history, shared contract, workflow and handoff material. Open stacked PRs must still be merged in their documented dependency order before future work should branch from the default branches.

The recommended next implementation task after the setup PR stack is merged is `TASK-DB-002: shared menu/catalogue foundation`.
