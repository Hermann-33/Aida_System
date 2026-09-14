# Active Context

**As of:** 2026-09-15  
**Current boundary:** Phase 5 — Inventory and Recipes  
**Current verdict:** Phase 4 `COMPLETE`; Phases 1–4 individually `COMPLETE`.  
**Implementation state:** Phase 5 may start on a dedicated branch from the frozen Phase 4 head.

## Product topology

AIDA Café is one product across:

- customer/backend: `Hermann-33/Aida_System`;
- Dashboard/Admin/POS: `Hermann-33/Aida_System-Dashboard`;
- shared Supabase project: `eswovqxqzfevcdwwcmuh`.

Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Completed authority through Phase 4

```text
Phase 1 COMPLETE
branch -> sales point -> terminal -> employee branch scope -> POS attribution

Phase 2 COMPLETE
terminal + employee -> shift -> POS order / cash ledger

Phase 3 COMPLETE
customer identity -> privacy preferences / whole-account deletion
                  -> anonymized retained transaction history

Phase 4 COMPLETE
active branch -> service calendar -> pickup policy -> slot capacity
              -> authoritative quote/order acceptance
```

Supabase/server owns trusted identity, role/disabled state, membership, topology, shift/cash/payment/commercial state, privacy/account-deletion state, branch-local scheduling policy and slot-capacity enforcement. Dashboard privileged flows stay behind the same-origin HttpOnly BFF with caller-JWT forwarding. No service-role secret or browser-readable employee bearer token/terminal credential is introduced. Preview fixtures are never backend authority.

## Phase 4 final evidence

Implementation heads before documentation closeout:

```text
Aida_System             f5e204c0cb882a1b0b4ca25b32086c47f5eef796
Aida_System-Dashboard   de7e9da36db8a9d426e8d545d89229cc53ce733f
```

Validation:

```text
Backend database audit #122   COMPLETE
Customer release audit #213   COMPLETE
Dashboard CI #84              COMPLETE
Supabase security advisor     COMPLETE for Phase 4
Supabase performance advisor  COMPLETE for Phase 4
```

Security advisor has one pre-existing Auth warning only: leaked-password protection is disabled. Performance findings are INFO-level unused indexes only.

Detailed evidence: `docs/context/PHASE_4_BRANCH_SCHEDULING_PICKUP_CLOSEOUT_2026-09-15.md`.

## Independent Phase 1–3 audit

The owner-directed Codex audit of Phases 1–3 may run in parallel with later implementation under `docs/decisions/ADR-0013-parallel-audit-and-phase-4-7-implementation.md`. A valid blocking audit finding reopens the affected earlier phase. Phase 1–3 PRs remain draft/unmerged unless explicitly authorized otherwise.

## Current PR boundaries

```text
Phase 1: Aida_System #20 / Dashboard #17
Phase 2: Aida_System #21 / Dashboard #18
Phase 3: Aida_System #22 / Dashboard #19
Phase 4: Aida_System #23 / Dashboard #20
```

Do not merge merely because implementation is complete.

## Next boundary

Phase 5 must document its plan before implementation. Its dependency is the Phase 4 branch and scheduling authority now marked `COMPLETE`. Phase 5 owns inventory and recipes; loyalty/rewards/vouchers remain Phase 6 and promotions/discounts remain Phase 7.
