# AIDA Café Project Instructions

AIDA Café is one product implemented across two source repositories and one shared Supabase backend. These instructions are project-wide and are mirrored in both repositories.

## Project topology

- Customer app: `Hermann-33/Aida_System` — Flutter/Dart, default branch `master`.
- POS/Admin dashboard: `Hermann-33/Aida_System-Dashboard` — React/TypeScript/Vite, default branch `main`.
- Shared backend: Supabase project **Aida System**, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`.
- Canonical database migration workspace, until superseded by ADR: `Hermann-33/Aida_System/supabase/`.

Neither frontend owns business truth. Both clients consume the same backend contract.

## New-session bootstrap

AIDA now uses the durable agent-context model under `docs/ai/`, following the same pattern used by the Cheaters Market documentation project.

For a fresh ChatGPT/Codex/Claude/Astra session:

1. Read `docs/ai/BOOTSTRAP.md`.
2. Read `docs/ai/context/CURRENT_STATE.md`.
3. Read `docs/ai/CONTEXT_MANIFEST.yaml`.
4. Use `docs/ai/prompts/FRESH_CHAT_BOOTSTRAP.md` as the permanent copy/paste context prompt.
5. Load only the task-specific prompt/playbook needed after that.

`docs/context/SESSION_BOOTSTRAP.md` remains as a compatibility entry point and points to the canonical `docs/ai/` material.

Do not rely on prior chat history as durable project memory.

## Mandatory reads before implementation

Read in this order:

1. `docs/ai/context/CURRENT_STATE.md`
2. `docs/context/ACTIVE_CONTEXT.md`
3. `docs/context/PROJECT_BRIEF.md`
4. `docs/context/ARCHITECTURE.md`
5. `docs/context/SYSTEM_MAP.md`
6. `docs/context/SUPABASE_STATUS.md`
7. `docs/contracts/SHARED_BACKEND_CONTRACT.md`
8. `docs/context/CODEBASE_MAP.md`
9. `docs/context/ROADMAP.md`
10. `docs/context/WORKFLOW.md`
11. `docs/context/HANDOFF.md`
12. Relevant `docs/decisions/ADR-*.md`
13. Relevant customer docs under `docs/frontend/` and dashboard docs under `docs/dashboard/`.
14. `docs/security/SECURITY_REVIEW.md` when security, authorization, trusted data, payments, loyalty, inventory, staff or audit boundaries are affected.

## Authority order

When sources conflict:

1. Accepted ADRs
2. `ACTIVE_CONTEXT.md`
3. `ARCHITECTURE.md`
4. `SYSTEM_MAP.md`
5. `SUPABASE_STATUS.md`
6. `SHARED_BACKEND_CONTRACT.md`
7. `PROJECT_BRIEF.md`
8. `CODEBASE_MAP.md`
9. `ROADMAP.md`
10. Current bounded task instruction
11. Chat history

Historical PRD/spec/status claims are evidence and requirements inputs, not proof of current code or infrastructure.

## Before changing anything

Provide a short pre-change summary covering scope, non-goals, affected repository/repositories, likely files and runtime boundaries, current evidence, checks, database/security impact, and unresolved assumptions.

If a shared concept changes—identity, member code, roles, branch scope, menu IDs, prices, modifiers, orders, payments, loyalty, vouchers, inventory, marketing, reporting, audit, realtime, or migrations—inspect both client repositories before implementation.

## Cross-repository rules

- One bounded task ID per outcome.
- Create a dedicated branch in every affected repository. Use the same task ID/slug when the task spans both repos.
- Do not implement directly on `master` or `main`.
- Keep customer-only, dashboard-only, and backend changes separated unless the task explicitly requires coordinated cross-stack work.
- Database migrations are canonical in `Aida_System/supabase/`; do not create a second independent migration history in the dashboard repository.
- Shared contract changes require compatibility review for both clients before completion.
- Project-level governance docs are mirrored in both repos. A material task is not complete if the shared copies drift.
- Repository-local screenshots, generated evidence, design specs, and source-specific QA artifacts may differ; they are not part of the mirrored governance set.

## Trust boundaries

Never treat client-computed or preview values as authority for:

- identity, roles, branch/location scope, verification, terminal credentials or manager approval;
- member codes, QR possession, voucher validity or reward eligibility;
- catalogue prices, modifier compatibility, discounts, taxes/fees or totals;
- order/receipt identifiers, payment state, status transitions or refunds;
- points, stamps, ledgers, inventory, marketing publication, reporting or audit facts.

The trusted Supabase/server boundary must validate and persist those outcomes.

## Protected customer boundaries

Do not casually change `apps/customer/lib/application/providers.dart`, `member_repository.dart`, `mock_member_repository.dart`, auth/navigation lifecycle, money/cart models, QR semantics, or golden baselines. Do not update goldens merely to make tests green.

## Protected dashboard boundaries

Do not casually change employee/session adapters, `ProtectedRoute`, terminal enrolment/credential semantics, POS pricing/cart/payment flow, manager approval, branch scope, preview/live gates, or admin mutation boundaries. Preview fixtures must not become production defaults.

## Security rules

- Never commit secrets, service-role keys, access tokens, private database URLs, employee PINs/passwords, terminal credentials, payment secrets or private certificates.
- Public clients receive only approved public/publishable configuration.
- RLS is mandatory on exposed tables; authentication alone is not authorization.
- User-editable metadata cannot grant staff/admin/owner roles or student verification.
- Privileged operations require explicit trusted authorization, idempotency where relevant, and audit.
- QR/member code is an identifier, not authentication.

## Completion gate

Use only `COMPLETE`, `PARTIAL`, or `FAIL`.

Where applicable, completion requires UI/client behavior, service/adapter contract, authoritative persistence/business rules, authentication/authorization/RLS, abuse and failure handling, operations/fulfilment, tests, and synchronized documentation. A polished preview is not a complete feature.

## Documentation updates

After material work update `ACTIVE_CONTEXT.md`, `HANDOFF.md`, and `AUDIT_LOG.md`; update architecture, system map, Supabase status, contract, codebase map, roadmap, security review or ADRs when their facts change. Run `docs/ai/playbooks/CONTEXT_UPDATE_PROTOCOL.md` when durable agent context changes. Shared governance updates, including `docs/ai/**`, must be applied to both repositories in the same task.
