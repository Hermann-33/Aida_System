# Codex / Independent Audit Workflow

Updated: 2026-09-16

## Two-repository rule

AIDA spans two repositories:

```text
Aida_System             — customer app, backend contracts, canonical Supabase migrations, customer tests
Aida_System-Dashboard   — Dashboard, Admin, POS, same-origin BFF, Dashboard tests
```

Any independent/Astra/Codex audit must inspect both repositories. When audit prompts are prepared, produce one prompt per repository unless the owner explicitly requests a combined prompt.

## Owner-approved audit timing

On 2026-09-16 the owner changed the audit sequence. Separate independent audits no longer block the transitions Phase 8 -> Phase 9 or Phase 9 -> Phase 10.

Required sequence:

```text
Phase 8 implementation + normal validation + docs
 -> Phase 9 implementation + normal validation + docs
 -> Phase 10 implementation + normal validation + docs
 -> one cumulative Phase 1–10 independent/Astra/Codex audit
 -> remediation + affected revalidation
 -> final cumulative closure
```

This defers only the separate independent audit. It does **not** defer clean migration replay, SQL regressions, contention/idempotency tests, Flutter tests/release builds, Dashboard lint/typecheck/unit/E2E/build, live Supabase migration verification/advisors, App Store checks, or documentation parity.

## Audit behavior

The cumulative audit is read-only unless the owner explicitly requests remediation. Audit agents must not modify code, migrations, tests, docs, PR state or live Supabase state while auditing.

The app/backend audit should focus on customer Flutter behavior, canonical migrations, database/RPC/RLS/security boundaries, payment/refund authority, privacy/account deletion, release behavior and App Store implications.

The Dashboard audit should focus on Admin/POS behavior, same-origin BFF security, HttpOnly employee/terminal credentials, caller-JWT forwarding, payment/refund/reporting surfaces, live-vs-preview isolation and Dashboard E2E/build evidence.

Cross-repository findings are reconciled after both reports are available.

Use project verdict vocabulary for formal audit/closure results:

- `COMPLETE`
- `PARTIAL`
- `FAIL`

Audit success never authorizes PR merge.
