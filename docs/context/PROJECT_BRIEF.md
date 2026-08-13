# AIDA Café Project Brief

Updated: 2026-08-14

## Product purpose

AIDA Café is the ordering, membership, loyalty and café-operations system for City University Malaysia. The product combines a customer application with staff POS and administration workflows over one authoritative Supabase backend.

## System components

### Customer application

Repository: `Hermann-33/Aida_System`.

Flutter/Dart/Riverpod application for customer authentication, membership, menu browsing/customization, cart, ordering, scheduled pickup, order history/status and additional preview/deferred loyalty/profile experiences.

Current trusted integrations include:

- Supabase Auth sign-up/sign-in/session/logout;
- trusted profile/member reads and server-generated member code;
- minimum per-user offline member-code cache;
- shared catalogue with variants/add-ons/prices/availability;
- catalogue revision invalidation/refetch;
- authoritative quote and customer order placement;
- ASAP/scheduled pickup policy;
- persisted order history/detail/status;
- owner-scoped order Realtime invalidation followed by authorized refetch.

Real payment settlement/refunds, loyalty earning/redemption, profile writes, inventory effects, reporting and other explicitly deferred domains are not complete.

### POS/Admin dashboard

Repository: `Hermann-33/Aida_System-Dashboard`.

React 19 + TypeScript + Vite browser application with employee access, terminal/POS surfaces and Admin management.

Current trusted integrations include:

- same-origin employee/Admin BFF session with HttpOnly cookies;
- role/disabled-state authorization from trusted profiles;
- protected Admin Members directory;
- shared catalogue reads for POS;
- protected Admin catalogue reads/mutations;
- preview/live session separation from TASK-AUTH-005;
- authoritative order BFF endpoints for policy, quote, POS placement, queue/detail and status transitions.

At the start of TASK-CLOSEOUT-001 the remaining dashboard implementation gap is the React POS/order frontend: live authoritative quote/place, scheduling UX, order queue and versioned fulfilment controls. Existing preview/local transaction/payment objects are not trusted business authority.

### Shared backend

Supabase project **Aida System**, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`.

Implemented shared authority includes:

- Supabase Auth;
- identity/profile/member/student state;
- trusted roles and role helpers;
- shared catalogue and revision/audit signal;
- order/scheduling policy;
- authoritative quote engine;
- customer/POS order placement;
- immutable order commercial snapshots;
- fulfilment state machine and events;
- customer/order Realtime signals;
- FORCE RLS and controlled RPC boundaries.

Canonical executable migrations live only in `Hermann-33/Aida_System/supabase/` unless a future accepted ADR changes ownership.

## Current live validation snapshot

Dated 2026-08-14 evidence records 9 Auth users/profiles, 6 customer members, one owner, one admin and one staff profile, catalogue revision 15 and no retained live orders at the baseline. See `docs/context/CLOSEOUT_EVIDENCE_2026-08-14.md`.

The user physically validated Android customer signup -> Dashboard member visibility and Dashboard Owner price mutation -> installed customer catalogue refresh.

## Target users

- Students and other café customers.
- Baristas/cashiers/staff operating shared terminals and POS workflows.
- Managers/admin/owners operating catalogue, staff, inventory, rewards, marketing and reporting workflows.

## Shared product rule

The two frontends are views/controllers over one operational system. They must use the same identifiers, lifecycle definitions and backend rules. The customer app cannot invent a price/order/reward outcome that the POS does not recognise, and the dashboard cannot mutate trusted data outside the same server-enforced contract.

## Completion discipline

ADR-0004 remains authoritative: polished UI is not feature completion. A domain is complete only when applicable client, API, persistence, security, operations, tests and documentation gates pass.

TASK-CLOSEOUT-001 exists to finish the currently implemented tranche before new business-domain work starts. Remaining closeout work is Android build reproducibility, Dashboard authoritative order frontend integration, cross-client order E2E and final synchronized merge-readiness checks.

## Deferred domains

The next product phases remain separate bounded tasks, including:

- trusted payment capture/refunds;
- loyalty earning/redemption/vouchers;
- inventory depletion/recipes/wastage/transfers;
- promotions/discount engine;
- branch-scoped operations and branch hours/capacity;
- tax/accounting;
- sales/revenue reporting;
- delivery.
