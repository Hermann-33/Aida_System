# Roadmap

Updated: 2026-08-17

## Current tranche

Implemented and validated to the current closeout standard:

- governance and shared-backend ownership;
- trusted identity/member foundation;
- customer Supabase Auth/member integration and physical signup;
- same-origin employee/Admin session boundary;
- protected Dashboard Members;
- shared catalogue, protected Admin mutation, POS/customer reads and customer revision refresh;
- TASK-AUTH-005 preview/live session separation;
- Android release networking and reproducible committed build toolchain;
- authoritative quote/order/schedule/status backend;
- customer authoritative quote/place/history/detail/status frontend;
- Dashboard authoritative POS quote/place and server-policy scheduling;
- Dashboard live polled order queue and versioned fulfilment transitions;
- customer and Dashboard full local toolchain/test/build gates;
- credential-backed live cross-client order lifecycle.

## Current status

`TASK-CLOSEOUT-001`: **COMPLETE** for implementation and applicable ADR-0004 validation.

Live proof completed on 2026-08-17:

customer placement
→ persisted order
→ Dashboard observation
→ preparing
→ customer authorized refresh
→ ready
→ customer authorized refresh
→ completed
→ customer authorized refresh.

The retained evidence is order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`), authoritative total 1,290 sen, completed at status version 4. Approved demo credentials were process-local, were not committed and were removed after the run.

## Merge state

Customer PR #13 and Dashboard PR #12 are independently verified mergeable and have completed the closeout gates. Final merge is repository housekeeping, not an implementation blocker.

Hosted/Vercel deployment is **DEFERRED** for the accepted local-PC + cloud-Supabase + installed-phone demo topology.

## Security operations

Current Supabase security-advisor evidence has one WARN: leaked-password protection is disabled. Enabling it is hosted Auth configuration work and does not justify weakening application Auth/RLS boundaries.

## Next bounded product work

Do not conflate these deferred domains with the completed closeout tranche. Future bounded tasks include:

1. trusted payment capture/refunds;
2. loyalty earning/redemption and voucher lifecycle;
3. inventory/recipes/depletion;
4. promotions/discount authority;
5. tax/accounting and trusted reporting;
6. branch-scoped staff/order visibility and branch hours/capacity;
7. delivery;
8. hosted production deployment, signing/distribution and operational release work.


## 2026-09-10 backend completion sequence

The remaining backend is now being completed in dependency order rather than by wiring isolated preview screens.

Current task:

1. **TASK-OPS-001 branch/location authority** — live backend foundation deployed; repository validation/integration remains PARTIAL.

Recommended dependency chain after this foundation:

2. trusted sales points + terminal/device authority;
3. shift lifecycle + cash-opening/closing/variance authority;
4. branch hours/closures/capacity and explicit pickup-location selection;
5. inventory items, recipes, stock movements and order depletion;
6. authoritative loyalty ledger, rewards/vouchers and redemption;
7. promotions/discount calculation authority;
8. trusted sales/tax/accounting/reporting projections and export;
9. external payment capture/refunds and accounting integration;
10. hosted production/release operations.

This order prevents terminals, inventory, loyalty and reporting from being built on fake global-branch or session-local identifiers.
