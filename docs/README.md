# AIDA Café Documentation Model

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

## Repository-local evidence

Source-specific evidence may differ and is not part of the mirror requirement. Examples include customer design specs/screenshots, dashboard screenshots/closure evidence, generated reports, and root import audits.

## Drift rule

A task that changes a project-level fact must update the shared documentation copies in both repositories. If the canonical files differ after a cross-system task, the documentation gate is `PARTIAL` until reconciled.

## Why both repos contain both contexts

Codex may work with both directories open in one project. Each repository must therefore be independently understandable if only one checkout is available. No critical architecture, backend, security, decision, status, or integration assumption should exist only in chat or only in the other repository.