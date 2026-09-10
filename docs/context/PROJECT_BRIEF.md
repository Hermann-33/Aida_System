# AIDA Café Project Brief

Updated: 2026-09-11

## Product purpose

AIDA Café is the customer ordering, membership and café-operations system for City University Malaysia. It combines a Flutter customer application and a React Dashboard/Admin/POS over one authoritative Supabase backend.

## Repositories and backend

```text
Customer/backend
  Hermann-33/Aida_System
  default: master

Dashboard/Admin/POS
  Hermann-33/Aida_System-Dashboard
  default: main

Shared backend
  Supabase project: Aida System
  ref: eswovqxqzfevcdwwcmuh
```

Canonical executable Supabase migrations live in the customer/backend repository.

## Current trusted product tranche

### Customer application

Implemented authority/integration includes:

- Supabase Auth/session/signup/logout and trusted member provisioning;
- server-generated member identity/code;
- database-backed catalogue with variants, drink option groups and compatible add-ons;
- authoritative quote and idempotent customer order placement;
- Now/scheduled pickup from backend policy;
- persisted order history/detail/status;
- owner-scoped Realtime invalidation/refetch;
- explicit pay-at-counter/unpaid semantics;
- reproducible Android release build path.

Customer clients submit selection/fulfilment intent only and never become authority for commercial or operational truth.

### Dashboard/Admin/POS

Implemented authority/integration includes:

- same-origin employee/Admin BFF with HttpOnly session cookies;
- trusted role/disabled-state authorization;
- trusted employee branch assignments;
- protected Admin member/catalogue operations;
- shared catalogue POS reads and authoritative quote/order placement;
- live polled order queue and versioned fulfilment transitions;
- trusted branch/sales-point/terminal management;
- one-time terminal enrolment and revocation;
- HttpOnly terminal credential storage;
- live POS placement bound to trusted terminal authority;
- immutable branch/sales-point/terminal order attribution.

Explicit UI Preview remains fixture-backed for demonstrations and is never trusted backend authority.

### Shared backend

Supabase currently owns trusted:

- Auth/profile/member identity;
- catalogue and modifier validity;
- commercial prices/totals;
- ordering/scheduling/idempotency;
- immutable order snapshots;
- fulfilment transitions/events;
- branch identity and staff branch scope;
- sales-point/terminal topology;
- terminal enrolment/credential/revocation;
- POS operational attribution;
- RLS/FORCE-RLS and controlled RPC boundaries;
- Realtime invalidation signals.

## Phase 1 completion

`TASK-OPS-002 — operational topology` is `COMPLETE` and frozen for Astra audit.

Trusted operational chain:

```text
branch
 -> sales point
 -> terminal
 -> employee branch scope
 -> POS order attribution
```

Live seed topology:

```text
BR-MAIN — Main Café
  SP-MAIN — Main Counter
    POS-MAIN-01 [pending until manager enrolment]
```

Current executable evidence:

```text
Backend database audit #22      PASS
Customer release audit #114     PASS
Dashboard CI #23                PASS
```

The clean database audit reconstructs Supabase from canonical migrations and passes branch, operational-topology, general-order and scheduled-order integration regressions.

Full evidence:

`docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

Matching audit PRs:

```text
Customer/backend PR #20
Dashboard/POS PR #17
```

These PRs are not merged by Phase 1 closeout. Astra findings must be resolved or explicitly accepted before Phase 2 begins.

## Trust rule

Clients may stage interaction and selection intent but never authorize or calculate trusted:

- identity/roles/branch scope;
- member codes;
- branch/sales-point/terminal IDs;
- terminal credential state;
- catalogue price/modifier validity;
- order totals/numbers/status;
- payment settlement;
- loyalty value;
- inventory state;
- shift/cash truth;
- reporting/accounting truth.

Dashboard privileged operations stay behind the same-origin BFF. Customer Flutter uses public/publishable configuration and customer-scoped backend authority.

## Current scheduling compatibility

The current singleton scheduling policy remains:

```text
Asia/Kuala_Lumpur
minimum lead 15 minutes
preparation lead 15 minutes
slot interval 15 minutes
maximum advance 7 days
```

Customer placement still resolves the active default branch server-side. Explicit customer pickup-branch selection plus branch hours/closures/capacity remain a later coordinated contract.

## Still deferred

- Phase 2 shift/cash authority;
- employee Auth-user provisioning, role mutation and badge/PIN lifecycle;
- branch hours/closures/capacity and explicit customer branch selection;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- tax/accounting/reporting;
- payment capture/refunds/external settlement;
- printer/KDS/payment-device integrations;
- delivery;
- hosted production/release operations;
- final App Store release gate, including production account deletion.

## Success criteria

AIDA succeeds when each role completes its flow against one consistent trusted backend with server-owned identity, commercial and operational state; secure scoped access; reproducible migrations/builds; cross-client validation; and synchronized governance documentation.

Phase 1 meets those criteria for operational topology and is now awaiting Astra audit before the next dependent phase.
