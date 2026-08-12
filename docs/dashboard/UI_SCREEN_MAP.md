# POS/Admin UI Screen Map

Scope: `Hermann-33/Aida_System-Dashboard`.

| Route/surface | Role | Purpose | Current source/status |
|---|---|---|---|
| `/employee` | anonymous/staff/admin | terminal enrolment and employee sign-in | preview roster/terminal repo; planned API adapters |
| `/employee/select-role` | dual-role admin | choose POS or Admin workspace | current employee session |
| `/pos` | staff / enabled dual-role admin | full counter workspace | shared catalogue browsing; preview cart/totals/orders/payments remain non-durable |
| `/unauthorized` | denied identity | access-denied boundary | route-guard state |
| `/admin` | admin | executive KPIs/operations | derived preview transactions/terminals/shifts |
| `/admin/reports/sales` | admin | sales/product/payment/void/refund/staff/branch reporting | preview aggregates; export disabled |
| `/admin/reports/transactions` | admin | transaction list/detail | fixture transactions |
| `/admin/reports/members` | admin | member/loyalty reporting | preview members/transactions/reward rules |
| `/admin/operations/branches` | admin | branch/sales-point directory | React-state copy of preview org |
| `/admin/operations/terminals` | admin | terminal health/enrol/revoke | preview/session simulator |
| `/admin/operations/shifts` | admin | shifts and cash variance | preview rows |
| `/admin/operations/employees` | admin | employee/role/branch management | session-only React state |
| `/admin/catalogue/menu` | admin | items/categories/modifiers/add item | shared catalogue through authenticated same-origin BFF |
| `/admin/catalogue/menu/:id` | admin | price/availability/variant/add-on editor | shared catalogue mutation through caller-JWT BFF/RPC |
| `/admin/inventory/stock` | admin | stock/recipes/wastage/transfers | local arrays/state; transfer simulation |
| `/admin/rewards/loyalty` | admin | points/stamps/offers rules | preview read-only |
| `/admin/rewards/campaigns` | admin | campaign/ad composition | publish disabled/local-only flag |
| `/admin/system/audit` | admin | audit search/filter | sample local rows |
| `/admin/system/integrations` | admin | integration status | static placeholder |
| `/admin/system/settings` | admin | organisation defaults | save disabled |
| `/admin/preview/data-table` | admin/developer | table pattern demo | local sample data; not sidebar-linked |

POS internal rails include sale, orders, member, shift, terminal and help. Current guards separate Employee/POS/Admin layouts but are not security authority.
