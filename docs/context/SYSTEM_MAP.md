# System Map

Updated: 2026-09-11

| System | Runtime | Trusted source |
|---|---|---|
| Customer | Flutter/Riverpod | Supabase Auth/member + catalogue + customer order RPCs |
| Dashboard/Admin/POS | React/Vite | same-origin employee/terminal BFF + caller-JWT RPCs |
| Backend | Supabase | Auth, Postgres, FORCE RLS, controlled RPCs, Realtime invalidation |

## Customer catalogue/order flow

```text
get_catalogue
 -> products / variants / required drink options / compatible add-ons
 -> customer configures local cart line
 -> quote_order
 -> Supabase validates selections and calculates pricingVersion=2 total
 -> place_customer_order
 -> backend derives authenticated customer/member + default branch
 -> immutable order commercial snapshot
```

Customer request data is selection intent only. Labels, prices, totals, identity, branch authority and order state remain server-owned.

Current customer fulfilment labels are `Now | Schedule`; `Now` maps to wire value `asap`.

## Admin catalogue flow

```text
Admin browser
 -> same-origin employee session
 -> BFF validates role/disabled state
 -> caller JWT
 -> save_catalogue_item
 -> catalogue rows + audit event + revision bump
 -> clients invalidate/refetch
```

Preview remains read-only and is never privileged catalogue authority.

## Trusted operational topology — Phase 1

```text
branches
  -> sales_points
      -> terminals

employee_branch_assignments
  -> ordinary staff branch scope

manager-issued one-time enrolment code
  -> terminal enrolment
  -> terminal credential
  -> HttpOnly Dashboard/POS cookie

employee caller JWT + terminal credential
  -> place_pos_order(payload, credential)
  -> server resolves terminal
  -> validates active terminal + active sales point + branch relationship
  -> validates employee may operate branch
  -> persists immutable branch/sales-point/terminal attribution
```

Live seed topology:

```text
BR-MAIN — Main Café
  SP-MAIN — Main Counter
    POS-MAIN-01 [pending until manager enrolment]
```

Every order has trusted immutable `branch_id`. POS orders may additionally carry `sales_point_id` and `terminal_id`. Customer orders remain terminal-free.

Credentialless `place_pos_order(jsonb)` is not executable by `authenticated`. The live POS contract is `place_pos_order(jsonb,text)` through the BFF-held terminal credential.

## Dashboard operational-management flow

```text
Admin Locations
 -> branches + sales points trusted API

Admin Terminals
 -> trusted terminal list/create
 -> issue one-time enrolment code
 -> revoke terminal

Admin Employees
 -> trusted employee directory
 -> branch-assignment mutation

POS shell
 -> employee session
 -> terminal status
 -> terminal-bound order placement
```

Explicit UI Preview can still render fixture data for demonstration. Preview branch/sales-point/terminal/shift identifiers are not trusted foreign keys or backend authority.

## Scheduled pickup flow

```text
get_ordering_policy
 -> Asia/Kuala_Lumpur
 -> minimumLead 15
 -> preparationLead 15
 -> 15-minute slots
 -> 7-day horizon
 -> quote validates time/slot
 -> scheduled order persists requestedPickupAt + prepareAt
```

Branch hours, closures, capacity and explicit customer pickup-branch selection are not yet authoritative; they belong to Phase 4.

## Fulfilment/status flow

```text
Dashboard queue
 -> BFF list_orders
 -> branch authorization
 -> legal next-state action + expectedVersion
 -> transition_order_status
 -> order_events append
 -> customer owner-scoped Realtime invalidation
 -> authorized refetch
```

Legal persisted flow remains:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Completed/cancelled remain terminal. Time never auto-mutates fulfilment status.

## Realtime/session boundary

Customer Flutter may use its Supabase session for authorized Realtime invalidation.

Dashboard React never receives the employee bearer token for direct Supabase Realtime. Employee operational reads poll/refetch same-origin BFF endpoints.

## Phase 1 validation

```text
Backend database audit #22   PASS
  branch authority           PASS
  operational topology       PASS
  order regression           PASS
  scheduled order regression PASS

Customer release audit #114  PASS
Dashboard CI #23             PASS — 31 files / 150 tests
```

Full evidence: `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.

## Still deferred

- shift/cash authority;
- employee Auth-user provisioning and badge/PIN lifecycle;
- branch hours/closures/capacity and explicit customer branch selection;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- tax/accounting/reporting;
- payment capture/refunds;
- printer/KDS/payment-device integrations;
- delivery;
- hosted production/release operations.
