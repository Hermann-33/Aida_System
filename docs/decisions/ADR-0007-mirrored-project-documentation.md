# ADR-0007: Mirrored project governance documentation

- **Status:** Accepted
- **Date:** 2026-08-12
- **Supersedes:** none

## Context

Codex works on AIDA as one project while source lives in two directories/repositories. If architecture, backend status, decisions or integration assumptions exist only in one repo or in chat, an agent opened in the other directory can make locally reasonable but system-invalid changes.

## Decision

The canonical project governance paths listed in `docs/README.md` are mirrored in both repositories and contain full context for both applications and the shared backend.

A project-level documentation change is applied to both repos as part of the same bounded task. After synchronization, canonical shared files should be byte-for-byte equivalent.

Repository-local screenshots, generated evidence, design specs and source-specific QA artifacts are exempt and may remain different.

## Workflow consequence

- Shared-doc drift makes a material cross-system task `PARTIAL`.
- Cross-repo tasks use the same task ID and preferably the same branch name in each affected repo.
- `ACTIVE_CONTEXT`, `HANDOFF` and `AUDIT_LOG` describe both repositories, not the current checkout only.
- Accepted ADR history is copied to both repos so either checkout can reconstruct decisions.

## Rationale

Duplication is deliberate here: availability and agent context are more important than eliminating a small Markdown duplication cost. Drift is controlled by the workflow rather than by assuming the other checkout is always present.