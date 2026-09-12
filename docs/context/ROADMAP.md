# Roadmap

Updated: 2026-09-11

## Current status

Phase 1 — operational topology — is `COMPLETE` and frozen for Astra audit.

Matching audit PRs:

```text
Customer/backend PR #20
Dashboard/POS PR #17
```

Do not merge the Phase 1 PRs as part of the closeout. Do not begin Phase 2 until Astra findings are resolved or explicitly accepted.

Detailed Phase 1 evidence:

`docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

## Trusted foundation now complete

Implemented and validated to the current closeout standard:

- governance and shared-backend ownership;
- trusted customer/employee identity and membership foundation;
- customer Supabase Auth/member integration;
- same-origin employee/Admin session boundary;
- shared catalogue and protected Admin mutation;
- catalogue-driven variants, drink options and compatible add-ons;
- authoritative quote/order/schedule/status backend;
- customer authoritative quote/place/history/detail/status flow;
- Dashboard live POS ordering and polled order queue;
- versioned fulfilment transitions;
- immutable commercial order snapshots;
- trusted branch identity and staff branch scope;
- trusted sales-point and terminal topology;
- manager-issued one-time terminal enrolment;
- HttpOnly terminal credential handling;
- terminal revocation;
- terminal-bound POS order placement;
- immutable branch/sales-point/terminal POS attribution;
- clean Supabase migration replay and writable-database regressions;
- current customer release and Dashboard CI gates.

## Phase 1 validation boundary

```text
Backend database audit #22
  branch authority regression              PASS
  operational topology regression         PASS
  order regression                         PASS
  scheduled-order operations regression   PASS

Customer release audit #114               PASS
Dashboard CI #23                           PASS
```

Supabase advisor review shows one pre-existing leaked-password-protection WARN and INFO-only unused-index findings. No Phase 1-created security/performance blocker remains.

## Dependency-ordered backend completion

The remaining backend continues in this order:

1. **Phase 2 — shift and cash authority**
   - open/lock/resume/close shifts;
   - opening float;
   - cash movement ledger;
   - expected/actual cash and variance;
   - manager approval for material variance;
   - order/sale shift attribution.

2. **Phase 3 — customer privacy and App Store account requirements**
   - production account deletion;
   - retention/deletion rules;
   - privacy/terms/support surfaces;
   - consent/preferences and marketing opt-in/out.

3. **Phase 4 — branch scheduling and pickup authority**
   - branch opening hours;
   - closures/holidays;
   - capacity;
   - explicit customer pickup branch;
   - server validation of branch/time availability.

4. **Phase 5 — inventory and recipes**
   - inventory items/units;
   - recipes/BOM;
   - receiving/adjustment/transfer;
   - stock movement ledger;
   - order depletion;
   - branch/inventory-pool attribution.

5. **Phase 6 — loyalty, rewards and vouchers**
   - append-only loyalty ledger;
   - earning/redemption;
   - voucher/reward issuance and expiry;
   - idempotent transaction linkage.

6. **Phase 7 — promotions and discounts**
   - definitions/eligibility;
   - stacking/exclusions;
   - student/member rules;
   - authoritative discount snapshots.

7. **Phase 8 — reporting, accounting and audit**
   - trusted sales/operational projections;
   - branch/terminal/staff/shift breakdowns;
   - tax-ready transaction records;
   - export and privileged audit events.

8. **Phase 9 — payments, refunds and external integrations**
   - card/e-wallet/Apple Pay for physical goods where selected;
   - refunds;
   - processor idempotency/webhooks;
   - accounting/device integrations.

9. **Phase 10 — App Store release gate**
   - iOS release build/current compatibility;
   - privacy manifest/App Privacy answers;
   - account deletion physically verified;
   - support/privacy URLs;
   - review credentials/notes;
   - final on-device stability/accessibility.

## Dependency rule

Do not skip forward when a later domain depends on an unaudited earlier authority boundary.

```text
branch
 -> sales point / terminal
 -> shift
 -> inventory / sales attribution
 -> loyalty / promotions
 -> reporting
 -> payments / refunds
```

The first two links are now complete through Phase 1. Phase 2 is the next dependency once Astra accepts the frozen boundary.

## Current deployment boundary

Hosted production deployment remains deferred. The current Phase 1 verdict proves application/backend correctness for its defined scope; it does not claim final production hosting, payment settlement, device integration or App Store release readiness.
