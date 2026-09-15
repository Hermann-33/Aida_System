# POS/Admin UI Screen Map

Updated: 2026-09-15

Scope: `Hermann-33/Aida_System-Dashboard`, current through the Phase 1–6 audit-remediation boundary.

| Route/surface | Role | Purpose | Current source/status |
|---|---|---|---|
| `/employee` | anonymous/staff/admin | employee entry + terminal activation | live password employee auth and live one-time terminal enrolment via same-origin BFF; Badge/PIN credential lifecycle remains deferred |
| `/employee/select-role` | eligible dual-role admin | choose POS or Admin workspace | current trusted employee session |
| `/admin/login` | anonymous | Admin/Owner login | same-origin employee BFF + HttpOnly session |
| `/pos` | staff / enabled admin | Sale + Orders + Help | live catalogue, trusted terminal/open-shift context, authoritative quote/place/status, member/voucher intent, cash/unpaid tender |
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
| `/admin/rewards/campaigns` | admin/owner | marketing UI | generalized promotions/campaign authority remains Phase 7+ deferred while Phase 1–6 remediation is frozen |
| `/admin/system/audit` | admin/owner | audit presentation | generalized reporting/audit expansion remains Phase 8 deferred |
| `/admin/system/integrations` | admin/owner | integration status | external integrations remain Phase 9 deferred |
| `/admin/system/settings` | admin/owner | organisation settings UI | deeper save authority remains deferred |

## Live authority boundaries through Phase 6

Live POS/Admin surfaces consume server-owned authority for branches, sales points, terminals, employee branch scope, shifts/cash, pickup scheduling/capacity, inventory/recipes, loyalty/rewards/vouchers, order quote/place/status and persisted commercial snapshots. The browser never becomes authority for topology, shift identity, cash truth, catalogue price, discount, payment state, loyalty balances or accepted order history.

Preview mode remains isolated. Preview fixtures may demonstrate UI behavior but must never silently substitute for unavailable live topology, shift, inventory, loyalty, order or payment authority.

## POS Sale / modifier surface

For a live product, the modifier sheet may render variant/size, configured Temperature and Sweetness groups, and compatible add-ons. Options come from the shared catalogue. Unavailable options remain visibly disabled and selected option/add-on state is per cart line.

## POS operational rails

Live POS uses trusted terminal status and an open shift. Orders are separated into Active, Scheduled, Ready and History. Due/overdue are display classifications only; persisted order status remains server-owned and staff explicitly starts preparation.

Phase 6 adds shift-bound member lookup and issued-voucher selection. Member/voucher selections are client intent only. Quote and placement revalidate ownership, status, expiry and discount, and accepted discount/voucher facts are immutable server snapshots.

## Now / Schedule

Immediate pickup is displayed as `Now`; the wire value remains `asap`. Scheduled choices come from server branch policy, windows/exceptions and capacity authority.

## Deferred boundaries

Still deferred after Phase 6: generalized promotions/campaigns (Phase 7), reporting/accounting expansion (Phase 8), external processor settlement/refunds/integrations (Phase 9), Badge/PIN credential provisioning, hardware integrations, hosted deployment operations and the final App Store release gate (Phase 10).

Route guards and visible role choices are presentation boundaries only; the same-origin BFF plus Supabase RLS/RPC boundaries are authoritative.
