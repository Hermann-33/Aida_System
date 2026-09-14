# AIDA Backend Completion Phases

**Status:** Phases 1–5 `COMPLETE`; Phase 6 is the next implementation boundary  
**Started:** 2026-09-10  
**Updated:** 2026-09-15

## Phase rule

A phase is `COMPLETE` only when implementation, canonical migrations, authorization/regression coverage, affected client validation, advisor review, synchronized documentation, deferred scope and App Store impact are all recorded.

By explicit owner direction on 2026-09-14, the independent Phase 1–3 Codex audit runs in parallel with Phase 4–7 implementation. Any blocking audit finding reopens the affected earlier phase and must be resolved; it does not authorize weakening later-phase trust boundaries. Existing phase PRs remain draft/unmerged unless explicitly authorized.

## Phase 1 — Operational topology

**Task:** `TASK-OPS-002`  
**Status:** `COMPLETE`  
**Plan:** `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_PLAN.md`  
**Evidence:** `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

Trusted chain: branch -> sales point -> terminal -> employee branch scope -> POS attribution.

## Phase 2 — Shift and cash authority

**Task:** `TASK-OPS-003`  
**Status:** `COMPLETE`  
**Plan:** `docs/context/PHASE_2_SHIFT_CASH_PLAN.md`  
**Evidence:** `docs/context/PHASE_2_SHIFT_CASH_CLOSEOUT_2026-09-12.md`

Trusted chain: terminal + employee -> shift -> POS order / append-only cash ledger. Expected cash/variance is server-owned; cash/unpaid is internal tender authority only.

## Phase 3 — Customer privacy and App Store account requirements

**Task:** `TASK-PRIVACY-001`  
**Status:** `COMPLETE`  
**Plan:** `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_PLAN.md`  
**Evidence:** `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_CLOSEOUT_2026-09-12.md`

Completed boundary includes caller-bound whole-account deletion, privacy preferences, anonymized retained customer transaction history, retained free-text scrubbing, public privacy/terms/support boundaries and iOS data/permission review.

## Independent Phase 1–3 audit

**Status:** `PARTIAL` — external Codex audit reports are not accepted until explicitly reviewed.  
**Boundary:** `docs/context/PHASE_1_3_ASTRA_AUDIT_BOUNDARY_2026-09-12.md`

A valid blocking audit finding reopens the affected earlier phase. Do not merge Phase 1–3 merely because implementation is complete.

## Phase 4 — Branch scheduling and pickup authority

**Task:** `TASK-OPS-004`  
**Status:** `COMPLETE`  
**Plan:** `docs/context/PHASE_4_BRANCH_SCHEDULING_PICKUP_PLAN.md`  
**Evidence:** `docs/context/PHASE_4_BRANCH_SCHEDULING_PICKUP_CLOSEOUT_2026-09-15.md`

Trusted chain: active branch -> branch-local service calendar -> pickup policy -> slot capacity -> authoritative quote/order acceptance.

Final validation: Backend database audit #122 `COMPLETE`; Customer release audit #213 `COMPLETE`; Dashboard CI #84 `COMPLETE`; Supabase security/performance advisor boundary `COMPLETE`.

## Phase 5 — Inventory and recipes

**Task:** `TASK-OPS-005`  
**Status:** `COMPLETE`  
**Plan:** `docs/context/PHASE_5_INVENTORY_RECIPES_PLAN.md`  
**Evidence:** `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`

Trusted chain: catalogue item/variant/add-on -> active recipe -> branch inventory -> append-only stock movements -> transactional order depletion -> cancellation reversal. Physical stock uses integer milli-units and client-calculated stock is never authority.

Final validation:

```text
Backend database audit #138   COMPLETE
Customer release audit #229   COMPLETE
Dashboard CI #99              COMPLETE
Supabase security advisor     COMPLETE for Phase 5
Supabase performance advisor  COMPLETE for Phase 5
```

## Phase 6 — Loyalty, rewards and vouchers

**Status:** `PARTIAL` only after dedicated branches and a mirrored plan are created. No implementation may precede the plan.  
**Dependency:** Phase 5 `COMPLETE`.

Target authority: trusted member identity -> append-only points ledger -> server-derived points balance -> reward catalogue -> atomic point redemption -> customer voucher wallet -> trusted voucher consumption. Points, eligibility, voucher state and redemption must never be client-authoritative.

## Later phases

Phase 7: promotions and discounts.  
Phase 8: reporting, accounting and audit.  
Phase 9: payments, refunds and external integrations.  
Phase 10: App Store release gate.

## Dependency rule

```text
Phase 1 COMPLETE
 -> Phase 2 COMPLETE
 -> Phase 3 COMPLETE
 -> independent Phase 1–3 Codex audit runs in parallel
 -> Phase 4 COMPLETE
 -> Phase 5 COMPLETE
 -> Phase 6 next
 -> Phase 7 only after Phase 6 COMPLETE
```
