# System Map

Updated: 2026-08-23

| System | Runtime | Current trusted source |
|---|---|---|
| Customer | Flutter/Riverpod | Supabase Auth/member + shared catalogue/options + customer order RPCs |
| Dashboard/Admin/POS | React/Vite | same-origin employee BFF + shared catalogue/options/member/order RPCs |
| Backend | Supabase | Auth, Postgres, FORCE RLS, controlled RPCs, Realtime |

## Catalogue / customization flow

```text
Admin Menu editor
 -> same-origin BFF cookie session
 -> Admin/Owner caller JWT
 -> save_catalogue_item
 -> catalogue item + variants + option overrides + compatible add-ons
 -> audit + catalogue revision bump
 -> catalogue_revision Realtime
 -> clients invalidate/refetch catalogue
```

Server catalogue controls:

```text
product vs addon
isDrink
variant labels/deltas/availability/default
Temperature/Sweetness labels/deltas/availability/default
compatible add-on links
publication / availability / image / sort order
```

Current reusable drink groups:

```text
Temperature: Hot | Iced
Sweetness: Regular | Less sweet | Least sweet
```

Customer browse filters `kind=addon` rows/categories, but compatible add-ons remain available to the selected product's Customize section.

## Customer configured-item flow

```text
Menu product
 -> Item detail
 -> choose Size when applicable
 -> choose required Temperature
 -> choose required Sweetness
 -> choose optional compatible add-ons
 -> quantity / note
 -> Add to cart
 -> configured line stored locally
 -> return to Menu
```

Cart identity includes option/add-on selections. Therefore:

```text
Latte · Hot · Regular
Latte · Iced · Less sweet · Boba
```

remain distinct configurations.

The customer local price is an estimate only:

```text
base + variant + option deltas + add-ons
```

Checkout always obtains the server quote before placement.

## Customer order flow

```text
Flutter cart selections
 -> quote_order(item/variant/option/add-on IDs + qty/note/intent)
 -> server validates catalogue compatibility/availability
 -> server calculates pricingVersion=2 totals
 -> customer chooses Now or server-policy-derived Schedule
 -> place_customer_order(clientRequestId + selections)
 -> trusted customer/member derived from auth session
 -> orders + immutable order_lines/order_line_addons/order_line_options snapshots
 -> order_events(created)
 -> persisted order returned
```

Customer-facing `Now` maps to trusted wire value `asap`; it is not a new backend fulfilment type.

Older client requests that omit required option IDs are resolved by the server's configured available defaults.

## POS configured-item flow

```text
POS catalogue product
 -> variant required when present
 -> Temperature required single choice
 -> Sweetness required single choice
 -> compatible add-ons optional multi-select
 -> local estimate
 -> POST /api/v1/orders/quote
 -> employee HttpOnly session validated by BFF
 -> caller JWT -> quote_order
 -> authoritative quote
 -> POST /api/v1/orders/place
 -> place_pos_order
```

Unavailable choices remain disabled. POS order intents contain selection IDs/quantity/note, not trusted prices/totals.

## Admin option-management flow

```text
Admin -> Menu management -> Edit item
 -> Drink customization toggle
 -> group cards
    -> customer label
    -> price delta
    -> Available
    -> Default
 -> Compatible add-ons checkboxes
 -> save
```

Every active required group needs at least one available option and exactly one available default. The Admin client validates this before save; the backend validates it as trusted authority.

Preview remains read-only and does not call privileged mutation routes.

## Scheduled pickup / operational flow

```text
get_ordering_policy
 -> Asia/Kuala_Lumpur
 -> minimumLead 15
 -> preparationLead 15
 -> slots 15 minutes
 -> horizon 7 days
 -> customer/POS Schedule selection
 -> quote_order validates server time/horizon/slot
 -> scheduled order persists prepareAt/status=scheduled
```

Customer keeps the accepted tactile policy-derived wheel. Branch hours/closures/capacity are not authoritative yet.

Dashboard workload projection remains:

```text
server order snapshots
 -> scheduled + overdue/due => Active, persisted status remains scheduled
 -> scheduled + future => Scheduled
 -> ready => Ready
 -> completed/cancelled => History
 -> explicit Start preparing + expectedVersion => persisted preparing
```

## Fulfilment/status flow

```text
Dashboard order board
 -> same-origin GET /api/v1/orders
 -> staff selects legal next state
 -> POST /api/v1/orders/status + expectedVersion
 -> transition_order_status
 -> statusVersion changes + order_events append
 -> customer receives owner-scoped orders Realtime invalidation
 -> Flutter authorized refetch
```

Legal flow remains `confirmed|scheduled -> preparing -> ready -> completed`, with cancellation allowed before ready. Completed/cancelled remain terminal.

## Realtime / employee token boundary

Customer Flutter may use its Supabase session for owner-scoped Realtime invalidation.

Employee JWTs remain HttpOnly. Dashboard React does not expose a staff JWT for direct Supabase Realtime; its order workload polls/refetches the same-origin BFF and invalidates after place/status mutations.

## Live validation state

TASK-MENU-CUSTOMIZATION-001 closeout on 2026-08-23 verified:

```text
catalogue revision         130
drink products              11
non-drink products           4
add-ons                      4
invalid required groups      0
Iced Drinks with Hot on      0
```

Customer executable validation: analyze PASS, 55/55 tests PASS, exact-size UI/golden QA PASS.

Dashboard executable validation: lint/typecheck/build PASS, Vitest 129/129, Playwright 10/10, UI/theme QA PASS.

Detailed evidence: `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`.

## Deployment / deferred authority

Hosted deployment remains deferred and is not implied by local/client validation.

Real payments/refunds, loyalty, inventory, promotions/discounts, tax/accounting/reporting, branch scheduling/capacity, branch-scoped operations, terminal/sales-point lifecycle, shifts/cash reconciliation and delivery remain separate trusted tasks.


## Trusted branch scope

```text
Admin/Owner
 -> save_branch / save_employee_branch_assignments
 -> branches + employee_branch_assignments

current customer/POS placement
 -> server resolves active default branch
 -> orders.branch_id immutable

ordinary staff queue/status
 -> employee assignment
 -> matching branch order only
```

Current default:

```text
BR-MAIN — Main Café
Asia/Kuala_Lumpur
```

The current wire order intent still omits `branchId`. This is deliberate rollout compatibility, not a permanent single-branch contract. A later explicit-branch task must validate branch choice on the server before placement.

Preview sales points, terminal IDs and shift IDs remain non-authoritative.
