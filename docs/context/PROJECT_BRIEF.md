# AIDA Café Project Brief

Updated: 2026-08-14

## Product purpose

AIDA Café is the customer ordering, membership, and café-operations system for City University Malaysia. It combines a Flutter customer application and a React Dashboard/Admin/POS over one authoritative Supabase backend.

## Current implemented tranche

### Customer application

Repository: `Hermann-33/Aida_System`.

Implemented and validated:

- Supabase Auth session/signup and server-provisioned profile/member;
- per-user minimum offline member ID/code cache;
- shared database-backed catalogue with variants/add-ons and revision invalidation;
- authoritative quote, ASAP/scheduled placement, persisted order history/detail/status, and owner-scoped order Realtime refetch;
- explicit Pay-at-counter boundary with no fake payment settlement;
- reproducible Android release packaging with production Internet permission.

Physical Android validation proved signup/member provisioning and Dashboard catalogue mutation propagation.

### Dashboard/Admin/POS

Repository: `Hermann-33/Aida_System-Dashboard`.

Implemented and validated before closeout: trusted same-origin employee sessions, Admin Members, shared catalogue Admin mutation, and shared catalogue POS browsing. Dashboard PR #12 is completing authoritative POS quote/place and the live staff order board/status UI. Until that branch and cross-client order E2E close, the order journey remains PARTIAL.

### Shared backend

Supabase project `Aida System`, ref `eswovqxqzfevcdwwcmuh`.

Auth/profile/member, catalogue, ordering, scheduling, immutable order snapshots, idempotency, fulfilment transitions, audit events, RLS/FORCE RLS, and Realtime signals are implemented. Canonical migrations and transactional regressions are owned by this repository.

## Trust rule

Clients may stage interaction and selection intent, but never authorize identity, roles, member codes, prices, totals, order numbers/status, payment state, loyalty value, inventory, or reporting truth. Dashboard privileged calls use its HttpOnly same-origin BFF and caller JWT; Flutter uses only the public publishable Supabase configuration and customer-scoped access.

## Deferred scope

Real payment/refunds, loyalty ledger/redemption, inventory, promotions/discount authority, tax/accounting, trusted reporting, branch-scoped operations/capacity, and delivery remain future bounded tasks. They are not completion requirements for this tranche.

## Success criteria for closeout

The tranche closes when both repositories build/test from committed Git, current shared documentation agrees, security boundaries remain intact, and the customer placement → Dashboard fulfilment transitions → customer authorized refresh journey is proven end to end.
