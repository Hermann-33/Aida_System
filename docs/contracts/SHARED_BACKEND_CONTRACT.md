# Shared Backend Contract

Updated: 2026-08-23

## Authority

Supabase Auth/Postgres/RLS plus controlled RPC/BFF operations are authoritative. Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/` unless a future accepted ADR changes ownership.

Neither frontend is authority for identity, role, member IDs/codes, catalogue IDs/prices, product-option validity, add-on compatibility, order totals/numbers, scheduling preparation authority, fulfilment status, payment state, loyalty, inventory or reporting truth.

## Identity / member contract

- Supabase Auth identity is trusted user identity.
- `user_profiles.app_role` plus `disabled_at` are trusted employee/Admin authorization state.
- `members` is trusted customer membership state.
- Public signup cannot self-assign employee/Admin role, member code or verification outcome.
- Customer reads remain owner-scoped; employee/Admin access uses explicit trusted boundaries.
- Employee identities remain distinct from customer/member records.

Deferred terminal/branch/shift state is not an authorization substitute.

## Catalogue contract

### Core resources

Server-owned catalogue resources include:

- `catalogue_categories`;
- `catalogue_items`;
- `catalogue_item_variants`;
- `catalogue_item_addons`;
- `catalogue_option_groups`;
- `catalogue_option_values`;
- `catalogue_item_option_values`;
- `catalogue_revision`;
- `catalogue_audit_events`.

Category/item/variant/add-on/option IDs are server UUIDs. Money and all deltas are integer sen.

Customer/public reads use `get_catalogue()` under RLS. Admin/Owner writes use the accepted catalogue mutation RPCs through the authenticated caller boundary. `catalogue_revision` is invalidation only; clients refetch authoritative state after it changes.

Unpublished and unavailable remain different concepts. Unpublished items are removed from the customer-visible catalogue; unavailable products/options are sold-out/disabled state.

### Product versus add-on

`catalogue_items.kind` remains `product | addon`.

Add-ons are reusable catalogue items but are not standalone customer browse products. A product may expose only add-ons linked through `catalogue_item_addons`; category membership never authorizes an add-on.

Each cart/order line owns its own selected add-on IDs. Selecting Boba/Oat Milk/etc. on one drink must not mutate another drink configuration.

### Drink option groups

`catalogue_items.is_drink` marks products that receive catalogue option groups.

Current standard reusable groups are:

```text
Temperature
- Hot
- Iced

Sweetness
- Regular
- Less sweet
- Least sweet
```

Per item, `catalogue_item_option_values` controls:

- customer-facing label override;
- price delta;
- availability;
- default;
- sort order.

For every active required group on a drink there must be at least one available option and exactly one available default.

Admin/Owner may edit these values through `save_catalogue_item(jsonb)`. Customer/POS clients may only consume the resulting catalogue snapshot; they do not gain mutation authority.

## Order / quote contract

ADR-0010 and `ORDER_AND_SCHEDULING_CONTRACT.md` define detailed order identity, scheduling and fulfilment behavior.

### Trusted client intent

An order line may submit only selection/intent fields:

```text
itemId
variantId when required
addOnIds[]
optionValueIds[]
quantity
note
```

Placement additionally carries `clientRequestId`; the order intent carries `fulfillmentType = asap | scheduled` and `requestedPickupAt` only when scheduled.

Clients must not submit or trust their own:

- item/variant/add-on/option labels;
- option/add-on price deltas;
- unit prices/subtotals/totals;
- customer/member identity;
- order number;
- `prepareAt` / `scheduleState`;
- fulfilment status;
- payment state.

### Authoritative modifier validation/pricing

`quote_order(jsonb)` re-checks:

- product publication/availability and active category;
- variant ownership/availability;
- add-on compatibility/publication/availability;
- drink option ownership, active group/value state and per-item availability;
- duplicate option/add-on rejection;
- no more than one selected value from a required option group;
- quantity/note bounds;
- server scheduling policy.

If a drink request omits a required group, the deployed quote function resolves the configured available default. This keeps older clients compatible while retaining server authority.

The current quote contract uses `pricingVersion=2` and derives:

```text
base product price
+ variant price delta
+ selected/default option deltas
+ compatible add-on prices
= authoritative unit price
```

Client-supplied commercial fields are ignored/not used as authority.

### Persistence / immutable snapshots

Customer placement uses `place_customer_order(jsonb)` and derives customer/member identity from the authenticated session and active member row.

POS placement uses `place_pos_order(jsonb)` and requires staff-or-above. Current POS remains guest-order placement unless a future trusted customer-attachment domain is approved.

Persisted resources include:

- `orders`;
- `order_lines`;
- `order_line_addons`;
- `order_line_options`;
- `order_events`.

`order_lines.option_total_sen` stores the authoritative option contribution. `order_line_options` snapshots selected option group/value IDs, codes, labels and price deltas. Later catalogue label/price/availability changes do not rewrite historical order truth.

## Scheduling contract

Current live policy verified 2026-08-23:

```text
timezone: Asia/Kuala_Lumpur
scheduleEnabled: true
minimumLeadMinutes: 15
preparationLeadMinutes: 15
slotIntervalMinutes: 15
maximumAdvanceDays: 7
```

`minimumLeadMinutes` governs the earliest customer-selectable pickup. `preparationLeadMinutes` governs the server-owned operational window and satisfies:

```text
0 <= preparationLeadMinutes <= minimumLeadMinutes
```

For scheduled orders the backend persists immutable:

```text
prepareAt = requestedPickupAt - preparationLeadMinutes
```

Authorized order snapshots expose server-owned `prepareAt`, `serverNow`, and `scheduleState = future | due | overdue | null`.

This classification never auto-mutates fulfilment state.

Branch-specific opening hours, closures and capacity are still not authoritative and must not be invented by clients.

## Fulfilment contract

Persisted states remain:

`confirmed`, `scheduled`, `preparing`, `ready`, `completed`, `cancelled`.

Legal staff transitions remain:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

`completed` and `cancelled` are terminal. Status mutation requires staff-or-above and expected `statusVersion`; stale transitions fail.

Reaching `prepareAt` does not persist `preparing`. A staff action still performs **Start preparing**.

## Realtime contract

`supabase_realtime` publishes the current mutable signals:

- `catalogue_revision`;
- `orders`.

Customer clients use Realtime as invalidation and refetch authorized snapshots. Immutable line/add-on/option snapshot tables are not separate client-authority streams.

Dashboard React does not expose the employee access token for direct Supabase Realtime. Employee order work uses the same-origin BFF with polling/refetch.

## Dashboard BFF contract

Privileged Dashboard flows follow ADR-0008:

- HttpOnly employee access/refresh cookies;
- Secure cookies on HTTPS;
- trusted role/disabled-state validation;
- caller JWT forwarded to Supabase;
- same-origin state-change protection;
- no browser-readable employee bearer-token persistence;
- no service-role credential in Vite/browser code.

Catalogue Admin mutations remain Admin/Owner-only. Staff can use POS/order capabilities but cannot use Admin catalogue mutation.

Current accepted operational scope remains single-café/global staff visibility because branch/terminal/sales-point/shift authority is deferred.

## Customer client contract

Customer Flutter:

- uses only public/publishable Supabase configuration;
- consumes `get_catalogue()` and revision invalidation;
- filters add-on rows/categories from customer browse while retaining them for compatible customization;
- stages variants, option IDs and compatible add-on IDs per cart line;
- keeps differently configured copies of the same product distinct;
- labels cart values as estimates and quotes before placement;
- treats server totals as authority;
- uses customer-facing `Now` while retaining wire value `asap`;
- derives Schedule choices only from backend policy;
- keeps one `clientRequestId` for retry of the same intended placement;
- clears the cart only after persisted success;
- reads persisted history/detail/status and uses owner-scoped order Realtime as invalidation.

After `Add to cart`, item detail returns to Menu; this is navigation/presentation only and does not alter backend authority.

## POS client contract

Dashboard POS maps the shared catalogue into:

- required single-choice variants when present;
- required single-choice Temperature/Sweetness groups;
- optional multi-select compatible add-ons.

Unavailable options remain disabled and must not be submitted. POS sends IDs/quantity/note/fulfilment intent only and renders server quote as commercial authority.

## Payment boundary

There is still no trusted payment processor/payment-settlement state. Current UI remains explicit `Pay at counter` / unpaid. Order completion means fulfilment completion, not verified payment settlement.

## TASK-MENU-CUSTOMIZATION-001 validation evidence

Detailed evidence:

`docs/context/MENU_CUSTOMIZATION_2026-08-23.md`

Live closeout checks confirm:

- catalogue revision 130;
- 11 drinks / 4 non-drink products / 4 add-ons;
- zero required drink groups with missing/ambiguous available default;
- no current Iced Drinks product exposes Hot as available;
- required public/authenticated function/table grants are present;
- ordinary authenticated users have no direct read grant on `order_line_options`;
- security advisor has no new task-related WARN/ERROR.

Customer executable validation: analyze PASS, 55/55 tests PASS, exact-size UI/golden review PASS.

Dashboard executable validation: lint/typecheck/build PASS, Vitest 129/129 PASS, Playwright 10/10 PASS, desktop UI/theme review PASS.

## Deferred downstream authority

Separate bounded tasks remain:

- branch-specific catalogue/scheduling/capacity and branch-scoped access;
- terminal/sales-point authority;
- shifts/cash reconciliation;
- payment capture/refunds;
- loyalty earning/redemption;
- inventory depletion;
- promotions/discounts;
- tax/accounting/reporting;
- delivery;
- hosted production operations.


## Branch identity and operational scope

Trusted branch entities:

```text
branches
employee_branch_assignments
orders.branch_id
```

### Branch invariants

- branch IDs are server-owned UUIDs;
- branch codes are unique stable operational codes;
- exactly one active default branch exists in the current compatibility model;
- order branch identity is immutable after placement;
- ordinary staff may operate only assigned branches;
- Admin/Owner are global operational roles until a later ADR narrows them.

### Branch RPCs

```text
list_branches()
list_admin_branches()
save_branch(jsonb)
list_admin_employees()
save_employee_branch_assignments(uuid, uuid[])
```

Public/customer branch access is read-only and active-only. Branch and employee-assignment mutation is Admin/Owner-authorized.

### Order compatibility

Current customer and POS request payloads remain:

```text
fulfillmentType
requestedPickupAt?
items[]
clientRequestId
```

They do not yet carry a trusted `branchId`. Placement resolves the active default branch server-side.

Order snapshots now additionally expose:

```text
branchId
branch {
  id
  code
  name
  timezone
}
```

Future explicit branch selection is a coordinated contract change and must validate branch availability and actor/customer rules at the server boundary.
