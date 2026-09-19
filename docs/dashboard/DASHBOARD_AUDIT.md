# Dashboard Audit

Updated: 2026-09-15

**Current verdict:** Dashboard implementation is `COMPLETE` through Phase 7 against the defined runtime/security/CI boundary. This document describes current state; older dated audit records remain historical evidence only.

## Trusted architecture

Dashboard/Admin/POS uses a same-origin BFF over the shared Supabase backend. Employee access/refresh and terminal credentials remain HttpOnly/server-side. The BFF forwards the caller JWT and publishable key so Supabase role/RLS/RPC checks remain authoritative. No normal live path uses a service-role credential or exposes reusable employee/terminal secrets to browser JavaScript.

Preview fixtures are isolated and never silently replace failed live authority.

## Completed live surfaces

- Phase 1: branches, employee branch scope, sales points, terminals, enrolment/revocation and POS topology attribution.
- Phase 2: shift lifecycle, cash movements/reconciliation and open-shift order authority.
- Phase 4: branch pickup configuration and capacity-aware ordering.
- Phase 5: branch inventory, movements and recipe administration.
- Phase 6: loyalty program/reward administration, member wallet/support adjustments, POS member lookup and voucher-aware orders.
- Phase 7: live campaign/promotion administration, automatic server promotion evaluation and POS/order presentation of accepted promotion snapshots.

Phase 3 customer deletion/privacy is primarily a customer/backend surface; Dashboard retained order views consume the resulting anonymised commercial history rather than restoring deleted customer identity.

## Phase 7 audit result

The Campaigns tab uses production BFF endpoints backed by `get_promotion_admin_state()` and `save_promotion(jsonb)`. Admin/Owner role and caller identity are revalidated server-side. Direct promotion-table access is revoked.

Dashboard order contracts strictly parse:

```text
voucherDiscountSen
promotionDiscountSen
discountSen
promotions[]
```

and reject inconsistent commercial snapshots. POS does not submit accepted promotion authority; promotions are server-selected during quote/place.

Live/preview regressions cover that preview mode does not contact privileged promotion endpoints and that live POS can render a promotion-only authoritative order/quote.

## Exact validated implementation

```text
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Dashboard CI #147       COMPLETE
```

Dashboard CI passed lint, TypeScript typecheck, unit tests, live POS browser authority regression, preview-isolation browser regression and production build.

Cross-repo Phase 7 validation also passed:

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
```

## Live backend evidence

AIDA Supabase `eswovqxqzfevcdwwcmuh` is `ACTIVE_HEALTHY`. The three canonical Phase 7 migrations are deployed. All six promotion tables have RLS + FORCE RLS with direct anon/authenticated CRUD revoked. Required RPC/function grants are present, the old pending-voucher trigger is retired, and fresh advisors show no new blocking Phase 7 issue.

The sole security WARN remains the pre-existing disabled leaked-password-protection Auth setting. Performance findings are INFO unused-index observations only.

## Known later boundaries

- Phase 8: authoritative reporting/accounting/audit data and exports.
- Phase 9: external payment/refund/settlement integrations.
- Phase 10: final production/App Store release gate.
- separately deferred unless explicitly owned later: Badge/PIN provisioning and hardware integrations.

## Governance

Phase completion does not authorize merge. Phase 7 PRs remain draft/unmerged until the owner explicitly says otherwise. Current-state docs must be updated with each implementation batch; historical audit documents should not be used as runtime truth when a current closeout supersedes them.
