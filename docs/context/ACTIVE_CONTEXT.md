# Active Context

**As of:** 2026-09-15  
**Current boundary:** Phase 6 — Loyalty, Rewards and Vouchers  
**Current verdict:** Phase 6 `PARTIAL`; Phases 1–5 individually `COMPLETE`.  
**Implementation state:** The documented Phase 6 feature scope is implemented on dedicated backend/customer and Dashboard branches. Phase 6 cannot be marked `COMPLETE` because final CI and live Supabase deployment/advisor gates are externally blocked. Phase 7 must not begin until those gates are proven.

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

## Phase 6 implemented boundary

Implemented server/client authority includes:

- server-owned loyalty program configuration, points/stamp ledgers and balances;
- idempotent earning on qualifying completed orders;
- server-owned reward catalogue and atomic points redemption;
- server-issued member vouchers with immutable commercial snapshots;
- trusted customer/POS voucher validation, authoritative quote/application and one-time order consumption;
- privacy-preserving account-deletion handling for Phase 6 customer-owned state;
- Admin/Owner reward management, member-support and loyalty-program configuration RPCs;
- shift/terminal-bound POS member loyalty lookup with the terminal credential kept inside the same-origin BFF;
- live customer loyalty repository using caller-bound RPCs rather than preview balances;
- live customer reward redemption with points/reward/voucher/stamp refresh;
- live customer checkout voucher selection submitting only `voucherId` intent for authoritative quote/place validation;
- Dashboard Admin loyalty BFF/client surfaces, full reward create/edit/enable/disable and audited member adjustments;
- live POS checkout member lookup and voucher selection through the shift-bound BFF, submitting only `memberCode`/`voucherId` intent to authoritative order RPCs;
- prior trusted POS quote is invalidated whenever selected member/voucher intent changes;
- preview member/reward controls remain isolated from live order authority.

Canonical Phase 6 migrations currently extend through:

```text
20260914184500_add_pos_loyalty_lookup_authority.sql
```

## Phase 6 remaining completion gates

No additional planned Phase 6 feature scope is currently outstanding. The remaining blockers are validation/infrastructure gates:

- the connected Supabase account does not expose existing AIDA project `eswovqxqzfevcdwwcmuh`, so canonical Phase 6 migrations cannot be verified/deployed from this context and security/performance advisors cannot be rerun;
- current GitHub Actions runs fail before runner allocation. Latest observed customer-release and Dashboard CI jobs report `steps: []` and `runner_id: 0`; therefore lint/typecheck/tests/build/database regression work never starts and these failures are not code-failure evidence;
- a real executed backend database audit, customer release audit and Dashboard CI run are mandatory before `COMPLETE`;
- final architecture/contracts/App Store/handoff closeout must record the exact validated final heads after those gates pass.

Because these gates are unresolved, Phase 6 remains `PARTIAL` and Phase 7 is blocked by dependency order.

Detailed implementation/validation handoff: `docs/context/PHASE_6_IMPLEMENTATION_STATUS_2026-09-15.md`.

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

Do not invent more Phase 6 features and do not start Phase 7. Restore/observe execution of the blocked validation gates. If an executed test/advisor exposes a real defect, repair only that defect on the existing Phase 6 branches. Once every gate is `COMPLETE`, write the synchronized Phase 6 closeout and then create dedicated Phase 7 promotions/discounts branches.
