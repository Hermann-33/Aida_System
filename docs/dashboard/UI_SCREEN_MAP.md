# POS/Admin UI Screen Map

Updated: 2026-08-17

Scope: `Hermann-33/Aida_System-Dashboard`.

| Route/surface | Role | Purpose | Current source/status |
|---|---|---|---|
| `/employee` | anonymous/staff/admin | terminal enrolment / employee entry | terminal/device enrolment remains preview/local; trusted employee identity is separate |
| `/employee/select-role` | dual-role admin | choose POS or Admin workspace | current employee session |
| `/admin/login` | anonymous | real Admin/Owner login | same-origin employee BFF + HttpOnly session; validated with Owner |
| `/pos` | staff / enabled admin | counter workspace | shared catalogue + authoritative quote/place + ASAP/scheduled pickup + live order queue/status + Pay at counter; deferred POS domains remain preview |
| `/unauthorized` | denied identity | access-denied boundary | route-guard presentation; backend remains authority |
| `/admin` | admin/owner | executive KPIs/operations | dashboard shell trusted; KPI/operations aggregates mostly preview/deferred |
| `/admin/reports/sales` | admin/owner | sales/product/payment/void/refund/staff/branch reporting | preview aggregates; trusted reporting deferred |
| `/admin/reports/transactions` | admin/owner | transaction list/detail | preview/fixture transactions; not order backend authority |
| `/admin/reports/members` | admin/owner | member directory + loyalty reporting | trusted live member directory; loyalty/report aggregates remain preview/deferred |
| `/admin/operations/branches` | admin/owner | branch/sales-point directory | local/preview; branch authority deferred |
| `/admin/operations/terminals` | admin/owner | terminal health/enrol/revoke | preview/session simulator; device authority deferred |
| `/admin/operations/shifts` | admin/owner | shifts and cash variance | preview/deferred |
| `/admin/operations/employees` | admin/owner | employee/role/branch management | trusted current identity used for access; management mutations remain deferred unless separately backed |
| `/admin/catalogue/menu` | admin/owner | items/categories/add-ons management | shared catalogue through authenticated same-origin BFF |
| `/admin/catalogue/menu/:id` | admin/owner | price/availability/variant/add-on editor | shared catalogue mutation through caller-JWT BFF/RPC |
| `/admin/inventory/stock` | admin/owner | stock/recipes/wastage/transfers | local arrays/state; trusted inventory deferred |
| `/admin/rewards/loyalty` | admin/owner | points/stamps/offers rules | preview/deferred |
| `/admin/rewards/campaigns` | admin/owner | campaign/ad composition | publish disabled/local-only; trusted marketing deferred |
| `/admin/system/audit` | admin/owner | audit search/filter | sample/local presentation; database audit authority is separate |
| `/admin/system/integrations` | admin/owner | integration status | static placeholder/deferred |
| `/admin/system/settings` | admin/owner | organisation defaults | save/deeper authority deferred |
| `/admin/preview/data-table` | admin/developer | table pattern demo | local sample data; not trusted product data |

## POS internal rails

Sale/cart selection uses the shared catalogue. Orders uses the live BFF queue and versioned status transitions. Member, shift, terminal and help surfaces retain their documented trusted/preview distinctions rather than inheriting order authority automatically.

## Validated Dashboard journeys

- Real Owner `/admin/login` → protected Members/Menu: PASS.
- Android customer signup → member visible in protected Dashboard Members: PASS.
- Owner catalogue price mutation → installed customer refresh: PASS.
- Final live order journey: customer order `100006` observed in Dashboard queue, transitioned confirmed v1 → preparing v2 → ready v3 → completed v4, with customer-authorized reads after each transition: PASS.

Route guards and visual role selection are not backend authorization authority. The same-origin BFF + Supabase RLS/RPC boundaries remain authoritative.
