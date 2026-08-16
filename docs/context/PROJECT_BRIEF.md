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

Both client implementations and their local test/build gates are complete for the current tranche. The only remaining ADR-0004 closeout gate is a fresh live supported order lifecycle proving customer placement → Dashboard observation/transitions → customer authorized persisted-status refresh.

Customer PR #13 and Dashboard PR #12 are technically mergeable but remain draft until that E2E and final mirrored-document/merge-readiness checks pass.

## Trust rule

Clients may stage interaction and selection intent, but never authorize identity, roles, member codes, prices, totals, order numbers/status, payment state, loyalty value, inventory or reporting truth. Dashboard privileged calls stay behind the same-origin BFF; customer Flutter uses public client configuration and customer-scoped backend authority.

## Deferred scope

Real payment/refunds, loyalty ledger/redemption, inventory, promotions/discount authority, tax/accounting, trusted reporting, branch-scoped operations/capacity, delivery and hosted production deployment/release operations remain future bounded tasks.

## Success criteria

AIDA succeeds when role-appropriate users complete their flows against one trusted backend with consistent IDs/state transitions, server-authoritative value calculations, secure ownership/role access, reproducible migrations/builds, cross-client integration evidence and current mirrored documentation.
