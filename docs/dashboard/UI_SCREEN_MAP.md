# POS/Admin UI Screen Map

Updated: 2026-08-14

Scope: `Hermann-33/Aida_System-Dashboard`. Route guards/UI role labels are navigation controls; server/BFF/RLS authorization remains authoritative.

| Route/surface | Role | Purpose | Current source/status |
|---|---|---|---|
| `/employee` | anonymous/staff/admin | terminal enrolment + employee entry | employee credential session BFF integrated; terminal/device enrolment semantics remain separate/partly preview |
| `/employee/select-role` | dual-role admin/owner | choose POS or Admin workspace | current trusted employee session/navigation |
| `/admin/login` | anonymous | real Admin/owner sign-in | same-origin employee BFF + HttpOnly session; integrated and live-validated |
| `/pos` | staff / enabled admin/owner | counter workspace | shared catalogue integrated; cart is local intent; authoritative order quote/place/Orders rail integration is TASK-CLOSEOUT-001 work; payment/loyalty/shift extras remain preview |
| `/unauthorized` | denied identity | access-denied boundary | route state; not backend authorization |
| `/admin` | admin/owner | executive KPIs/operations | mostly preview aggregates; not authoritative reporting |
| `/admin/reports/sales` | admin/owner | sales/product/payment/void/refund/staff/branch reporting | preview aggregates; export disabled/not authoritative |
| `/admin/reports/transactions` | admin/owner | transaction list/detail | preview transactions until trusted reporting/payment domain exists |
| `/admin/reports/members` | admin/owner | Members + loyalty/reward reporting | trusted protected member directory integrated; loyalty/reward activity remains preview/deferred |
| `/admin/operations/branches` | admin/owner | branch/sales-point directory | React/preview state; branch authority deferred |
| `/admin/operations/terminals` | admin/owner | terminal health/enrol/revoke | preview/session simulator beyond existing terminal identity semantics |
| `/admin/operations/shifts` | admin/owner | shifts/cash variance | preview rows |
| `/admin/operations/employees` | admin/owner | employee/role/branch management | session/local UI; trusted role mutation management UI not completed |
| `/admin/catalogue/menu` | admin/owner | items/categories/menu management | shared catalogue through authenticated same-origin BFF; live-validated |
| `/admin/catalogue/menu/:id` | admin/owner | price/availability/variant/add-on editor | caller-JWT BFF/RPC mutation; live-validated through real Owner price change |
| `/admin/inventory/stock` | admin/owner | stock/recipes/wastage/transfers | local arrays/state; not trusted inventory authority |
| `/admin/rewards/loyalty` | admin/owner | points/stamps/offers rules | preview/read-only; trusted loyalty deferred |
| `/admin/rewards/campaigns` | admin/owner | campaign/ad composition | publish disabled/local-only |
| `/admin/system/audit` | admin/owner | audit search/filter | sample/local rows; not full backend audit explorer |
| `/admin/system/integrations` | admin/owner | integration status | static placeholder |
| `/admin/system/settings` | admin/owner | organisation defaults | mostly disabled/deferred; order-policy RPC exists server-side but no major new settings UI is required for closeout |
| `/admin/preview/data-table` | admin/developer | table pattern demo | local sample data; not sidebar-linked |

## POS internal rails

The counter workspace includes sale, orders, member, shift, terminal and help.

Current closeout distinction:

- **Sale catalogue/customization:** shared catalogue source is integrated.
- **Active cart:** local interaction/selection state is allowed.
- **Final quote/total/order identity:** must come from `/api/v1/orders/quote` and `/place` after closeout integration.
- **Orders rail:** must switch from `PREVIEW_TRANSACTIONS` to `/api/v1/orders` in live mode during TASK-CLOSEOUT-001.
- **Status controls:** must use versioned `/api/v1/orders/status` legal transitions.
- **Payment:** no trusted settlement processor; authoritative demo path is Pay at counter/unpaid.

## Validated cross-system evidence

- A physical Android customer signup provisioned a member that appeared in protected Dashboard Members.
- A real Owner catalogue price mutation propagated to the installed Android customer app.
- TASK-AUTH-005 preview/live session navigation regression is fixed and tested.

The final unclosed product-flow evidence for this tranche is authoritative customer order placement -> live Dashboard order queue/status transitions -> customer authorized refresh.
