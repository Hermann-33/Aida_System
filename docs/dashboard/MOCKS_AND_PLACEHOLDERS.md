# POS/Admin Mocks and Placeholders Register

Updated: 2026-08-23

## Trusted current paths

These are shared/live backend integrations, not preview authority:

- protected Admin Members directory;
- Admin Menu categories/items/prices/publication/availability;
- variants/sizes;
- Drink flag and Temperature/Sweetness per-item configuration;
- compatible add-on links;
- POS catalogue browsing and modifier groups;
- authoritative POS quote/place;
- Now/scheduled pickup policy;
- scheduled preparation classification;
- Active/Scheduled/Ready/History order workloads;
- live staff Sale/Orders entry in accepted global single-café scope;
- live order queue/detail and versioned fulfilment transitions.

Preview menu/modifier/order fixtures are not runtime authority for those paths.

## Local UI state that is allowed

The browser may keep transient interaction state such as:

- current unsaved cart lines;
- selected item/variant IDs;
- selected `optionValueIds` for Temperature/Sweetness;
- selected compatible add-on IDs;
- quantity/note;
- local estimated price before quote;
- selected Now/scheduled intent;
- view/filter/dialog/loading/error state;
- one `clientRequestId` reused for retry of the same intended placement.

Local state must not become authority for modifier availability, compatibility or final prices.

## Modifier-specific boundary

Temperature/Sweetness and add-on metadata come from the shared catalogue.

The browser may render catalogue price deltas in an estimate, but `quote_order` revalidates IDs and returns authoritative `pricingVersion=2` totals.

If the Admin disables or reprices an option after a cart was staged, the client must tolerate quote rejection/repricing rather than preserving stale local truth.

Add-ons are per-line optional selections. Do not use a global add-on selection that implicitly applies to an entire sale.

## Removed order/POS preview authority

The live Sale/Orders path must not use:

- client-computed totals as final commercial truth;
- preview/local orders as persisted-order fallback;
- fake order numbers;
- fake processor/tender success;
- local-only fulfilment status;
- fake timer-driven progression;
- preview option/add-on values to bypass unavailable live catalogue state.

## Admin preview boundary

UI Preview may inspect the public catalogue but is read-only. It must not expose or simulate successful Admin catalogue mutation.

Real option/add-on edits require the authenticated Admin/Owner BFF/RPC path.

## Payment boundary

No trusted processor exists. Use explicit `Pay at counter` / unpaid semantics. Preview tender/payment UI is never settlement evidence.

## Still preview/deferred

- loyalty/rewards;
- terminal/device enrolment authority;
- shift/cash authority;
- POS Member, Shift and Terminal preview rails;
- branch/branch-scope and deeper employee-management mutation;
- inventory/depletion;
- marketing publication;
- payment/refunds;
- tax/accounting;
- sales/revenue reporting;
- branch opening-hours/capacity scheduling;
- many settings/integration/audit presentation surfaces;
- hosted production operations.

TASK-MENU-CUSTOMIZATION-001 closeout and executable validation are documented in `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`.


## Branch authority boundary

The following branch data is now trusted backend state rather than preview-only:

- branch UUID/code/name/timezone/active/default state;
- employee-to-branch assignments;
- order `branchId` / branch snapshot;
- ordinary staff branch authorization.

Dashboard same-origin endpoints now exist for the public branch directory, Admin branch directory/mutation, Admin employee directory and employee branch assignments.

Still preview-only:

- the current Admin Locations and Employees screen state until those components consume the BFF APIs;
- sales-point definitions;
- terminal lists/device enrolment;
- branch opening-hours/capacity presentation;
- inventory-pool labels in `PREVIEW_ORG`.

Do not copy the fixture IDs such as `br-main`, `sp-main` or `POS-MAIN-01` into trusted backend records.
