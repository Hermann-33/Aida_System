# AIDA Café Documentation Model

Updated: 2026-08-12

AIDA Café uses mirrored project-level documentation because the customer app and POS/Admin dashboard are separate repositories over one shared backend.

## Canonical mirrored governance set

The following paths are intended to be byte-for-byte equivalent in both repositories after a documentation-sync task:

- root `AGENTS.md`
- `docs/README.md`
- `docs/context/`
- `docs/decisions/`
- `docs/contracts/`
- `docs/frontend/` — customer-app context, regardless of which repo copy is being read
- `docs/dashboard/` — POS/Admin context, regardless of which repo copy is being read
- `docs/database/`
- `docs/security/`

`docs/context/SESSION_BOOTSTRAP.md` contains the permanent prompt for starting a new ChatGPT/Codex session. Its purpose is to direct the agent back to the repository-resident source of truth rather than restating the entire project from chat memory.

## Repository-local evidence

Source-specific evidence may differ and is not part of the mirror requirement. Examples include customer design specs/screenshots, dashboard screenshots/closure evidence, generated reports, and root import audits.

## Drift rule

A task that changes a project-level fact must update the shared documentation copies in both repositories. If the canonical files differ after a cross-system task, the documentation gate is `PARTIAL` until reconciled.

## Why both repos contain both contexts

Codex may work with both directories open in one project. Each repository must therefore be independently understandable if only one checkout is available. No critical architecture, backend, security, decision, status, or integration assumption should exist only in chat or only in the other repository.

## Setup closeout

The initial AIDA project setup/governance phase is complete on the current task branches:

- customer frontend audit and governance baseline;
- POS/Admin source import and audit;
- Supabase identity/membership foundation;
- dual-repository/shared-backend architecture;
- mirrored context, ADRs, security review, backend contract and handoff;
- permanent new-session bootstrap prompt.

The open stacked PRs still need to be merged in their documented dependency order. After that, future implementation work should start from updated default branches and use the same bounded-task/branch/documentation discipline.
