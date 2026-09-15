# Codex Audit Workflow

Updated: 2026-09-15

## Two-directory rule

AIDA is implemented across two separate Codex working directories/repositories:

```text
Aida_System             — customer app, backend contracts, canonical Supabase migrations, customer tests
Aida_System-Dashboard   — Dashboard, Admin, POS, same-origin BFF, Dashboard tests
```

Whenever a Codex audit prompt is requested for any phase or combined phase boundary, **always produce two separate prompts**:

1. one prompt intended to be run from the `Aida_System` working directory;
2. one prompt intended to be run from the `Aida_System-Dashboard` working directory.

Do not give a single combined Codex prompt unless the owner explicitly asks for one. Each prompt must constrain Codex to the repository it can actually inspect while referencing cross-repository contracts only where necessary.

The app/backend prompt should focus on customer Flutter behavior, canonical Supabase migrations, database/RPC/RLS/security boundaries, clean migration replay, customer tests and App Store/privacy effects.

The Dashboard prompt should focus on React/Admin/POS behavior, same-origin BFF security, HttpOnly employee/terminal credentials, caller-JWT forwarding, live-vs-preview boundaries, Dashboard tests/E2E and shared-governance consistency.

Cross-repository findings should be reported by each agent when visible from its own repository, then reconciled after both reports are available.

## Audit behavior

Codex audits are read-only unless the owner explicitly requests remediation. Audit prompts must say not to modify code, migrations, tests, documentation, PR state or Supabase state during the audit.

Use project verdict vocabulary where a completion verdict is required:

- `COMPLETE`
- `PARTIAL`
- `FAIL`

Do not merge phase PRs merely because an audit passes.
