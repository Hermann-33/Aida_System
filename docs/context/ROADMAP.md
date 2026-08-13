# Roadmap

Updated: 2026-08-14

## Current tranche

- Governance and shared-backend ownership: COMPLETE.
- Identity/member database foundation: COMPLETE for scoped authority.
- Customer Supabase Auth/member integration and physical signup: COMPLETE.
- Shared catalogue backend, Dashboard Admin/POS browsing, Flutter Realtime refresh, and physical cross-client price proof: COMPLETE.
- Android release networking and committed build reproducibility: COMPLETE.
- Authoritative order/scheduling backend: COMPLETE for ADR-0010 scope.
- Customer authoritative order frontend: COMPLETE for implemented scope.
- Dashboard authoritative POS/order-board frontend: PARTIAL; tracked by Dashboard PR #12.
- Full cross-client order lifecycle E2E: PARTIAL pending Dashboard closeout evidence.

## Closeout rule

Customer PR #13 and Dashboard PR #12 remain draft until the Dashboard order frontend passes its toolchain and proves customer placement → dashboard status transitions → customer authorized refresh. Mirrored current governance must agree before either closeout is marked COMPLETE.

## Deferred product work

Do not add these domains to the closeout tranche:

1. trusted payment capture/refunds;
2. loyalty earning/redemption and voucher lifecycle;
3. inventory/recipes/depletion;
4. promotion/discount authority;
5. tax/accounting and trusted reporting;
6. branch-scoped staff/order visibility and branch capacity/hours;
7. delivery and production release signing/distribution.
