# AIDA Café Project Memory

## Purpose

The repositories should contain enough durable context for a fresh coding agent to continue AIDA work without relying on one conversation.

## Source-of-truth hierarchy

1. Accepted ADRs.
2. Current repository implementation and live infrastructure evidence.
3. `docs/context/ACTIVE_CONTEXT.md`.
4. `docs/context/ARCHITECTURE.md`.
5. `docs/context/SYSTEM_MAP.md`.
6. `docs/context/SUPABASE_STATUS.md`.
7. `docs/contracts/SHARED_BACKEND_CONTRACT.md`.
8. `docs/context/PROJECT_BRIEF.md`.
9. `docs/context/CODEBASE_MAP.md`.
10. `docs/context/ROADMAP.md`.
11. Current bounded task instruction.
12. Historical change records and Git history.
13. Conversation memory for convenience only.

When a task depends on live Supabase state, current live evidence outranks stale migration assumptions.

## Memory layers

- `AGENTS.md` — always-on project rules.
- `docs/ai/BOOTSTRAP.md` — fresh-session reconstruction sequence.
- `docs/ai/context/CURRENT_STATE.md` — concise present-tense project map.
- `docs/ai/CONTEXT_MANIFEST.yaml` — routes task classes to docs/prompts.
- `docs/ai/prompts/**` — reusable task contracts.
- `docs/ai/playbooks/**` — repeatable process.
- `docs/context/AUDIT_LOG.md` — chronological project evidence.
- Git history — proof of what actually changed.

## Mirroring rule

Project-level governance context is mirrored across both source repositories. A shared fact should not exist in only one checkout.

Repository-local generated evidence may differ, but architecture, backend contract, security, current-state and agent-bootstrap rules must remain synchronized.

## Durable promotion

Promote a fact into durable context only when a future agent should rely on it. Do not promote guesses, temporary experiments, demo behavior, or undeployed draft SQL into current production truth.

Files under `supabase/drafts/` are preserved future work, not applied backend state.
