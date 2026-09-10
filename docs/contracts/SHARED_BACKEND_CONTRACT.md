# Shared Backend Contract

Updated: 2026-09-11

## Authority

Supabase Auth/Postgres/FORCE-RLS plus controlled RPC/BFF operations are authoritative. Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/` unless a future accepted ADR changes ownership.

Neither frontend is authority for:

- authenticated identity or employee role/disabled state;
- member IDs/codes;
- employee branch scope;
- branch, sales-point or terminal identity;
- terminal credential validity;
- catalogue IDs, availability, prices or modifier compatibility;
- order prices/totals/numbers/status;
- scheduling preparation authority;
- payment settlement;
- loyalty, inventory, promotions, shifts/cash or reporting truth.

## Identity/member contract

- Supabase Auth identity is trusted user identity.
- `user_profiles.app_role` plus `disabled_at` are trusted employee/Admin authorization state.
- `members` is trusted customer membership state.
- Public signup cannot self-assign employee/Admin role, member code, verification outcome or branch scope.
- Employee identities remain distinct from customer/member records.
- Customer reads remain owner-scoped.
- Dashboard employee access uses the same-origin BFF and caller JWT.

## Employee operational-scope contract

Trusted operational branch scope is stored in `employee_branch_assignments`.

- ordinary `staff` may operate only assigned branches;
- ordinary staff with no assignment fail closed;
- `admin` and `owner` remain global operational roles for the current tranche;
- role/disabled state and branch assignment are evaluated by the backend, never browser claims or preview fixtures.

## Catalogue contract

Server-owned resources include:

```text
catalogue_categories
catalogue_items
catalogue_item_variants
catalogue_item_addons
catalogue_option_groups
catalogue_option_values
catalogue_item_option_values
catalogue_revision
catalogue_audit_events
```

Category/item/variant/add-on/option IDs are server UUIDs. Money and price deltas are integer sen.

`catalogue_items.kind = product | addon`. Add-ons are reusable catalogue rows but are not standalone customer browse products. Compatibility is controlled by `catalogue_item_addons`.

`catalogue_items.is_drink` marks products that consume reusable option groups. Current standard groups are:

```text
Temperature: Hot | Iced
Sweetness: Regular | Less sweet | Least sweet
```

Every active required group on a drink must have at least one available option and exactly one available default.

Customer/public reads use `get_catalogue()`. Admin/Owner writes use controlled catalogue mutation RPCs through the BFF caller-JWT boundary. `catalogue_revision` is invalidation only.

## Branch contract

Trusted branch resources:

```text
branches
employee_branch_assignments
orders.branch_id
```

Invariants:

- branch IDs are server-owned UUIDs;
- branch codes are stable unique operational codes;
- current compatibility model has exactly one active default branch;
- every persisted order has non-null immutable `branch_id`;
- ordinary staff order access and fulfilment transitions are branch-scoped;
- current customer placement resolves the active default branch server-side;
- explicit customer pickup-branch selection remains a coordinated Phase 4 contract change.

Public branch directory reads expose active branch information only. Admin/Owner mutation uses controlled RPCs.

## Sales-point/terminal contract — Phase 1

Trusted operational topology resources:

```text
sales_points
terminals
private.terminal_enrolment_codes
private.terminal_credentials
orders.sales_point_id
orders.terminal_id
```

A sales point belongs to exactly one branch. A terminal belongs to exactly one sales point. The backend validates these relationships.

Live seed topology:

```text
BR-MAIN — Main Café
  SP-MAIN — Main Counter
    POS-MAIN-01
```

The seeded terminal remains `pending` until a manager explicitly enrols it.

### Terminal enrolment

Manager/Admin operational flow:

```text
trusted terminal row
 -> issue one-time enrolment code
 -> staff/manager enters code on workstation
 -> enrol_terminal(code)
 -> backend validates employee may operate terminal branch
 -> terminal becomes active
 -> one terminal credential is returned
 -> Dashboard BFF stores credential in HttpOnly cookie
```

Enrolment-code possession alone is not authorization. Caller identity/role/branch scope is revalidated by Supabase before the code can activate a terminal.

Codes are one-time and expiry-bound. Failed authorization must not consume the code.

### Terminal credential

The terminal credential is not exposed to normal React state. It is stored by the Dashboard BFF in an HttpOnly cookie and forwarded server-side only to the terminal RPC/order boundary.

`resolve_terminal_credential(text)` validates:

- credential hash exists and is not revoked;
- terminal status is active and not revoked;
- sales point is active;
- branch is active;
- topology relationships are intact;
- caller employee is valid;
- caller may operate the resolved branch.

Removing staff branch scope invalidates terminal resolution for that staff member immediately even when the terminal credential itself remains active.

Revoking the terminal invalidates credential resolution and POS placement immediately.

### Operational topology reads/writes

`branches`, `sales_points` and `terminals` remain FORCE-RLS protected.

`authenticated` has SELECT privilege on `sales_points` and `terminals` only so the `SECURITY INVOKER` Admin topology RPC can read them. Existing RLS policies restrict those rows to Admin/Owner. Anonymous SELECT is denied.

Browser roles retain no direct INSERT/UPDATE/DELETE authority on branches, sales points or terminals. Mutations use controlled RPCs through the BFF.

## Order/quote contract

ADR-0010 and `ORDER_AND_SCHEDULING_CONTRACT.md` define detailed commercial/scheduling/fulfilment behavior.

An order line may submit selection/intent only:

```text
itemId
variantId?
addOnIds[]
optionValueIds[]
quantity
note?
```

Placement additionally carries `clientRequestId`; fulfilment carries `fulfillmentType = asap | scheduled` and `requestedPickupAt` only when scheduled.

Clients must not submit or trust their own labels, price deltas, unit prices, totals, customer/member identity, branch/sales-point/terminal authority, order number, `prepareAt`, `scheduleState`, fulfilment status or payment state.

`quote_order(jsonb)` revalidates publication/availability, variants, compatible add-ons, drink-option ownership/availability, quantity/note bounds and scheduling policy.

If a required drink group is omitted, the backend resolves its configured available default. Current pricing contract is `pricingVersion=2`:

```text
base product
+ variant delta
+ selected/default option deltas
+ compatible add-ons
= authoritative unit price
```

## Customer placement contract

`place_customer_order(jsonb)`:

- derives customer/member identity from the authenticated session;
- resolves current active default branch server-side;
- does not accept trusted sales-point/terminal authority;
- persists `sales_point_id = null` and `terminal_id = null`;
- remains idempotent through `clientRequestId`.

## POS placement contract

The previous credentialless signature is not executable by `authenticated`:

```text
place_pos_order(jsonb)        authenticated execute: false
```

The live POS contract is:

```text
place_pos_order(jsonb, text terminal_credential)
```

The terminal-bound function:

- validates staff-or-above identity/disabled state;
- resolves terminal/sales point/branch from the credential;
- validates employee branch scope;
- validates terminal/sales-point/branch active state;
- quotes the order authoritatively;
- persists immutable branch/sales-point/terminal attribution;
- preserves `clientRequestId` idempotency within trusted placement authority.

Browser-supplied location IDs cannot replace terminal credential authority.

## Immutable order snapshots

Persisted order resources include:

```text
orders
order_lines
order_line_addons
order_line_options
order_events
```

Historical commercial labels/prices/options remain immutable snapshots. Operational topology attribution on an accepted order is also immutable.

Order snapshots expose trusted branch data and, when applicable, trusted sales-point/terminal data.

## Scheduling contract

Current policy:

```text
timezone: Asia/Kuala_Lumpur
scheduleEnabled: true
minimumLeadMinutes: 15
preparationLeadMinutes: 15
slotIntervalMinutes: 15
maximumAdvanceDays: 7
```

For scheduled orders:

```text
prepareAt = requestedPickupAt - preparationLeadMinutes
```

Order snapshots expose server-owned `prepareAt`, `serverNow`, and `scheduleState = future | due | overdue | null`.

Time classification never auto-mutates persisted fulfilment status.

Branch-specific opening hours, closures and capacity are still not authoritative and must not be invented by clients.

## Fulfilment contract

Persisted states:

```text
confirmed
scheduled
preparing
ready
completed
cancelled
```

Legal staff transitions:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

`completed` and `cancelled` are terminal. Status mutation requires authorized staff scope and expected `statusVersion`; stale transitions fail.

## Dashboard BFF contract

Privileged Dashboard flows follow ADR-0008:

- HttpOnly employee access/refresh cookies;
- Secure cookies on HTTPS;
- HttpOnly terminal credential cookie;
- trusted role/disabled/branch validation;
- caller JWT forwarded to Supabase;
- terminal credential forwarded server-side only where required;
- same-origin state-change protection;
- no browser-readable employee bearer token;
- no service-role credential in browser/Vite code.

Admin Locations, Terminals and Employees consume trusted APIs in live mode. UI Preview may retain fixtures but remains explicitly non-authoritative.

## Realtime contract

Customer clients may use their Supabase session for authorized catalogue/order invalidation and then refetch authoritative snapshots.

Dashboard React does not expose employee access tokens for direct Supabase Realtime. Employee operational flows use same-origin BFF polling/refetch.

## Payment boundary

No trusted payment processor or settlement authority exists yet. Current UI remains `Pay at counter` / unpaid semantics. Fulfilment completion is not proof of payment settlement.

## Phase 1 validation boundary

Full closeout evidence:

`docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

Current executable evidence:

```text
Backend database audit #22      PASS
Customer release audit #114     PASS
Dashboard CI #23                PASS
```

The clean database audit passed branch authority, operational topology, general order and scheduled-order integration regressions.

## Deferred downstream authority

Separate bounded tasks remain:

- shifts/cash reconciliation;
- employee Auth-user provisioning/role mutation/badge-PIN lifecycle;
- branch hours/closures/capacity and explicit customer branch selection;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- tax/accounting/reporting;
- real payment capture/refunds;
- printer/KDS/payment-device integrations;
- delivery;
- hosted production operations.
