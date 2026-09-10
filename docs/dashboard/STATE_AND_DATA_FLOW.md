# POS/Admin State and Data Flow

Updated: 2026-08-23

## Employee/Admin session

```text
Admin/employee login
 -> same-origin employee BFF
 -> Supabase Auth server session
 -> trusted user_profiles role/disabled-state check
 -> HttpOnly cookies
 -> React session identity
```

The browser does not persist the employee access token. Preview identity remains explicitly non-authoritative.

## Admin catalogue / drink customization

```text
AdminMenuPage / AdminMenuEditorPage
 -> catalogueClient
 -> employeeFetch(credentials: include)
 -> same-origin catalogue BFF
 -> employee session validation
 -> caller Admin/Owner JWT
 -> get_catalogue / save_catalogue_item
 -> catalogue + audit + revision bump
```

The catalogue snapshot includes `isDrink`, variants, compatible add-on IDs and `customizationGroups`.

For a drink, Admin can edit each Temperature/Sweetness option's customer label, price delta, availability and default. The UI requires at least one available option and exactly one available default per required group; the backend remains authoritative and validates the same invariant.

Preview mode uses the public catalogue in read-only mode and exposes no privileged save control.

## POS catalogue / modifier read

```text
CounterWorkspace
 -> catalogueClient
 -> GET /api/v1/catalogue
 -> get_catalogue(public read)
 -> posCatalogue adapter
 -> product + variants + customization groups + compatible add-ons
```

Modifier mapping:

```text
variant (when present)        required single choice
Temperature / Sweetness       required single choice
compatible add-ons            optional multi-select
```

Unavailable options remain visible/disabled and are not selectable. No preview catalogue fallback becomes live authority.

## POS cart versus authoritative quote

```text
itemId + variantId + optionValueIds[] + addOnIds[] + quantity + note
 -> local POS cart interaction / estimate
 -> POST /api/v1/orders/quote
 -> BFF validates employee session
 -> caller JWT -> quote_order
 -> server revalidates catalogue/options/add-ons
 -> authoritative line/subtotal/total sen
```

The local cart may display an estimate including variant, option and add-on deltas, but the server quote is commercial authority. Differently configured copies of the same product remain distinct cart lines.

## Now / scheduled POS order

```text
GET /api/v1/orders/policy
 -> serverNow + schedule policy
 -> POS offers Now / Schedule for later
 -> selected timestamp + line selection IDs
 -> POST /api/v1/orders/quote
 -> backend validates schedule + modifiers
 -> create/reuse clientRequestId for this intent
 -> POST /api/v1/orders/place
 -> place_pos_order with employee caller JWT
 -> persisted guest POS order
```

`Now` is presentation only; the trusted wire value remains `asap`. The sale clears only after persisted success.

## Staff order queue

```text
GET /api/v1/orders
 -> strict snapshot parsing
 -> Active / Scheduled / Ready / History projection
 -> refetch every ~2.5 seconds
```

Backend `prepareAt`, `serverNow` and `scheduleState` remain operational authority. No React timer mutates order status.

## Status transition

```text
staff action + current statusVersion
 -> POST /api/v1/orders/status
 -> BFF same-origin/session check
 -> caller JWT
 -> transition_order_status(expectedVersion)
 -> updated order + event
 -> queue/detail invalidation
```

Legal progression remains:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Completed/cancelled remain terminal; stale versions refetch rather than replay stale state.

## Live staff POS entry

```text
/employee
 -> trusted employee Auth
 -> HttpOnly session
 -> /pos
 -> Sale + Orders + Help
```

Live mode does not depend on deferred terminal/current-shift authority. Preview terminal/shift/member state never authorizes live APIs.

## Customer propagation

```text
catalogue Admin save
 -> catalogue_revision
 -> customer catalogue invalidation/refetch

staff order transition
 -> orders change
 -> customer owner-scoped Realtime invalidation
 -> authorized order refetch
```

## Payment boundary

There is no trusted payment processor state. Current live ordering remains explicit `Pay at counter` / unpaid.

## Validation

TASK-MENU-CUSTOMIZATION-001 Dashboard validation passed lint, typecheck, 129/129 Vitest tests, production build and Playwright 10/10, plus 1366x768 and 1440x900 UI QA with no task-related console errors.

Detailed cross-repository evidence: `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`.

## Deferred data flows

Loyalty, inventory depletion, refunds, tax/accounting, reporting, branch scope/capacity/hours, terminal/sales-point authority, shifts/cash, delivery and hosted production remain separate trusted domains.


## Branch/session authority

```text
employee login/session
 -> caller JWT
 -> user_profiles
 -> employee_branch_assignments
 -> assignedBranchIds in HttpOnly-session response
```

Ordinary staff with no trusted assignment fail closed.

Branch administration:

```text
GET  /api/v1/branches
 -> list_branches

GET  /api/v1/admin/branches
POST /api/v1/admin/branches/save
 -> Admin session
 -> list_admin_branches / save_branch

GET  /api/v1/admin/employees
POST /api/v1/admin/employees/branches
 -> Admin session
 -> list_admin_employees / save_employee_branch_assignments
```

Order operations now apply branch authorization server-side:

```text
orders.branch_id
 + employee_branch_assignments
 -> list_orders / get_order / transition_order_status
```

Current POS placement resolves the active default branch for backward compatibility. Explicit selected-branch POS/customer payloads are not implemented yet.
