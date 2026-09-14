# AIDA Café Project Brief

Updated: 2026-09-15

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

Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Current trusted product tranche

Phases 1–5 are individually `COMPLETE`. Phase 6 loyalty/rewards/vouchers is the current `PARTIAL` boundary.

### Customer application

Implemented authority/integration includes:

- Supabase Auth/session/signup/logout and trusted member provisioning;
- server-generated member identity/code;
- database-backed catalogue with variants, drink options and compatible add-ons;
- authoritative quote and idempotent customer order placement;
- explicit validated pickup branch selection;
- branch-local ASAP/scheduled pickup availability and server-derived preparation timing;
- persisted order history/detail/status;
- owner-scoped Realtime invalidation/refetch;
- in-app privacy preferences and caller-bound whole-account deletion;
- explicit pay-at-counter/unpaid semantics;
- reproducible Android release validation.

Customer clients submit identity-independent selection/fulfilment intent only. Catalogue compatibility, prices/totals, branch/schedule acceptance, inventory sufficiency, order identity/status and persisted commercial facts remain server-owned.

### Dashboard/Admin/POS

Implemented authority/integration includes:

- same-origin employee/Admin BFF with HttpOnly session cookies;
- trusted role/disabled-state and employee branch authorization;
- protected Admin catalogue/member operations;
- trusted branch/sales-point/terminal management;
- one-time terminal enrolment/revocation with HttpOnly terminal credential storage;
- live POS placement bound to trusted terminal + employee + open-shift authority;
- immutable topology/shift/tender/payment POS attribution;
- trusted shift open/lock/resume/close and append-only cash movements;
- server-derived expected cash and variance approval boundary;
- branch scheduling/service-window/exception/capacity administration;
- live inventory and recipe administration;
- receiving/waste/manual-adjustment stock movements behind trusted RPCs;
- shared live order queue and optimistic fulfilment transitions.

Explicit UI Preview remains fixture-backed for demonstrations only and is never trusted backend authority or live fallback.

### Shared backend authority through Phase 5

```text
Phase 1: branch -> sales point -> terminal -> employee branch scope -> POS attribution
Phase 2: terminal + employee -> shift -> POS order / cash ledger
Phase 3: customer identity -> privacy/account deletion -> anonymized retained history
Phase 4: branch -> local service calendar -> pickup policy -> slot capacity -> order acceptance
Phase 5: catalogue -> recipe -> branch stock -> transactional depletion/reversal
```

Supabase owns the corresponding trusted identity, authorization, operational, commercial, privacy, scheduling and inventory facts. Money remains integer sen; inventory quantities use integer milli-units. Historical accepted commercial facts are not rewritten by later configuration changes.

## Validation boundary

Latest completed phase evidence:

```text
Phase 5 backend implementation head      2b26bc531e2f03c1af1f31e5e51a8b529111fc04
Phase 5 dashboard implementation head    2f6128c40fe0b9778f193c43681ad0b6bbf47653
Backend database audit #138              COMPLETE
Customer release audit #229              COMPLETE
Dashboard CI #99                         COMPLETE
Supabase security advisor                COMPLETE for Phase 5
Supabase performance advisor             COMPLETE for Phase 5
```

Detailed evidence: `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`.

## Current Phase 6 boundary

Phase 6 replaces preview/client loyalty state with server-authoritative:

- append-only points/stamp earning history;
- server-derived loyalty balances;
- reward catalogue and point-cost authority;
- atomic points redemption;
- customer-owned voucher issuance/expiry/status;
- trusted voucher quote/application/consumption;
- stable applied-voucher commercial snapshots;
- live Admin/Owner loyalty/reward support controls through the existing BFF.

Plan: `docs/context/PHASE_6_LOYALTY_REWARDS_VOUCHERS_PLAN.md`.

Phase 7 promotions/discounts may not begin until Phase 6 is `COMPLETE`.

## Trust rule

Clients may stage interaction and intent but never authorize or calculate trusted:

- identity/roles/branch scope;
- member codes or customer ownership;
- branch/sales-point/terminal/shift identity;
- terminal credential state;
- catalogue price/modifier validity;
- branch scheduling/capacity acceptance;
- inventory balances/recipes/depletion;
- order totals/numbers/status;
- payment settlement/refunds;
- loyalty balances/reward cost/voucher validity;
- promotions/discounts;
- reporting/accounting truth.

Dashboard privileged operations stay behind the same-origin BFF with caller-JWT forwarding. Customer Flutter uses public/publishable configuration and caller-bound customer authority. No service-role secret or browser-readable reusable employee bearer/terminal credential is permitted.

## Deferred

- promotions/discounts — Phase 7;
- tax/accounting/reporting — Phase 8;
- payment capture/refunds/external settlement and deployment-heavy integrations;
- supplier purchasing, lot/expiry, forecasting and automated procurement;
- employee Auth-user provisioning/credential lifecycle;
- printer/KDS/payment-device integrations;
- delivery and hosted production/release operations;
- final release-store operational submission gate.

Under ADR-0013, the owner-directed independent Phase 1–3 Codex audit may run in parallel with Phases 4–7. A valid blocking finding reopens the affected earlier phase. Completion never authorizes automatic PR merge.
