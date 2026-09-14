# Active Context

**As of:** 2026-09-15  
**Current boundary:** Phase 6 — Loyalty, Rewards and Vouchers  
**Current verdict:** Phase 6 `PARTIAL`; Phases 1–5 individually `COMPLETE`.  
**Implementation state:** Phase 6 implementation is active on dedicated backend/customer and Dashboard branches. Phase 7 must not begin until every Phase 6 validation/documentation gate is `COMPLETE`.

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

Detailed evidence: `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`.

## Phase 6 active implementation

Implemented server authority includes:

- server-owned loyalty program configuration, points/stamp ledgers and balances;
- idempotent earning on qualifying completed orders;
- server-owned reward catalogue and atomic points redemption;
- server-issued member vouchers with immutable commercial snapshots;
- trusted customer/POS voucher validation and order application;
- privacy-preserving account-deletion handling for Phase 6 state;
- Admin/Owner reward, member-support and loyalty-program configuration RPCs;
- shift/terminal-bound POS member loyalty lookup with terminal credential kept inside the same-origin BFF;
- live customer loyalty repository using caller-bound RPCs rather than preview balances;
- Dashboard Admin loyalty BFF/client surfaces and audited member adjustments.

Canonical Phase 6 migrations currently extend through:

```text
20260914184500_add_pos_loyalty_lookup_authority.sql
```

Current incomplete gates:

- customer reward redemption UI must call the live redemption repository and refresh balances/vouchers;
- customer checkout must expose eligible issued-voucher selection and submit voucher intent for authoritative quote/place;
- live POS member/voucher selection must consume the shift-bound POS lookup instead of preview-only member fixtures;
- Dashboard reward management still needs the full create/edit flow required by the Phase 6 plan;
- the AIDA Supabase project is not currently visible through the connected Supabase tool, so new Phase 6 migrations have not been deployed in this run and security/performance advisors cannot be rerun;
- current GitHub Actions attempts are failing before runner steps execute, so they do not constitute code-validation evidence.

Because these gates are unresolved, Phase 6 remains `PARTIAL` and Phase 7 is blocked by dependency order.

## Independent Phase 1–3 audit

The owner-directed Codex audit of Phases 1–3 may run in parallel with later implementation under `docs/decisions/ADR-0013-parallel-audit-and-phase-4-7-implementation.md`. A valid blocking audit finding reopens the affected earlier phase. Phase PRs remain draft/unmerged unless explicitly authorized otherwise.

## Current PR boundaries

```text
Phase 1: Aida_System #20 / Dashboard #17
Phase 2: Aida_System #21 / Dashboard #18
Phase 3: Aida_System #22 / Dashboard #19
Phase 4: Aida_System #23 / Dashboard #20
Phase 5: Aida_System #24 / Dashboard #21
Phase 6: Aida_System #25 / Dashboard #22
```

Do not merge merely because implementation is complete.

## Next boundary

Close every Phase 6 functional, database, CI, advisor and mirrored-documentation gate. Only then mark Phase 6 `COMPLETE` and create dedicated Phase 7 promotions/discounts branches.
