# System Map

Updated: 2026-08-14

| System | Runtime | Current trusted source |
|---|---|---|
| Customer | Flutter/Riverpod | Supabase Auth/member + shared catalogue + customer order RPCs |
| Dashboard/Admin/POS | React/Vite + same-origin BFF | trusted employee session + member/catalogue/order RPCs |
| Backend | Supabase | Auth, Postgres, FORCE RLS, controlled RPCs, Realtime |

## Current validated topology

The user-validated demo topology is:

```text
Installed Android customer app
        |
        | public Supabase client / customer session
        v
Shared Supabase <------ caller JWT ------ Local Dashboard BFF
        ^                                      ^
        |                                      |
        +---- catalogue/order invalidation ----+-- React Dashboard on local PC
```

The Dashboard employee access/refresh token stays HttpOnly and is not exposed to React. The customer app uses only the public project configuration and its own authenticated customer session.

Dated closeout evidence on 2026-08-14 records 9 Auth users/profiles, 6 customer members, one owner, one admin, one staff profile, catalogue revision 15 and no retained live orders at the baseline. These values are observations, not architecture constants.

## Auth/member flow — implemented and physically validated

```text
Android Sign Up
 -> Supabase Auth
 -> trusted new-user provisioning trigger
 -> user_profiles(app_role=customer)
 -> server-generated members row/member code
 -> protected Dashboard Members read through Owner/Admin BFF session
 -> new customer visible in Admin Members
```

Public signup cannot self-grant staff/admin/owner, member code or verified student state. Employee identities are separate from customer membership.

The user physically validated this flow with a newly created Android customer.

## Catalogue flow — implemented and physically validated

```text
Admin Menu
 -> same-origin HttpOnly employee session
 -> admin/owner caller JWT
 -> save_catalogue_* RPC
 -> catalogue tables + audit + revision bump
 -> catalogue_revision Realtime
 -> Flutter invalidates catalogue snapshot
 -> get_catalogue() under RLS
 -> updated menu shown
```

The production customer menu and Dashboard POS catalogue browser contain no runtime hardcoded catalogue fallback.

The user physically validated a real Owner price mutation in Dashboard Admin Menu and observed the changed price in the installed Android app.

## Customer order flow — implemented

```text
Flutter cart selections
 -> quote_order(ids/qty/intent only)
 -> server revalidates catalogue and calculates integer-sen totals
 -> customer chooses ASAP or server-policy-aligned scheduled pickup
 -> place_customer_order(clientRequestId + selections)
 -> trusted customer/member derived from auth session
 -> orders + immutable line/add-on snapshots
 -> order_events(created)
 -> server order number/status/total returned
 -> owner history/detail + orders Realtime invalidation/refetch
```

The customer cannot submit trusted prices, totals, order numbers, member IDs or status. Placement requires an active trusted member and is idempotent per authenticated actor + `clientRequestId`.

## Dashboard POS order flow — backend implemented, React integration in closeout

The trusted server/BFF path already exists:

```text
POS selections
 -> POST /api/v1/orders/quote
 -> employee HttpOnly session validated by BFF
 -> caller JWT -> quote_order
 -> authoritative quote
 -> POST /api/v1/orders/place
 -> caller JWT -> place_pos_order
 -> persisted guest POS order
 -> GET /api/v1/orders queue refresh
```

At the start of TASK-CLOSEOUT-001 the React `CounterWorkspace`/Orders rail still contains preview transaction/payment/order authority. Closeout must connect those live surfaces to the existing BFF. Until that integration lands, this diagram is the accepted trusted path, not a claim that the current React screen already completes it.

## Scheduled pickup

```text
get_ordering_policy
 -> Asia/Kuala_Lumpur
 -> 15-minute minimum lead
 -> 15-minute slots
 -> 7-day horizon
 -> selected scheduled timestamp
 -> quote_order validates server time/horizon/slot
 -> scheduled order persisted with status=scheduled
```

Branch hours, closures and per-slot capacity are not authoritative and must not be presented as backend guarantees.

## Fulfilment/status flow — backend implemented, Dashboard UI pending closeout

```text
Dashboard live order board
 -> GET /api/v1/orders
 -> staff selects legal next state
 -> POST /api/v1/orders/status + expectedVersion
 -> transition_order_status
 -> orders row/statusVersion updated
 -> order_events appended
 -> customer receives owner-authorized orders Realtime event
 -> Flutter calls get_order(orderId)
 -> UI renders persisted status
```

Legal flow is `confirmed|scheduled -> preparing -> ready -> completed`, with cancellation allowed before ready. Completed/cancelled are terminal. Stale `statusVersion` mutations fail.

Because employee JWTs remain HttpOnly, React must not expose a staff token for direct Supabase Realtime. The accepted live dashboard strategy is short same-origin BFF polling/refetch plus immediate invalidation after place/status mutations. Customer Flutter can use owner-scoped Supabase Realtime directly.

## Android release boundary

The main Android manifest now declares `android.permission.INTERNET`. The user installed the fixed release app and successfully reached live Supabase signup, closing the prior release host-resolution failure.

TASK-CLOSEOUT-001 still must make the Android release build reproducible from committed Gradle/AGP configuration without a local stash/toolchain override.

## Deployment state

A Vercel project/deployment exists historically, but the hosted BFF runtime was not completed/configured. The currently validated demo path is **local Dashboard PC + cloud Supabase + installed Android app**.

Hosted deployment is therefore deferred operational work, not a claim of production deployment and not a blocker for the accepted local demo closeout unless a later requirement changes that gate.

## Deferred authority

Real payments/refunds, loyalty, inventory depletion, discounts/promotions, tax/accounting, revenue reporting, delivery, branch scheduling/capacity and branch-scoped operations remain separate trusted tasks.
