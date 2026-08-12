# AIDA Café Implementation Roadmap

Updated: 2026-08-12

Statuses describe verified project reality, not historical PRD deployment claims.

## Phase 1 — Governance and source baselines

- `TASK-WF-001`: customer frontend audit/governance — COMPLETE.
- `TASK-WF-002`: POS/Admin source import and audit — COMPLETE on task branch; merge pending.
- `TASK-WF-003`: mirrored dual-repository project context and shared-backend governance — COMPLETE on task branches; merge pending.
- Setup closeout: permanent session bootstrap prompt and final handoff recorded — COMPLETE on task branches.

Exit criterion has been met on the setup branches: both repositories independently describe the full system, share authority/workflow rules, contain customer and dashboard context, reference one backend contract, and include a repeatable new-session bootstrap.

Integration status: the setup PR stack still needs to be merged in the dependency order documented in `ACTIVE_CONTEXT.md` and `HANDOFF.md`.

## Phase 2 — Shared Supabase foundation

`TASK-DB-001` created the identity/profile/member/student-verification foundation with forced RLS and 0 security-advisor lints.

Still required:

- local reset/lint and seeded role/RLS scenarios;
- branches/locations/terminals/employees authorization model;
- published catalogue/modifier/storage model;
- quote/order lifecycle;
- loyalty/voucher ledger;
- inventory and audit foundations.

Status: PARTIAL.

## Phase 3 — Authentication, membership and staff access integration

Customer: Supabase Auth session bootstrap, profile/member reads/edits, server-issued member code, logout/cache isolation, recovery and verification state.

Dashboard: employee/staff/admin identity, branch scope, dual-role rules, terminal credential lifecycle, manager approval and session revocation.

Both must use trusted roles and compatible member/verification semantics.

Status: not started; UI previews exist.

## Phase 4 — Catalogue and publication

Create server-owned categories/items/variants/modifier groups/options, integer-sen prices, availability, routing metadata, publication/versioning and managed images. Customer reads published catalogue; POS uses the same IDs/prices; admin mutations are privileged and audited.

Status: not started. This is the recommended next database domain.

## Phase 5 — Quote, order, fulfilment and payment

Authoritative quote validation, idempotent order creation, pickup/scheduling rules if approved, POS/KDS fulfilment transitions, immutable receipt snapshots, payment/provider records, refunds/void/cancel controls and customer status/history.

Status: not started; both clients simulate these flows.

## Phase 6 — Loyalty, rewards, vouchers and promotions

Ledger-derived balances/stamps, reward catalogue, atomic redemption/voucher consumption, eligibility, promotions and customer/dashboard publication controls.

Status: not started; both clients contain preview values.

## Phase 7 — Operations and inventory

Branches/sales points, terminals, shifts/cash movements, employee access, stock ledger, recipes, depletion, wastage, transfers and operational audit.

Status: not started; dashboard previews exist.

## Phase 8 — Reporting, marketing, hardening and release

Trusted financial/operational aggregates, exports, marketing publication, MyInvois/integrations as approved, notification strategy, dependency remediation, accessibility/performance/offline review, observability, backups, UAT and deployment runbooks.

Status: not started.

## Next recommended task

After the setup PR stack is merged:

`TASK-DB-002: shared menu/catalogue foundation`.

Before SQL, inspect both `docs/frontend/BACKEND_INTEGRATION_PLAN.md` and `docs/dashboard/BACKEND_INTEGRATION_PLAN.md` plus `docs/contracts/SHARED_BACKEND_CONTRACT.md`. Do not map either preview model mechanically into tables, and do not wire either frontend unless that task is explicitly expanded.
