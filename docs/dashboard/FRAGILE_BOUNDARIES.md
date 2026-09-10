# POS/Admin Fragile Boundaries

Updated: 2026-09-11

## Authorization/session boundary

- React route guards are presentation only; same-origin BFF + Supabase remain authorization authority.
- Employee session semantics must not regress from HttpOnly cookies to browser-readable bearer tokens.
- `assignedBranchIds` must come from `employee_branch_assignments`, never preview fixtures/browser storage.
- Ordinary staff with no trusted branch assignment must fail closed.
- Admin/Owner are intentionally global for the current tranche; do not generalize that scope to ordinary staff.

## Terminal authority boundary

Terminal authority is now live and must not regress to preview/local identifiers.

- real terminal credential stays in an HttpOnly BFF cookie;
- React may consume only trusted terminal status/location projections;
- one-time enrolment code possession alone is insufficient—backend employee branch authorization is required;
- removing employee branch scope must immediately prevent that employee from using the terminal in that branch;
- revoking a terminal must immediately prevent resolution/new placement;
- browser-supplied `branchId`, `salesPointId` or `terminalId` must never replace credential resolution;
- credentialless `place_pos_order(jsonb)` must remain unavailable to authenticated live clients;
- accepted order topology attribution is immutable.

Do not write the terminal credential to localStorage, sessionStorage, URL parameters, logs or normal React state.

## Operational topology boundary

`branches`, `sales_points` and `terminals` are trusted backend entities.

- fixture IDs must never be promoted to backend foreign keys;
- Admin live pages must use the operational BFF/API rather than session-local records;
- explicit UI Preview may continue to show fixtures but cannot call them trusted state;
- FORCE-RLS and controlled mutation RPCs must remain intact;
- authenticated SELECT on sales points/terminals must remain RLS-constrained to Admin/Owner rather than becoming public directory access.

## POS/order boundary

- local cart arithmetic is estimate-only; server quote is commercial authority;
- order intents contain selection/fulfilment data, not trusted prices/totals or topology IDs;
- POS placement requires employee session plus valid terminal credential;
- customer placement remains terminal-free;
- `clientRequestId` retry semantics must remain stable;
- `orders.branchId`, `salesPointId` and `terminalId` are backend truth and must not be rewritten from workstation state.

## Catalogue/modifier boundary

- shared catalogue decoding must preserve variants, customization groups and compatible add-ons without inventing commercial defaults client-side;
- required drink groups need one available default;
- client validation supplements backend validation only;
- cart identity must include option/add-on selections so distinct configured drinks never merge implicitly;
- unavailable catalogue state cannot be bypassed with preview data.

## Scheduling/fulfilment boundary

- customer/POS display may say `Now`; shared wire value remains `asap`;
- do not manufacture schedule slots or branch hours locally;
- do not reconstruct authoritative `scheduleState` from workstation time;
- reaching `prepareAt` never auto-transitions an order;
- legal fulfilment mutations require expected `statusVersion` and server authorization.

Branch hours/closures/capacity and explicit customer pickup branch remain Phase 4 and must not be inferred from current branch/terminal topology.

## Preview boundary

`src/preview/` remains demonstration-only. Preview staff, branch, sales-point, terminal, shift, inventory, payment and reporting values must never authorize live APIs or become persisted business truth.

The Phase 1 change is specifically that branches/sales points/terminals now also have a separate trusted live path. Preview copies are still non-authoritative.

## Still deferred high-risk domains

- shift/cash lifecycle and variance approval;
- employee Auth-user creation/role mutation/badge-PIN lifecycle;
- branch hours/capacity/customer branch selection;
- inventory/recipes/depletion;
- loyalty/rewards;
- promotions;
- reporting/accounting;
- payment/refunds;
- printer/KDS/payment-device integration;
- delivery/hosted production.

Do not wire a later domain against preview identifiers simply because its UI already exists.

## Cross-repository change rule

Changes to shared IDs, order payloads, terminal credential semantics, staff branch scope, scheduling state or lifecycle strings are coordinated backend + Dashboard/customer contract changes. Update accepted ADRs/contracts and both mirrored governance sets before treating them as complete.

## Phase 1 audit boundary

`TASK-OPS-002` is `COMPLETE`; evidence is in `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.

PR #20 and PR #17 are frozen for Astra. Phase 2 must not begin until Astra findings are resolved or explicitly accepted.
