# Active Context

**As of:** 2026-09-15  
**Current boundary:** Phase 6 closeout — Loyalty, Rewards and Vouchers  
**Current verdict:** Phases 1–6 `COMPLETE`; valid Phase 1–3 Codex audit findings remediated `COMPLETE`; Phase 7 not started.

## Product topology

- customer/backend: `Hermann-33/Aida_System`
- Dashboard/Admin/POS: `Hermann-33/Aida_System-Dashboard`
- shared Supabase: `eswovqxqzfevcdwwcmuh` (`ACTIVE_HEALTHY`)
- canonical executable migrations: `Hermann-33/Aida_System/supabase/migrations/` only

## Completed authority

```text
Phase 1 COMPLETE  branch -> sales point -> terminal -> employee branch scope -> POS attribution
Phase 2 COMPLETE  terminal + employee -> shift -> POS order / cash ledger
Phase 3 COMPLETE  customer identity -> privacy preferences / whole-account deletion -> anonymized retained history
Phase 4 COMPLETE  branch calendar/policy -> pickup slot capacity -> authoritative quote/place
Phase 5 COMPLETE  recipe -> branch inventory -> transactional depletion/reversal
Phase 6 COMPLETE  member -> loyalty ledgers/balances -> reward/voucher -> authoritative discount/consumption
```

Supabase/server remains authority for identity, roles, topology, shift/cash/payment/commercial state, privacy/deletion, scheduling/capacity, inventory/recipes and loyalty/voucher state. Dashboard privileged flows remain behind the same-origin HttpOnly BFF with caller-JWT forwarding. No normal flow exposes a service-role secret, reusable employee bearer token or terminal credential to browser JavaScript. Preview fixtures are never backend authority.

## Phase 1–3 Codex remediation

Valid findings are closed. Key fixes: generic order writer grant removed; POS retry/open-shift authority hardened; Phase 3 anonymization restored under a narrow internal transition; retained customer request digests scrubbed; loyalty-aware deletion added; live Dashboard authority tests made blocking; customer full-screen goldens made blocking.

Evidence: `docs/context/PHASE_1_3_CODEX_AUDIT_REMEDIATION_CLOSEOUT_2026-09-15.md`.

The older combined Astra boundary document remains historical and is not represented as an Astra acceptance.

## Phase 6 final evidence

Implementation heads before documentation closeout:

```text
Aida_System             9273ba8f6c2f3d42404d9f6a34005bdde3df69e0
Aida_System-Dashboard   9979df27ed663b779c3d5c79670de4f19367b01c
```

```text
Backend database audit #190   COMPLETE
Customer release audit #281   COMPLETE
Dashboard CI #126             COMPLETE
Supabase deployment           COMPLETE
Supabase security advisor     COMPLETE for Phase 6
Supabase performance advisor  COMPLETE for Phase 6
```

Detailed evidence: `docs/context/PHASE_6_LOYALTY_REWARDS_VOUCHERS_CLOSEOUT_2026-09-15.md`.

## Current PR boundaries

```text
Phase 1: Aida_System #20 / Dashboard #17
Phase 2: Aida_System #21 / Dashboard #18
Phase 3: Aida_System #22 / Dashboard #19
Phase 4: Aida_System #23 / Dashboard #20
Phase 5: Aida_System #24 / Dashboard #21
Phase 6: Aida_System #25 / Dashboard #22
```

All remain draft/unmerged unless explicitly authorized. Completion is not merge authorization.

## Next boundary

Phase 7 promotions/discounts is next in dependency order, but it has not been started. External payment/refund/deployment-heavy work remains deferred.