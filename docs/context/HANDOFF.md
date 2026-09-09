# Current Handoff

Updated: 2026-09-10

## Task

`TASK-DOC-SYNC-001 — cross-repository governance synchronization and durable agent prompts`

**Verdict:** PARTIAL — the documentation work is committed on matching task branches in both repositories; default branches are not yet updated.

Matching branches:

`codex/task-doc-sync-001-ai-context`

Repositories:

- `Hermann-33/Aida_System`
- `Hermann-33/Aida_System-Dashboard`

## Starting default-branch state

Customer `master`:

`5dac63de972d9a0761bc817c4ae9ad5079d9385c`

This includes merged PR #19 / `TASK-UI-REDESIGN-004`.

Dashboard `main`:

`b8e4b11dbc093106d4f62383dbb0d13ba85001b8`

This includes the validated Dashboard/POS/Admin menu-customization integration.

## What changed

### Cross-repository documentation reconciliation

Customer-side project/frontend changes that existed only in the customer repository after PR #19 were mirrored into the Dashboard documentation copy, including:

- current Active Context;
- Audit Log;
- backend draft notes;
- Codebase Map;
- Handoff;
- Supabase Status;
- Security Review;
- customer fragile boundaries;
- iOS toolchain draft;
- 2026-09-09 UI redesign audit;
- current UI redesign spec;
- customer UI screen map.

No Dashboard runtime code or Supabase live state was changed by this task.

### Durable AI context

Both repositories now contain the same `docs/ai/` structure:

```text
docs/ai/
  README.md
  BOOTSTRAP.md
  PROJECT_MEMORY.md
  CONTEXT_MANIFEST.yaml
  context/
    CURRENT_STATE.md
  playbooks/
    CONTEXT_UPDATE_PROTOCOL.md
  prompts/
    README.md
    FRESH_CHAT_BOOTSTRAP.md
    CUSTOMER_APP_TASK.md
    DASHBOARD_TASK.md
    SHARED_BACKEND_TASK.md
    CROSS_REPO_TASK.md
    RELEASE_AUDIT.md
    DOCUMENTATION_SYNC.md
```

The structure is modeled after the durable context/prompt system in `Hermann-33/Cheaters-Market-Docs/docs/ai/`.

### Existing bootstrap integration

Mirrored updates were made to:

- root `AGENTS.md`;
- `docs/README.md`;
- `docs/context/SESSION_BOOTSTRAP.md`;
- `docs/context/WORKFLOW.md`.

The canonical permanent fresh-agent prompt is now:

`docs/ai/prompts/FRESH_CHAT_BOOTSTRAP.md`

The legacy Session Bootstrap is a compatibility pointer.

## Current product truth preserved

- PR #19 customer redesign is merged.
- Demo-only order/status/test work is absent.
- Account-deletion/referral work remains preserved but dormant.
- Draft SQL remains outside canonical migrations.
- Production order/pricing/status authority remains Supabase/server-owned.
- Dashboard and customer continue to share the same catalogue/order contract.
- Payment remains Pay at counter / unpaid.

## Verification for this documentation task

Completed:

- mirrored `docs/context/`, `docs/contracts/`, `docs/frontend/`, `docs/dashboard/`, `docs/decisions/`, `docs/database/`, `docs/security/` file presence/content hashes compared across the two task branches: **0 differences**;
- mirrored `docs/ai/`, `docs/ai/context/`, `docs/ai/playbooks/`, `docs/ai/prompts/`, root `AGENTS.md` and `docs/README.md` hashes compared: **0 differences**;
- customer task branch compared with `master`: documentation/AGENTS changes only, **0 runtime files** and **0 canonical Supabase migrations**;
- Dashboard task branch compared with `main`: documentation/AGENTS changes only, **0 runtime files** and **0 canonical Supabase migrations**;
- both task branches are based on the current default heads used for this sync and were **0 behind** at verification time.

No Flutter, Dashboard runtime, or SQL execution was required because final diff inspection confirmed this task is documentation-only.

## Next action

Merge the two matching documentation branches together so default branches receive the same governance/AI-context state.

Do not merge only one repository and leave the other copy stale.
