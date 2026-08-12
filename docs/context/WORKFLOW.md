# AIDA Café Cross-Repository Workflow

Updated: 2026-08-12

## Task startup

1. Read root `AGENTS.md` and mandatory shared docs.
2. Identify whether the task affects customer, dashboard, backend or multiple areas.
3. Inspect Git status/branch/history in every affected checkout.
4. Inspect current implementation evidence before planning.
5. State scope, non-goals, files/boundaries, checks, database/security impact and assumptions.

## Branch discipline

- Never implement directly on `master` or `main`.
- Use one bounded task ID and a dedicated `codex/<task-id>-<slug>` branch.
- If a task spans both repos, create the same branch name in both when practical.
- Preserve unrelated user work and ignore explicitly identified scrap branches.
- Do not rewrite history unless explicitly authorized.
- Use stacked PRs when a task depends on an unmerged predecessor; document merge order.

## Backend ownership

- Supabase is shared by both clients.
- Canonical migrations currently live in `Aida_System/supabase/`.
- Dashboard code must not start a second migration ledger.
- Before a shared-schema change, inspect both client needs and existing adapters/models.
- Applied migrations are append-only; change them with forward migrations rather than editing accepted history.

## Shared contract workflow

For changes to identities, roles, branches, member codes, catalogue IDs, price/modifier rules, orders/statuses, payments, loyalty/vouchers, inventory, marketing, reporting, audit or realtime:

1. identify both client consumers;
2. define trusted authority and invariants;
3. update migration/API/RPC contract;
4. test ownership/role/branch and abuse cases;
5. update affected adapters/UI separately or in coordinated branches;
6. update `SHARED_BACKEND_CONTRACT.md` and mirrored docs.

## Client rules

Customer Flutter may stage intent and render estimates but cannot authorize identity/value. Dashboard route guards and preview permissions are not server authorization. POS/admin privileged actions require backend role/branch checks and audit.

## Tests

Customer, proportionate to change:

```powershell
cd apps/customer
flutter analyze
flutter test
```

Do not update golden baselines without visual review and explicit scope.

Dashboard, proportionate to change:

```powershell
npm run lint
npm run typecheck
npm test
npm run build
npm run test:e2e
```

Run API-backed E2E only when its backend environment is deliberately available.

Supabase, proportionate to change:

```bash
supabase db reset
supabase db lint
```

Add seeded RLS/authorization/idempotency/concurrency tests for risky operations.

## Documentation synchronization

The canonical governance paths listed in `docs/README.md` must be mirrored in both repos. Every material task asks: did this change a shared project fact? If yes, update both copies before `COMPLETE`.

Repository-local screenshots/specs/evidence may differ.

## ADR triggers

Create a new ADR for durable/cross-cutting decisions such as repository split, backend ownership, auth/session architecture, role/branch model, money/quote authority, order lifecycle, QR trust, migration workflow, offline sync or documentation governance. Do not rewrite an accepted ADR to hide history; supersede it explicitly.

## Completion verdicts

- `COMPLETE`: scoped outcomes, applicable tests/security/docs and cross-repo sync pass.
- `PARTIAL`: useful work exists but a required gate/dependency/drift remains.
- `FAIL`: requested outcome is absent, unsafe or materially unverified.

## Handoff

Report verdict, starting state, affected repos/branches, files, behavior/data/infrastructure changes, checks, known failures, assumptions/risks, PR/commit status, merge order and exact next action.