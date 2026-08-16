# AIDA Café Project Brief

Updated: 2026-08-17

## Product purpose

AIDA Café is the customer ordering, membership and café-operations system for City University Malaysia. It combines a Flutter customer application and a React Dashboard/Admin/POS over one authoritative Supabase backend.

## Current implemented tranche

### Customer application

Repository: `Hermann-33/Aida_System`.

Implemented and validated:

- Supabase Auth/session/signup/logout and trusted customer profile/member provisioning;
- server-generated member code and minimum per-user offline member-code cache;
- shared database-backed catalogue with variants/add-ons and revision invalidation/refetch;
- authoritative quote and idempotent customer order placement;
- ASAP/scheduled pickup from server policy;
- explicit Pay-at-counter/unpaid order semantics;
- persisted order history/detail/status and owner-scoped Realtime-triggered refetch;
- Android production Internet permission and reproducible release packaging from committed Git.

Physical Android validation proved signup/member provisioning and Dashboard catalogue mutation propagation to the installed app.

### Dashboard/Admin/POS

Repository: `Hermann-33/Aida_System-Dashboard`.

Implemented and validated:

- same-origin employee/Admin BFF with HttpOnly session cookies;
- trusted role/disabled-state authorization;
- protected Admin Members;
- shared catalogue POS reads and protected Admin catalogue mutation;
- TASK-AUTH-005 preview/live session separation;
- authoritative POS quote/place using the existing order BFF;
- server-policy ASAP/scheduled pickup;
- stable placement idempotency;
- explicit Pay-at-counter/unpaid semantics;
- live polled order queue with no preview-order fallback;
- legal versioned fulfilment transitions and stale-version refetch.

### Shared backend

Supabase project **Aida System**, ref `eswovqxqzfevcdwwcmuh`.

Implemented authority includes Auth/profile/member, catalogue, quote/order, scheduling, immutable order snapshots, idempotency, fulfilment transitions/events, RLS/FORCE RLS, controlled RPCs and Realtime signals. Canonical executable migrations live in the customer repository.

## Current closeout status

`TASK-CLOSEOUT-001` is **COMPLETE** for implementation and applicable ADR-0004 validation.

The final live proof on 2026-08-17 placed customer order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`) at an authoritative total of 1,290 sen. The Dashboard observed the exact record and persisted `confirmed` v1 → `preparing` v2 → `ready` v3 → `completed` v4. Customer-authorized reads observed every persisted transition. Independent database verification confirms the completed order and event sequence.

Customer PR #13 and Dashboard PR #12 are independently verified mergeable. Final coordinated merge is repository housekeeping, not an implementation blocker.

## Trust rule

Clients may stage interaction and selection intent, but never authorize identity, roles, member codes, prices, totals, order numbers/status, payment state, loyalty value, inventory or reporting truth. Dashboard privileged calls stay behind the same-origin BFF; customer Flutter uses public client configuration and customer-scoped backend authority.

## Deferred scope

Real payment/refunds, loyalty ledger/redemption, inventory, promotions/discount authority, tax/accounting, trusted reporting, branch-scoped operations/capacity, delivery and hosted production deployment/release operations remain future bounded tasks.

## Success criteria

AIDA succeeds when role-appropriate users complete their flows against one trusted backend with consistent IDs/state transitions, server-authoritative value calculations, secure ownership/role access, reproducible migrations/builds, cross-client integration evidence and current mirrored documentation. The current tranche meets those criteria for its defined scope.
