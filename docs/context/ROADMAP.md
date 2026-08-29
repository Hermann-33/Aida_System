# Roadmap

Updated: 2026-08-29

## 2026-08-29 update

Two backend migrations against item 2 below ("loyalty earning/redemption and
voucher lifecycle") and one App/Play Store compliance item are now drafted
but **not applied/verified** — see `docs/context/BACKEND_MIGRATIONS_2026-08-29.md`:

- `TASK-REFERRAL-001`: a referral-bonus points ledger (`members.points_balance`,
  `referrals` table, reward on a referred member's first completed order).
  Stamps, the rewards catalogue, vouchers and offers remain fully mock.
- `TASK-ACCT-001`: customer self-service account deletion
  (`delete_own_account()` RPC) — not itself on the "next bounded work" list
  below, but recorded here since it's a real backend/identity change made
  this session.

Separately, a large uncommitted customer-app presentation-layer pass
(rewards tear-to-apply animation, app-wide popup redesign, menu search,
membership card/profile/order-confirmation redesigns, a splash screen, and a
demo order-progress capsule) landed as `TASK-REDESIGN-001` — see
`docs/frontend/UI_REDESIGN_SPEC.md` for full evidence. It does not change
this roadmap's scope, only presentation.

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
