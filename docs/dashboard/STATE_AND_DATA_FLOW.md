# POS/Admin State and Data Flow

Updated: 2026-09-11

## Employee session

```text
employee login
 -> same-origin BFF
 -> Supabase Auth
 -> user_profiles role/disabled check
 -> employee_branch_assignments
 -> HttpOnly access/refresh cookies
 -> React receives identity + assignedBranchIds only
```

The employee bearer token is never persisted/read by browser JavaScript. Ordinary staff with no trusted branch assignment fail closed.

## Terminal enrolment/session

```text
Admin creates terminal
 -> manager issues one-time enrolment code
 -> employee enters code on workstation
 -> POST terminal enrol endpoint
 -> BFF validates employee session and forwards caller JWT
 -> Supabase validates code + terminal + employee branch scope
 -> one terminal credential returned
 -> BFF stores credential in HttpOnly cookie
 -> React receives only trusted location/status projection
```

The terminal credential is not exposed to normal React state or local storage.

Terminal status resolution revalidates active terminal, sales point, branch and employee branch scope. Revocation or loss of branch scope blocks the flow.

## Admin operational topology

```text
AdminLocationsPage
 -> operationalLocationClient
 -> same-origin BFF
 -> branch / sales-point RPCs

AdminTerminalsPage
 -> operationalLocationClient
 -> Admin topology / save terminal / issue code / revoke RPCs

AdminEmployeesPage
 -> operationalLocationClient
 -> trusted employee directory / branch-assignment RPCs
```

Live mode uses these APIs. Explicit UI Preview follows a separate fixture path and remains non-authoritative.

## POS catalogue and quote

```text
catalogue selection IDs
 -> local cart + estimate
 -> POST /api/v1/orders/quote
 -> employee BFF session validation
 -> caller JWT -> quote_order
 -> server catalogue/modifier/schedule validation
 -> authoritative integer-sen quote
```

Local cart state is interaction only; server quote is commercial authority.

## Live POS placement — Phase 1

```text
employee session
 + HttpOnly terminal credential
 + selection/fulfilment intent
 -> POST /api/v1/orders/place
 -> order BFF
 -> caller JWT + server-held terminal credential
 -> place_pos_order(payload, credential)
 -> Supabase resolves terminal -> sales point -> branch
 -> validates employee may operate branch
 -> persists trusted POS order attribution
```

Persisted POS snapshot includes immutable branch/sales-point/terminal authority. The browser never supplies trusted topology IDs.

Credentialless `place_pos_order(jsonb)` is not executable by authenticated users.

## Customer placement contrast

Customer Flutter does not participate in terminal flow:

```text
customer selections
 -> quote_order
 -> place_customer_order
 -> backend derives customer/member + active default branch
 -> salesPointId/terminalId remain null
```

## Order queue/status

```text
GET /api/v1/orders
 -> BFF caller JWT
 -> backend branch scope
 -> Active / Scheduled / Ready / History projection
 -> periodic refetch

staff next-state action + statusVersion
 -> POST /api/v1/orders/status
 -> transition_order_status
 -> branch authorization + legal transition + optimistic version check
 -> order event + updated snapshot
```

Backend `prepareAt`, `serverNow` and `scheduleState` remain operational scheduling authority. No React timer changes persisted order state.

## Catalogue propagation

```text
Admin catalogue mutation
 -> Supabase
 -> catalogue_revision bump
 -> customer/POS invalidate and refetch
```

Preview catalogue data cannot override live catalogue state.

## Customer order propagation

```text
staff fulfilment transition
 -> orders change
 -> owner-scoped Realtime invalidation
 -> customer authorized refetch
```

Dashboard employee flows do not expose employee JWT for direct Realtime.

## Payment boundary

There is no trusted processor/settlement state. Current flow remains explicit pay-at-counter/unpaid semantics.

## Phase 1 validation

```text
Dashboard CI #23              PASS — 31 files / 150 tests
Backend database audit #22   PASS — all four SQL suites
Customer release audit #114  PASS
```

Detailed evidence: `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.

## Deferred flows

- shift/cash open/lock/close and variance;
- employee provisioning/role/badge/PIN lifecycle;
- branch hours/closures/capacity/customer branch selection;
- inventory/recipes/depletion;
- loyalty/rewards;
- promotions;
- tax/accounting/reporting;
- payment/refunds;
- printer/KDS/payment-device integrations;
- delivery/hosted production.
