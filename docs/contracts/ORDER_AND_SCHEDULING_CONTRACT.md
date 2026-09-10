# Order and Scheduling Contract

**Updated:** 2026-08-23
**Current task extension:** `TASK-MENU-CUSTOMIZATION-001`
**Status:** COMPLETE.

ADR-0010 remains authoritative for order identity, server quote/persistence, scheduling and fulfilment-state ownership. TASK-MENU-CUSTOMIZATION-001 extends each line's trusted selection model with catalogue option IDs and immutable option snapshots; it does not change the persisted fulfilment state machine.

## Backend authority

Live Supabase project: `eswovqxqzfevcdwwcmuh`.

Canonical migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

Relevant order/customization migrations:

- `20260812182212_create_authoritative_orders_and_scheduling.sql`
- `20260812183029_index_order_foreign_keys.sql`
- `20260820151421_add_scheduled_order_preparation_window.sql`
- `20260822135421_add_drink_customization_catalogue.sql`
- `20260822135602_integrate_drink_customizations_with_orders.sql`
- `20260822141814_harden_drink_customization_indexes_and_rls.sql`
- `20260822143542_grant_public_drink_customization_reads.sql`

Persistent order resources:

- `order_schedule_settings`;
- `orders`;
- `order_lines`;
- `order_line_addons`;
- `order_line_options`;
- `order_events`.

Realtime publication remains `catalogue_revision` + `orders`.

## Trusted order payload

Clients submit selection and fulfilment intent only:

```json
{
  "clientRequestId": "UUID-required-for-placement",
  "fulfillmentType": "asap | scheduled",
  "requestedPickupAt": "ISO-8601 timestamp only when scheduled",
  "items": [
    {
      "itemId": "product UUID",
      "variantId": "variant UUID when required",
      "optionValueIds": ["drink option-value UUID"],
      "addOnIds": ["compatible add-on UUID"],
      "quantity": 1,
      "note": "optional <= 300 chars"
    }
  ]
}
```

Clients do not submit trusted product/variant/add-on/option labels, price deltas, unit prices, subtotals, totals, member/customer IDs, order numbers, `prepareAt`, `scheduleState`, fulfilment status, role or payment state.

Customer-facing `Now` is presentation only. The trusted fulfillment enum remains `asap` for immediate orders.

## Authoritative quote / customization resolution

`quote_order(jsonb)` remains the shared commercial/scheduling validator for customer and POS.

For each line it revalidates:

- product exists, is `kind=product`, published and available under active category;
- variant ownership/availability when variants exist;
- add-on IDs are unique, linked to that product, published and available;
- option IDs are unique and belong to that drink;
- option group/value and per-item option are active/available;
- at most one selected option belongs to each required group;
- quantity and note bounds;
- requested pickup against server scheduling policy.

### Required option defaults / older clients

If the item is a drink and a required active group has no explicit selection, the deployed quote function resolves that group's configured available default.

This means an older APK that sends no `optionValueIds` can still place a drink order using server-owned defaults, provided every required group has a valid available default.

If no available default exists, quote fails closed rather than inventing client state.

### Pricing version 2

Current quote responses use:

```text
pricingVersion = 2
```

Authoritative unit price:

```text
basePriceSen
+ variant.priceDeltaSen
+ sum(selected/default option priceDeltaSen)
+ sum(compatible add-on priceSen)
= unitPriceSen
```

`lineTotalSen = unitPriceSen * quantity` and order subtotal/total are server-derived.

Client-computed prices remain estimates only.

## Immutable line snapshots

`order_lines` stores:

- base product snapshot;
- variant snapshot;
- add-on total;
- option total (`option_total_sen`);
- authoritative unit/line totals;
- quantity/note.

`order_line_addons` snapshots selected compatible add-ons.

`order_line_options` snapshots, per selected/default option:

- catalogue option group ID;
- catalogue option value ID;
- group code/name;
- option code/customer-facing label;
- accepted price delta.

Historical orders therefore do not change when Admin later renames/disables/reprices a Temperature/Sweetness option.

## Per-line independence

Modifier state is line-scoped.

These are distinct intended configurations:

```text
Latte · Hot · Regular · no Boba
Latte · Iced · Less sweet · Boba
```

Customer and POS carts must keep option/add-on IDs in their line identity/equivalence logic so editing one configuration does not merge/mutate the other.

## Scheduling policy

Read RPC: `get_ordering_policy()`.

Current live policy verified 2026-08-23:

```text
timezone: Asia/Kuala_Lumpur
scheduleEnabled: true
minimumLeadMinutes: 15
preparationLeadMinutes: 15
slotIntervalMinutes: 15
maximumAdvanceDays: 7
```

`minimumLeadMinutes` controls the earliest scheduled pickup.

`preparationLeadMinutes` controls the server-owned operational preparation window and satisfies:

```text
0 <= preparationLeadMinutes <= minimumLeadMinutes
```

Branch hours/closures/capacity remain unimplemented and must not be fabricated by clients.

## Scheduled-order preparation snapshot

For scheduled orders:

```text
prepareAt = requestedPickupAt - preparationLeadMinutes
```

`prepareAt` is backend-generated, null for ASAP orders, immutable after placement and unaffected by later policy edits.

Authorized snapshots expose:

```text
prepareAt
serverNow
scheduleState = future | due | overdue | null
```

For persisted `status=scheduled`:

```text
requestedPickupAt < serverNow -> overdue
prepareAt <= serverNow         -> due
otherwise                      -> future
```

`scheduleState` is operational classification, not a persisted lifecycle state.

## Persisted fulfilment state machine

Initial persisted state remains:

```text
asap      -> confirmed
scheduled -> scheduled
```

Legal staff transitions remain:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready     -> completed
```

`completed` and `cancelled` are terminal.

No timer/migration/client auto-transitions scheduled work to `preparing`. **Start preparing** remains an authorized staff action with expected `statusVersion`.

## Customer client requirements

Customer Flutter must:

- load variants/customization groups/compatible add-ons from the shared catalogue;
- filter add-on rows from normal customer browse;
- retain one selected available option per required group;
- keep configured option/add-on IDs per cart line;
- include option deltas only in a labelled local estimate;
- send `optionValueIds` and `addOnIds` to quote/place without commercial fields;
- quote before placement and display server total as authority;
- use `Now` presentation for `asap`;
- derive Schedule values only from `OrderingPolicy` / `derivePickupSlots`;
- reuse `clientRequestId` for retry of the same intended placement;
- clear cart only after persisted placement.

`Add to cart` returning to Menu is a UI-navigation decision only.

## Dashboard / POS requirements

Existing same-origin order endpoints remain:

```text
GET  /api/v1/orders/policy
GET  /api/v1/orders
GET  /api/v1/orders/detail?id=<uuid>
POST /api/v1/orders/quote
POST /api/v1/orders/place
POST /api/v1/orders/status
POST /api/v1/admin/orders/policy
```

Dashboard BFF forwards the authenticated caller JWT and never exposes a service-role credential or employee bearer token to React.

POS modifier groups map as:

```text
variant                   required single choice when present
Temperature/Sweetness     required single choice
compatible add-ons        optional multi-select
```

Unavailable options remain disabled and must not be sent. POS line-to-order mapping emits only item/variant/option/add-on IDs, quantity and note.

Operational Active/Scheduled/Ready/History classification continues to consume backend `scheduleState` and does not derive trusted state from workstation time.

## Payment boundary

There is still no trusted payment processor/payment settlement. Current flow remains explicit `Pay at counter` / unpaid. Fulfilment completion does not prove payment settlement.

## Verification

Detailed closeout evidence:

`docs/context/MENU_CUSTOMIZATION_2026-08-23.md`

Live closeout checks confirm:

- `pricingVersion=2` in deployed `quote_order` definition;
- all current required drink groups have at least one available option and exactly one available default;
- current Iced Drinks have Hot unavailable;
- public/authenticated quote execution and option-catalogue reads are granted as intended;
- immutable `order_line_options` has no ordinary authenticated direct read grant;
- Supabase security advisor has no new task-related WARN/ERROR.

Customer executable evidence: analyze PASS, 55/55 tests PASS, option/cart/order regressions and UI/golden QA PASS.

Dashboard executable evidence: lint/typecheck/build PASS, Vitest 129/129, Playwright 10/10, POS/Admin UI/theme QA PASS.

The final database connector is read-only and cannot impersonate `anon`; closeout therefore inspected the deployed quote/default function definition instead of creating synthetic production orders.

## Deferred domains

Still separate bounded tasks:

- branch-specific hours/closures/capacity;
- branch-scoped order visibility;
- terminal/sales-point authority;
- shifts/cash authority;
- payment/refunds;
- loyalty;
- inventory;
- promotions/discounts;
- tax/accounting/reporting;
- delivery;
- hosted production operations.


## Branch authority extension

Every persisted order now has immutable trusted `branch_id`.

Order snapshots expose:

```text
branchId
branch.id
branch.code
branch.name
branch.timezone
```

For current backward compatibility, `quote_order` and placement payloads do not yet require a branch selector. `place_customer_order` and `place_pos_order` persist the active default branch through the server-owned order path.

Ordinary staff queue access and `transition_order_status` are authorized against `employee_branch_assignments`. Admin/Owner remain global operational roles for this tranche.

Branch opening hours, closures, capacity and branch-specific schedule policy remain unimplemented. The existing singleton scheduling policy therefore still governs accepted pickup times until a later branch-scheduling contract supersedes it.
