# System Map

Updated: 2026-09-15

| System | Runtime | Trusted source |
|---|---|---|
| Customer | Flutter/Riverpod | Supabase Auth/member + catalogue + customer order/branch RPCs |
| Dashboard/Admin/POS | React/Vite | same-origin HttpOnly employee/terminal BFF + caller-JWT RPCs |
| Backend | Supabase | Auth, Postgres, FORCE RLS, controlled RPCs, Realtime invalidation |

## Authority chain through Phase 5

```text
Phase 1 COMPLETE
branch -> sales point -> terminal -> employee branch scope -> POS attribution

Phase 2 COMPLETE
terminal + employee -> shift -> POS order / cash ledger

Phase 3 COMPLETE
customer identity -> privacy preferences / own-account deletion
                  -> anonymized retained commercial history

Phase 4 COMPLETE
active branch -> branch-local service calendar -> pickup policy -> slot capacity
              -> authoritative quote/order acceptance

Phase 5 COMPLETE
catalogue item/variant/add-on -> active recipe -> branch stock
                              -> transactional depletion / cancellation reversal
```

Supabase/server owns identity, roles, branch/terminal/shift, scheduling/capacity, catalogue/pricing, inventory/recipes, tender/payment classification, order IDs/status/commercial history and privacy/account-deletion state. Client state is intent only. Preview fixtures are never live authority.

## Customer order flow

```text
get_catalogue
 -> customer configures cart intent
 -> list_active_branches / branch pickup state / available slots
 -> quote_order
 -> server validates catalogue + branch + schedule + inventory
 -> place_customer_order
 -> server derives authenticated customer/member
 -> validates selected active branch as intent
 -> serializes scheduled slot capacity where applicable
 -> transactionally consumes recipe inventory
 -> persists immutable commercial/operational snapshot
```

Customer orders remain terminal-free and shift-free. Customer branch choice is validated intent, not trusted authority. Prices, totals, schedule acceptance, inventory sufficiency and persisted IDs remain server-owned.

## Dashboard privileged boundary

```text
React browser
 -> same-origin BFF
 -> HttpOnly employee session + HttpOnly terminal credential
 -> caller JWT + publishable Supabase key
 -> controlled RPCs
 -> Supabase authorization / branch / terminal / shift / Admin checks
```

No service-role secret, reusable employee bearer token or terminal credential is exposed to browser JavaScript.

## Phase 1 operational topology

```text
branches -> sales_points -> terminals
employee_branch_assignments -> employee operational scope
manager one-time enrolment -> terminal credential -> HttpOnly BFF cookie
```

POS placement resolves trusted branch/sales-point/terminal from the server-held terminal credential and validates employee branch scope. Accepted topology attribution is immutable. Credentialless POS placement is denied.

## Phase 2 shift/cash flow

```text
employee + terminal
 -> open/locked shift
 -> opening float
 -> append-only cash movements
 -> POS order shift/tender/payment attribution
 -> server-derived expected cash
 -> close + actual cash + variance
```

New POS placement requires the caller's matching open shift. Money is integer sen. Non-zero close variance requires Admin/Owner authority. External processor settlement/refunds remain deferred.

## Phase 3 privacy/account flow

```text
auth.uid()
 -> customer privacy preferences
 -> delete_own_account()
 -> scrub customer-authored retained free text
 -> anonymize retained customer transaction identity
 -> delete customer/member/Auth identity
```

Deletion accepts no target customer parameter. Staff/POS audit identity and non-identifying commercial facts remain preserved.

## Phase 4 branch scheduling/pickup flow

```text
active branch
 -> branch timezone
 -> weekly service windows / dated exceptions
 -> ASAP/scheduled policy
 -> lead + preparation time + horizon + slot interval
 -> scheduled slot capacity
 -> authoritative quote/place acceptance
```

The server derives `prepare_at`, rejects closed/invalid windows, and serializes scheduled branch+slot capacity before placement. POS branch remains terminal/open-shift derived. Dashboard scheduling administration stays behind the caller-JWT BFF.

## Phase 5 inventory/recipe flow

```text
catalogue item/variant/add-on
 -> active recipe
 -> recipe_components
 -> branch_inventory
 -> quote sufficiency check
 -> transactional non-negative consumption
 -> append-only inventory_movements
 -> exactly-once cancellation reversal
```

Inventory uses integer milli-units with base units `g`, `ml`, or `unit`. Quote does not reserve stock. Placement is final authority and rolls back if required stock cannot be consumed. Preview inventory is not a live fallback.

## Fulfilment/status flow

```text
Dashboard queue
 -> BFF list_orders
 -> branch authorization
 -> legal next-state + expectedVersion
 -> transition_order_status
 -> append order event
 -> customer owner-scoped invalidation/refetch
```

Persisted flow remains:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Completed/cancelled remain terminal. Time does not auto-mutate fulfilment state.

## Validation boundary

Phase 5 closeout evidence:

```text
Backend database audit #138   COMPLETE
Customer release audit #229   COMPLETE
Dashboard CI #99              COMPLETE
Supabase security advisor     COMPLETE for Phase 5
Supabase performance advisor  COMPLETE for Phase 5
```

Full evidence: `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`.

## Current boundary / deferred

Phase 6 is `PARTIAL` until loyalty/rewards/vouchers are implemented and validated. Phase 7 promotions/discounts cannot begin until Phase 6 is `COMPLETE`.

Still deferred beyond the current Phase 6 boundary:

- generalized promotions/discounts — Phase 7;
- tax/accounting/reporting — Phase 8;
- supplier purchasing, lot/expiry, forecasting and automated procurement;
- external payment capture/refunds/settlement;
- employee Auth-user/credential lifecycle;
- printer/KDS/payment-device integrations;
- delivery and deployment-heavy production infrastructure.
