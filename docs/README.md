# AIDA Café Documentation Model

Updated: 2026-09-10

AIDA Café uses mirrored project-level documentation because the customer app and POS/Admin dashboard are separate repositories over one shared backend.

## Canonical mirrored governance set

The following paths are intended to be byte-for-byte equivalent in both repositories after a documentation-sync task:

- root `AGENTS.md`
- `docs/README.md`
- `docs/ai/`
- `docs/context/`
- `docs/decisions/`
- `docs/contracts/`
- `docs/frontend/` — customer-app context, regardless of which repo copy is being read
- `docs/dashboard/` — POS/Admin context, regardless of which repo copy is being read
- `docs/database/`
- `docs/security/`

`docs/ai/` is the canonical durable agent-context layer. `docs/ai/prompts/FRESH_CHAT_BOOTSTRAP.md` is the permanent copy/paste prompt for a fresh agent; `docs/ai/BOOTSTRAP.md`, `docs/ai/context/CURRENT_STATE.md`, and `docs/ai/CONTEXT_MANIFEST.yaml` reconstruct the project from repository-resident truth. `docs/context/SESSION_BOOTSTRAP.md` remains only as a compatibility entry point.

## Repository-local evidence

Source-specific evidence may differ and is not part of the mirror requirement. Examples include customer design specs/screenshots, dashboard screenshots/closure evidence, generated reports, and root import audits.

## Drift rule

A task that changes a project-level fact must update the shared documentation copies in both repositories. If the canonical files differ after a cross-system task, the documentation gate is `PARTIAL` until reconciled.

## Why both repos contain both contexts

Codex may work with both directories open in one project. Each repository must therefore be independently understandable if only one checkout is available. No critical architecture, backend, security, decision, status, or integration assumption should exist only in chat or only in the other repository.

## Setup closeout

The initial AIDA project setup/governance phase is complete and merged into both default branches. The integrated baseline includes:

- customer frontend audit and governance;
- POS/Admin source import and audit;
- Supabase identity/membership foundation;
- dual-repository/shared-backend architecture;
- mirrored context, ADRs, security review, backend contract and handoff;
- permanent new-session bootstrap prompt;
- mirrored `docs/ai/` project memory, reusable prompts, context manifest and update playbook.

Future implementation work should start from fresh task branches based on `master` and `main`, with project-level documentation kept mirrored as changes occur.
