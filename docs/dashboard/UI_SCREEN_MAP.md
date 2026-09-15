# POS/Admin UI Screen Map

Updated: 2026-09-15

Scope: `Hermann-33/Aida_System-Dashboard`, current through the Phase 7 repository implementation boundary. Formal Phase 7 remains `PARTIAL` until live AIDA Supabase deployment/advisors are complete.

| Route/surface | Role | Purpose | Current source/status |
|---|---|---|---|
| `/employee` | anonymous/staff/admin | employee entry + terminal activation | live password employee auth and live one-time terminal enrolment via same-origin BFF; Badge/PIN credential lifecycle remains deferred |
| `/employee/select-role` | eligible dual-role admin | choose POS or Admin workspace | current trusted employee session |
| `/admin/login` | anonymous | Admin/Owner login | same-origin employee BFF + HttpOnly session |
| `/pos` | staff / enabled admin | Sale + Orders + Help | live catalogue, trusted terminal/open-shift context, authoritative quote/place/status, member/voucher intent, automatic server promotions, cash/unpaid tender |
| `/unauthorized` | denied identity | access-denied presentation | backend/BFF remains authorization authority |
| `/admin` | admin/owner | executive shell | shell live; generalized KPI/reporting aggregates remain Phase 8 deferred |
| `/admin/reports/sales` | admin/owner | reporting presentation | trusted reporting remains Phase 8 deferred |
| `/admin/reports/transactions` | admin/owner | transaction presentation | preview/fixture presentation only; not order authority |
| `/admin/reports/members` | admin/owner | live member directory + live loyalty support | member directory, wallet lookup and audited points/stamp adjustments are live; aggregate reporting remains Phase 8 deferred |
| `/admin/operations/branches` | admin/owner | branch/sales-point directory | live Phase 1 topology via same-origin BFF; branch-local scheduling policy is live Phase 4 |
| `/admin/operations/terminals` | admin/owner | terminal lifecycle UI | live terminal state, enrolment-code issuance and revocation |
| `/admin/operations/shifts` | admin/owner | shift/cash UI | live open/lock/resume/close, cash movement, reconciliation and history |
| `/admin/operations/employees` | admin/owner | employee management UI | live trusted employee/branch assignment boundary; Badge/PIN credential provisioning remains deferred |
| `/admin/catalogue/menu` | admin/owner | shared items/categories/add-ons | live shared catalogue via authenticated BFF |
| `/admin/catalogue/menu/:id` | admin/owner | item/variant/drink-option/add-on editor | live caller-JWT catalogue mutation |
| `/admin/inventory/stock` | admin/owner | inventory + recipe administration | live Phase 5 branch inventory, movements and recipes via same-origin BFF |
| `/admin/rewards/loyalty` | admin/owner | loyalty program + reward administration | live Phase 6 program and reward authority via same-origin BFF |
| `/admin/rewards/campaigns` | admin/owner | promotion/campaign administration | Phase 7 live-code surface: promotion list/create/edit/activation with branch/product/variant/add-on targeting through same-origin caller-JWT BFF; live AIDA deployment still pending |
| `/admin/system/audit` | admin/owner | audit presentation | generalized reporting/audit expansion remains Phase 8 deferred |
| `/admin/system/integrations` | admin/owner | integration status | external integrations remain Phase 9 deferred |
| `/admin/system/settings` | admin/owner | organisation settings UI | deeper save authority remains deferred |

## Live authority boundaries through Phase 7 code

Live POS/Admin code consumes server-owned authority for branches, sales points, terminals, employee branch scope, shifts/cash, pickup scheduling/capacity, inventory/recipes, loyalty/rewards/vouchers, promotion configuration/evaluation, order quote/place/status and persisted commercial snapshots. The browser never becomes authority for topology, shift identity, cash truth, catalogue price, voucher discount, promotion eligibility/discount, payment state, loyalty balances or accepted order history.

Phase 7 quote/order responses separate `voucherDiscountSen` and `promotionDiscountSen` while preserving total `discountSen`. Promotion application snapshots are immutable accepted commercial facts. POS presents server-accepted promotions but does not send accepted promotion IDs or discount amounts as order authority.

Preview mode remains isolated. Preview fixtures may demonstrate UI behavior but do not contact privileged promotion endpoints and must never silently substitute for unavailable live topology, shift, inventory, loyalty, order, promotion or payment authority.

## POS Sale / modifier surface

For a live product, the modifier sheet may render variant/size, configured Temperature and Sweetness groups, and compatible add-ons. Options come from the shared catalogue. Unavailable options remain visibly disabled and selected option/add-on state is per cart line.

## POS operational rails

Live POS uses trusted terminal status and an open shift. Orders are separated into Active, Scheduled, Ready and History. Due/overdue are display classifications only; persisted order status remains server-owned and staff explicitly starts preparation.

Member/voucher selections are client intent only. Active promotions require no client selection; the server resolves them from configuration. Quote and placement revalidate member/voucher ownership, promotion eligibility/usage, scheduling, inventory and commercial totals.

## Admin Marketing / Campaigns

The Campaigns tab now consumes authoritative promotion state and writes through `save_promotion` via the same-origin BFF. Supported configuration includes fixed/percent amount, minimum subtotal, optional cap, windows, priority, exclusive/stackable behavior, voucher coexistence, member requirement, usage limits and branch/product/variant/add-on targeting.

In UI preview mode the page uses sample campaign presentation and explicitly does not perform privileged backend requests.

## Now / Schedule

Immediate pickup is displayed as `Now`; the wire value remains `asap`. Scheduled choices come from server branch policy, windows/exceptions and capacity authority.

## Deployment caveat

The Phase 7 Dashboard/backend repository implementation is green, but the current Supabase connector account does not expose AIDA project `eswovqxqzfevcdwwcmuh`. The Campaigns surface must not be described as production-live until the Phase 7 migrations are deployed/reconciled on that project and fresh advisors pass.

## Deferred boundaries

Still deferred: generalized reporting/accounting/audit (Phase 8), external processor settlement/refunds/integrations (Phase 9), Badge/PIN credential provisioning, hardware integrations, hosted deployment operations and the final App Store release gate (Phase 10).

Route guards and visible role choices are presentation boundaries only; the same-origin BFF plus Supabase RLS/RPC boundaries are authoritative.
