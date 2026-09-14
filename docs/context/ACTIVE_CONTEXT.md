# Active Context

**As of:** 2026-09-15  
**Current boundary:** Phase 6 — Loyalty, Rewards and Vouchers  
**Current verdict:** Phase 5 `COMPLETE`; Phases 1–5 individually `COMPLETE`.  
**Implementation state:** Phase 6 may start on dedicated branches from the frozen Phase 5 documentation heads.

## Product topology

AIDA Café is one product across:

- customer/backend: `Hermann-33/Aida_System`;
- Dashboard/Admin/POS: `Hermann-33/Aida_System-Dashboard`;
- shared Supabase project: `eswovqxqzfevcdwwcmuh`.

Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Completed authority through Phase 5

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

Phase 5 COMPLETE
catalogue item/variant/add-on -> active recipe -> branch stock
                              -> transactional depletion/reversal
```

Supabase/server owns trusted identity, role/disabled state, membership, topology, shift/cash/payment/commercial state, privacy/account-deletion state, branch-local scheduling/capacity, inventory balances, recipes and order-linked stock depletion/reversal. Dashboard privileged flows stay behind the same-origin HttpOnly BFF with caller-JWT forwarding. No service-role secret or browser-readable employee bearer token/terminal credential is introduced. Preview fixtures are never backend authority.

## Phase 5 final evidence

Implementation heads before documentation closeout:

```text
Aida_System             2b26bc531e2f03c1af1f31e5e51a8b529111fc04
Aida_System-Dashboard   2f6128c40fe0b9778f193c43681ad0b6bbf47653
```

Validation:

```text
Backend database audit #138   COMPLETE
Customer release audit #229   COMPLETE
Dashboard CI #99              COMPLETE
Supabase security advisor     COMPLETE for Phase 5
Supabase performance advisor  COMPLETE for Phase 5
```

Security advisor has no Phase 5 finding; the single remaining Auth warning is the pre-existing leaked-password-protection setting. Performance findings are INFO-level unused indexes only.

Detailed evidence: `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`.

## Independent Phase 1–3 audit

The owner-directed Codex audit of Phases 1–3 may run in parallel with later implementation under `docs/decisions/ADR-0013-parallel-audit-and-phase-4-7-implementation.md`. A valid blocking audit finding reopens the affected earlier phase. Phase PRs remain draft/unmerged unless explicitly authorized otherwise.

## Current PR boundaries

```text
Phase 1: Aida_System #20 / Dashboard #17
Phase 2: Aida_System #21 / Dashboard #18
Phase 3: Aida_System #22 / Dashboard #19
Phase 4: Aida_System #23 / Dashboard #20
Phase 5: Aida_System #24 / Dashboard #21
```

Do not merge merely because implementation is complete.

## Next boundary

Phase 6 must document its plan before implementation. It owns loyalty, rewards and vouchers. Promotions/discounts remain Phase 7 and may not begin until Phase 6 is `COMPLETE`.
