# POS/Admin UI Screen Map

Updated: 2026-08-23

Scope: `Hermann-33/Aida_System-Dashboard`.

| Route/surface | Role | Purpose | Current source/status |
|---|---|---|---|
| `/employee` | anonymous/staff/admin | employee entry | live employee auth is independent of deferred terminal enrolment; terminal/device simulation remains preview-only |
| `/employee/select-role` | eligible dual-role admin | choose POS or Admin workspace | current trusted employee session |
| `/admin/login` | anonymous | Admin/Owner login | same-origin employee BFF + HttpOnly session |
| `/pos` | staff / enabled admin | Sale + Orders + Help | shared catalogue with variants/Temperature/Sweetness/add-ons; authoritative quote/place; Active/Scheduled/Ready/History; Pay at counter |
| `/unauthorized` | denied identity | access-denied presentation | backend/BFF remains authorization authority |
| `/admin` | admin/owner | executive shell | many KPI aggregates remain preview/deferred |
| `/admin/reports/sales` | admin/owner | reporting presentation | trusted reporting remains deferred |
| `/admin/reports/transactions` | admin/owner | transaction presentation | preview/fixture data; not order authority |
| `/admin/reports/members` | admin/owner | member directory + loyalty report UI | member directory live; loyalty/reporting deferred |
| `/admin/operations/branches` | admin/owner | branch/sales-point directory | preview/deferred |
| `/admin/operations/terminals` | admin/owner | terminal lifecycle UI | preview/deferred |
| `/admin/operations/shifts` | admin/owner | shift/cash UI | preview/deferred |
| `/admin/operations/employees` | admin/owner | employee management UI | trusted identity for access; deeper management authority separately bounded |
| `/admin/catalogue/menu` | admin/owner | shared items/categories/add-ons | live shared catalogue via authenticated BFF; new-product dialog includes Drink toggle |
| `/admin/catalogue/menu/:id` | admin/owner | item/variant/drink-option/add-on editor | live caller-JWT catalogue mutation; Temperature/Sweetness label/delta/availability/default and compatible add-ons |
| `/admin/inventory/stock` | admin/owner | inventory UI | trusted inventory deferred |
| `/admin/rewards/loyalty` | admin/owner | loyalty UI | preview/deferred |
| `/admin/rewards/campaigns` | admin/owner | marketing UI | publish/deeper authority deferred |
| `/admin/system/audit` | admin/owner | audit presentation | database audit authority separate |
| `/admin/system/integrations` | admin/owner | integration status | placeholder/deferred |
| `/admin/system/settings` | admin/owner | organisation settings UI | deeper save authority deferred |

## POS Sale / modifier surface

For a live product, the modifier sheet may render:

```text
Size / variant                required single-choice when present
Temperature                   required single-choice for configured drinks
Sweetness                     required single-choice for configured drinks
Compatible add-ons            optional multi-select
```

Options come from the shared catalogue. Unavailable options remain visibly disabled and cannot be selected. Selected option/add-on state is per cart line, so differently customized copies of the same product remain independent.

The final Codex UI review confirmed that these controls reuse existing POS modifier-sheet density, typography, burgundy selection/focus language, labelled native controls and scroll behavior rather than introducing a separate theme.

## Admin Menu item editor

The live editor now includes:

- product/add-on type;
- Drink customization toggle for products;
- existing variants/sizes;
- per-group option cards;
- customer-facing option label;
- price delta in sen;
- Available checkbox;
- Default radio, disabled for unavailable choices;
- Compatible add-ons checkboxes.

Required groups cannot be saved without at least one available option and exactly one available default. Preview mode remains read-only.

The editor uses existing Admin form/card/button tokens and responsive row classes; it does not create a separate administration design language.

## POS internal rails

Live mode exposes Sale, Orders and Help. Member, Shift and Terminal remain preview-only until those domains have trusted backend authority.

Orders uses Active/Scheduled/Ready/History. Due/overdue scheduled work can appear in Active while persisted state remains `scheduled`; staff must explicitly Start preparing.

## Now / Schedule

Immediate pickup is displayed as `Now`. The trusted backend wire value remains `asap`. Schedule choices remain server-policy-derived.

## Validation

TASK-MENU-CUSTOMIZATION-001 Dashboard evidence:

- Vitest 29 files / 129 tests PASS;
- Playwright 10/10 PASS;
- lint/typecheck/build PASS;
- UI QA PASS at 1366x768 and 1440x900;
- no task-related console errors or warnings;
- focus-visible/reduced-motion and labelled native input behavior preserved.

Detailed evidence: `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`.

Route guards and visible role choices remain presentation boundaries; the same-origin BFF + Supabase RLS/RPC boundaries are authoritative.
