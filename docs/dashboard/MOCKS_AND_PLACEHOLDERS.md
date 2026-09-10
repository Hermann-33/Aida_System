# POS/Admin Mocks and Placeholders Register

Updated: 2026-09-11

## Trusted live paths

The following are live backend integrations, not preview authority:

- employee/Admin session and trusted branch assignments;
- Admin Members;
- catalogue categories/items/variants/options/add-ons;
- authoritative POS quote/order placement;
- Now/scheduled pickup policy and workload classification;
- live order queue/detail and versioned fulfilment transitions;
- branches and sales points;
- terminals and terminal status;
- manager-issued terminal enrolment codes;
- terminal enrolment/revocation;
- Admin employee directory and branch assignment;
- terminal-bound POS placement and persisted branch/sales-point/terminal attribution.

## Allowed local browser state

Transient UI state is allowed for:

- unsaved cart lines and selected catalogue IDs;
- quantity/note;
- local price estimates before quote;
- Now/Schedule intent;
- filters/dialog/loading/error state;
- one retry-stable `clientRequestId`;
- decoded terminal display context returned by trusted status endpoints.

Local state must not become authority for catalogue validity/pricing, employee branch scope, terminal credential validity or operational attribution.

## Preview boundary

Explicit UI Preview may use fixture branches, sales points, terminals, employees and shifts for demonstration. Those fixture values are presentation-only.

Live mode must not use preview identifiers as database foreign keys, authorization claims, terminal credentials or persisted order attribution.

Admin Locations, Admin Terminals and Admin Employees now consume trusted APIs in live mode. Their Preview behavior remains intentionally separate.

## Terminal credential boundary

The real terminal credential is not a preview/local-storage value and must not be exposed to normal React state.

Live flow:

```text
one-time enrolment code
 -> BFF enrol endpoint
 -> Supabase validates caller/branch/terminal
 -> credential returned once
 -> HttpOnly terminal cookie
 -> server-side forwarding for status/POS placement
```

Preview terminal samples must never be accepted by live APIs.

## Removed/fake authority forbidden in live mode

Do not use:

- client-computed totals as final truth;
- preview/local orders as persisted-order fallback;
- fake order numbers;
- fake payment/tender success;
- local-only fulfilment state;
- timer-driven order progression;
- preview catalogue options to bypass live availability;
- preview branch/sales-point/terminal IDs for live POS attribution;
- local-storage employee or terminal secrets.

## Still preview/deferred

The following are not trusted live authority yet:

- shifts, opening float, cash movement and variance;
- employee Auth-user creation/role mutation/badge-PIN lifecycle;
- branch opening hours/closures/capacity and explicit customer branch selection;
- inventory/recipes/depletion/transfers;
- loyalty/reward balances and redemption;
- promotions/marketing publication authority;
- payment settlement/refunds;
- tax/accounting/trusted sales reporting;
- printer/KDS/payment-device integrations;
- many settings/integration presentation surfaces;
- hosted production operations.

## Phase 1 boundary

`TASK-OPS-002` is `COMPLETE`. Phase 1 evidence is in `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.

PR #20 and PR #17 remain the frozen Astra audit boundary. Do not begin Phase 2 until Astra findings are resolved or explicitly accepted.
