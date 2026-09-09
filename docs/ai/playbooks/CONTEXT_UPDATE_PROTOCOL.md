# AIDA Café Context Update Protocol

Run this after a logical AIDA project change.

## Gate A — shared-fact check

Ask whether the task changed a project-level fact that a future agent must know.

Examples:

- architecture or repository ownership;
- Auth/role/security behavior;
- Supabase schema/RPC/RLS;
- shared catalogue/order/payment/loyalty contract;
- customer or Dashboard integration status;
- release/build requirements;
- accepted UI behavior that another client or backend task depends on;
- agent workflow or verification requirements.

If yes, update the mirrored durable docs in both repositories.

## Gate B — current-state update

For material work, update as applicable:

- `docs/context/ACTIVE_CONTEXT.md`
- `docs/context/HANDOFF.md`
- `docs/context/AUDIT_LOG.md`
- `docs/ai/context/CURRENT_STATE.md`

Update architecture, system map, Supabase status, contracts, codebase map, security review, frontend/dashboard boundaries, roadmap or ADRs only when their facts changed.

## Gate C — prompt/context infrastructure

If a task changes how future agents should work, update:

- `docs/ai/BOOTSTRAP.md`
- `docs/ai/CONTEXT_MANIFEST.yaml`
- relevant `docs/ai/prompts/**`
- relevant playbooks.

Do not put temporary task chronology into reusable prompts.

## Mirroring

The governance/context copies in `Aida_System` and `Aida_System-Dashboard` must agree after a cross-system task.

A documentation-sync task should compare file presence and content hashes, not rely on memory.

## Validation record

Record only checks that actually ran. Examples:

- Flutter analyze/test/goldens/build;
- Dashboard lint/typecheck/Vitest/Playwright/build;
- SQL regressions;
- migration replay;
- Supabase advisors;
- RLS/privilege checks;
- final repository diff/hash comparison.

Do not convert an unrun check into PASS.

## Final response block

Use:

Context update:
- Shared facts changed: yes/no
- Mirrored docs updated: yes/no; files:
- AI context/prompts updated: yes/no; files:
- Verification performed:
- Unknowns/limitations:
