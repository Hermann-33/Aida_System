# POS/Admin Dashboard Audit

Updated: 2026-09-11

## Current verdict

`COMPLETE` for Phase 1 operational topology. Dashboard live mode now consumes trusted branch, employee-branch, sales-point and terminal authority in addition to the previously trusted Auth/member/catalogue/order tranche.

Full evidence: `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.

## Trusted live surfaces

- same-origin employee/Admin authentication/session BFF with HttpOnly cookies;
- trusted role/disabled-state and `assignedBranchIds`;
- protected Admin member/catalogue operations;
- shared catalogue and authoritative quote/order flows;
- live order queue and versioned fulfilment transitions;
- Admin branch and sales-point management;
- Admin terminal list/create/enrolment-code/revoke flows;
- Admin employee directory and branch-assignment mutation;
- terminal enrolment/status/credential clearing;
- live POS requiring trusted terminal context;
- terminal-bound POS placement with immutable branch/sales-point/terminal attribution.

The browser receives neither a service-role credential nor a readable employee/terminal secret. Employee tokens and the terminal credential remain HttpOnly/BFF-held.

## Preview boundary

Explicit UI Preview still uses fixtures for demonstrations. Preview identifiers/state are not trusted backend authority and cannot be used to authorize live employee, location, terminal or order operations.

Admin Locations, Terminals and Employees now use trusted APIs in live mode. Their preview branches remain deliberately separate.

## Phase 1 runtime evidence

Dashboard code head before documentation-only closeout:

`50c559f4ed5a5f0ddd373a4bf450a38c7e9716ba`

Dashboard CI run #23:

```text
npm ci                 PASS
lint                   PASS
typecheck              PASS
Vitest files      31 / 31 PASS
Vitest tests     150 / 150 PASS
production build        PASS
```

Backend database audit #22 separately proves the database/RPC allow/deny boundary on a clean migration replay.

## Security result

- ordinary staff with no branch assignment fail closed;
- employee branch scope is backend state;
- terminal enrolment requires authenticated branch authorization in addition to possession of the one-time code;
- the terminal credential stays in an HttpOnly cookie;
- terminal revocation immediately blocks terminal resolution/POS placement;
- browser-supplied location IDs are not POS attribution authority;
- direct topology mutation is denied;
- no service-role/browser bearer-token bypass exists.

Supabase security advisor has one pre-existing leaked-password-protection WARN only. No Phase 1-created security blocker remains.

## Still non-authoritative/deferred

- shifts/cash movements/opening float/variance;
- employee Auth-user creation, role mutation and badge/PIN lifecycle;
- branch opening hours/closures/capacity and explicit customer branch selection;
- inventory/recipes/depletion/transfers;
- loyalty/rewards/vouchers;
- promotions/marketing authority;
- trusted sales/revenue/tax/accounting reporting;
- payment settlement/refunds;
- printer/KDS/payment-device integrations;
- hosted production operations.

Presentation in those areas must not imply backend authority before their phases are implemented.

## Audit boundary

Dashboard PR #17 and customer/backend PR #20 form the frozen Phase 1 Astra audit boundary. Do not start Phase 2 until Astra findings are resolved or explicitly accepted.
