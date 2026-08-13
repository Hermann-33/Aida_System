# POS/Admin UI Screen Map

Updated: 2026-08-14

This mirrored map summarizes current Dashboard surfaces. Detailed trust boundaries are in `docs/context/ACTIVE_CONTEXT.md`, `SYSTEM_MAP.md` and the accepted ADR/contracts.

| Route/surface | Current status |
|---|---|
| `/employee` | Employee/terminal entry; employee account boundary integrated, terminal/device operations partly preview |
| `/employee/select-role` | Role-appropriate workspace selection from current employee state |
| `/admin/login` | Real management entry integrated and live-validated |
| `/pos` | Shared catalogue integrated; authoritative order frontend is TASK-CLOSEOUT-001 work; payment/loyalty/shift extras remain preview |
| `/admin` | Management shell; overview KPIs remain preview/non-authoritative |
| `/admin/reports/sales` | Preview reporting; trusted revenue reporting deferred |
| `/admin/reports/transactions` | Preview transaction reporting |
| `/admin/reports/members` | Protected member directory integrated; loyalty/reward reporting deferred |
| `/admin/operations/*` | Branch/terminal/shift/employee management mostly preview/deferred |
| `/admin/catalogue/menu` | Shared catalogue management integrated and live-validated |
| `/admin/catalogue/menu/:id` | Shared catalogue edit path integrated and live-validated |
| `/admin/inventory/stock` | Preview/local inventory; trusted inventory deferred |
| `/admin/rewards/*` | Preview/deferred loyalty and campaigns |
| `/admin/system/audit` | Sample/local audit explorer; backend audit UI deferred |
| `/admin/system/integrations` | Placeholder |
| `/admin/system/settings` | Mostly deferred |

## POS closeout distinction

- Cart/customization may remain local selection state.
- Final quote/total/order identity must come from the existing order backend.
- Live Orders must replace preview transactions with the existing order queue.
- Fulfilment controls must use persisted status/version rules.
- No trusted payment processor exists; authoritative demo semantics are Pay at counter / unpaid.

Validated evidence already includes physical Android customer creation -> Dashboard Members, real Owner catalogue mutation -> installed customer refresh, and the TASK-AUTH-005 navigation regression fix.

The final unclosed tranche flow is customer order placement -> Dashboard fulfilment transition -> customer authorized refresh.
