# Order and Scheduling Contract

**Updated:** 2026-09-11  
**Current extension:** `TASK-OPS-002 — Phase 1 operational topology`  
**Status:** `COMPLETE`

ADR-0010 remains authoritative for order identity, quote/persistence, scheduling and fulfilment. ADR-0011 and ADR-0012 extend the trusted order boundary with branch scope plus sales-point/terminal authority.

## Trusted order intent

Clients submit selection and fulfilment intent only:

```text
clientRequestId
fulfillmentType = asap | scheduled
requestedPickupAt? 
items[]:
  itemId
  variantId?
  optionValueIds[]
  addOnIds[]
  quantity
  note?
```

Clients are not authority for labels, prices, totals, customer/member identity, order number, `prepareAt`, `scheduleState`, fulfilment status, payment state, branch scope or sales-point/terminal attribution.

Customer-facing `Now` maps to wire value `asap`.

## Quote/pricing authority

`quote_order(jsonb)` validates current product/category availability, variants, required/default options, compatible add-ons, quantity/note bounds and scheduling policy.

Current pricing contract:

```text
pricingVersion = 2
base + variant delta + option deltas + add-ons = authoritative unit price
```

If an older client omits a required option group, the backend resolves the configured available default. Invalid/missing authority fails closed.

## Immutable commercial snapshots

Persisted order resources:

```text
orders
order_lines
order_line_addons
order_line_options
order_events
```

Accepted item/variant/add-on/option labels and prices are snapshotted so later catalogue edits do not rewrite historical orders.

## Branch authority

Every order has immutable trusted `branch_id`.

Ordinary staff order reads/transitions require trusted assignment to the order branch. Admin/Owner remain global operational roles for the current tranche.

Customer requests do not yet submit trusted branch selection; current placement resolves the active default branch server-side. Explicit customer pickup-branch choice is Phase 4.

## Customer placement

`place_customer_order(jsonb)`:

- derives customer/member identity from Auth;
- resolves current active default branch server-side;
- remains idempotent through `clientRequestId`;
- persists no sales-point or terminal attribution.

Customer snapshots therefore have:

```text
branchId = trusted default branch
salesPointId = null
terminalId = null
```

## POS placement — Phase 1

Credentialless placement is not a live authenticated capability:

```text
place_pos_order(jsonb)         authenticated execute: false
```

Live POS uses:

```text
place_pos_order(jsonb, text terminalCredential)
```

The backend resolves the terminal credential and validates:

- authenticated employee role/disabled state;
- terminal credential validity/revocation;
- terminal active state;
- sales-point and branch active state;
- terminal -> sales point -> branch relationship;
- employee permission to operate the resolved branch.

The browser does not submit trusted branch/sales-point/terminal IDs for placement.

Accepted POS orders persist immutable:

```text
branchId
salesPointId
terminalId
branch { ... }
salesPoint { ... }
terminal { ... }
```

A terminal credential is stored only by the Dashboard BFF in an HttpOnly cookie and forwarded server-side.

## Terminal lifecycle effect on ordering

A manager issues a one-time terminal enrolment code. Successful authorized enrolment activates the terminal and returns the credential once.

Removing employee branch scope prevents that employee from resolving/using a terminal in the removed branch. Terminal revocation immediately prevents credential resolution and new POS placement.

Historical attributed orders remain unchanged after terminal revocation.

## Scheduling policy

Current live singleton policy:

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

`prepareAt` is immutable after placement. Authorized snapshots expose server-owned `serverNow` and `scheduleState = future | due | overdue | null`.

Branch-specific opening hours, closures and capacity are not yet authoritative and must not be fabricated by clients.

## Fulfilment state machine

Initial state:

```text
asap      -> confirmed
scheduled -> scheduled
```

Legal transitions:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready     -> completed
```

Completed/cancelled are terminal. Status mutation requires authorized branch scope and expected `statusVersion`; stale transitions fail. Time never auto-transitions an order to `preparing`.

## Dashboard order boundary

Same-origin endpoints remain the browser boundary for policy, quote, placement, order queue/detail and status transitions.

The BFF:

- validates employee session/role/disabled state;
- forwards caller JWT;
- forwards terminal credential server-side for POS placement;
- never exposes employee bearer or terminal credential to normal React state;
- uses no service-role credential for normal flows.

## Realtime boundary

Customer may use authorized Supabase Realtime only as order invalidation and then refetch trusted snapshots.

Dashboard employee order work uses BFF polling/refetch because employee tokens remain HttpOnly.

## Payment boundary

No trusted payment processor/settlement state exists. `Pay at counter` remains unpaid semantics. Fulfilment completion is not proof of settlement.

## Phase 1 verification

Backend database audit #22 rebuilt a clean Supabase environment and passed:

```text
branch authority regression              PASS
operational topology regression         PASS
order regression                         PASS
scheduled-order operations regression    PASS
```

Customer release audit #114 and Dashboard CI #23 also pass.

Detailed evidence: `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.

## Deferred order-related domains

- branch hours/closures/capacity and explicit pickup branch;
- shifts/cash and order-to-shift attribution;
- inventory depletion;
- loyalty/rewards;
- promotions/discounts;
- tax/accounting/reporting;
- payment capture/refunds;
- delivery.
