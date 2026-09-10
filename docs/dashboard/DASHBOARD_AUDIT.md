# POS/Admin Dashboard Audit

Updated: 2026-08-17

## Current verdict

`COMPLETE` for the trusted Auth/member/catalogue/order tranche defined by TASK-CLOSEOUT-001. Broader payment, loyalty, inventory, reporting, branch/terminal/shift and hosted-production domains remain preview/deferred and are not promoted by this verdict.

## Runtime

React 19.2.7, TypeScript 6.0.3, Vite 8.1.5, React Router DOM 7.18.1, Tailwind CSS 4, Radix/shadcn-style components, TanStack Query, Vitest and Playwright. npm with lockfile.

## Trusted current surfaces

- same-origin employee/Admin authentication/session BFF with HttpOnly cookies;
- trusted role/disabled-state checks from shared profiles;
- protected Admin Members directory;
- shared public/POS catalogue read;
- protected Admin catalogue management;
- TASK-AUTH-005 preview/live session separation;
- authoritative POS quote/place with stable idempotency;
- server-policy ASAP/scheduled pickup;
- explicit Pay-at-counter/unpaid order semantics;
- live BFF-backed order queue;
- legal versioned fulfilment transitions with conflict refetch.

The browser does not receive a service-role credential or persistent employee bearer token. Route guards remain presentation/access-routing logic, not backend authorization authority.

## Current non-authoritative/deferred behavior

The following remain outside the trusted tranche unless separately backed by a current contract:

- payment settlement/refunds;
- loyalty/reward balances and redemptions;
- inventory/recipes/depletion/transfers;
- branch scope and branch opening-hours/capacity;
- terminal enrolment/device authority beyond current preview/local behavior;
- shift/cash-movement authority;
- employee/branch management surfaces not yet backed by a trusted server contract;
- marketing publication;
- sales/revenue/tax/accounting reporting;
- several settings/integration/audit display surfaces.

Preview/local fixtures in these domains must not be used as catalogue/order/member/payment truth.

## Final verification baseline

TASK-CLOSEOUT-001 Dashboard validation:

- lint: PASS with two established Fast Refresh warnings;
- typecheck: PASS;
- Vitest: PASS, 25 files / 111 tests;
- production build: PASS;
- legacy token/localStorage safety assertion: PASS;
- Playwright: PASS, 8/8;
- `npm audit`: PASS, 0 vulnerabilities;
- `git diff --check`: PASS;
- no service-role/secret/browser employee-token persistence introduced.

## Cross-client evidence

Physical/manual proof:

- Android customer signup → trusted member → protected Dashboard Members;
- real Owner catalogue mutation → installed customer catalogue refresh.

Final live order proof on 2026-08-17:

- customer quoted Sandwich ASAP at 1,290 sen;
- customer placed order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`) as `confirmed` v1;
- authenticated Owner Dashboard queue observed the same order;
- Dashboard persisted `preparing` v2 → `ready` v3 → `completed` v4;
- customer-authorized reads observed each status.

One completed order remains retained as closeout evidence.

## Security/operations

Current Supabase security advisor has one WARN: leaked-password protection disabled. Hosted/Vercel deployment remains DEFERRED for the accepted local Dashboard PC → cloud Supabase → installed-phone topology.

## Historical baseline note

The original TASK-WF-002/TASK-MENU-001 audits correctly described a much earlier preview-first state. Those measurements remain historical evidence only. Current system truth is maintained in `docs/context/ACTIVE_CONTEXT.md`, `SUPABASE_STATUS.md`, `CLOSEOUT_EVIDENCE_2026-08-17.md`, the accepted ADRs/contracts, and this updated audit.


## 2026-09-10 branch authority update

Trusted branch scope is no longer wholly deferred.

Backend/BFF authority now exists for:

- active public branch directory;
- Admin/Owner full branch directory and mutation;
- trusted employee branch assignments;
- employee session `assignedBranchIds` loaded with the caller JWT;
- ordinary staff branch-scoped order queue/detail/status authorization;
- immutable branch identity in order snapshots;
- Admin employee directory and branch-assignment mutation endpoints.

The existing `AdminLocationsPage.tsx` and `AdminEmployeesPage.tsx` are still session-local preview UI and are **not yet wired** to these APIs. Sales points, terminals, shifts, branch hours/capacity and inventory remain deferred.
