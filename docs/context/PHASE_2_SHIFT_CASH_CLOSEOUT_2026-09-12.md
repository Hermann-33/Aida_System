# Phase 2 — Shift and Cash Authority Closeout

**Task:** `TASK-OPS-003`  
**Date:** 2026-09-12  
**Verdict:** `COMPLETE`  
**Audit policy:** Astra review remains intentionally deferred. Phase 2 is frozen as a completed boundary but its PRs must remain unmerged. After Phase 3 is `COMPLETE`, Phases 1–3 will be presented together for one Astra audit before Phase 4 begins.

## Scope and dependency rationale

Phase 2 extends the trusted operational topology established in Phase 1:

```text
branch
 -> sales point
 -> terminal
 -> employee
 -> shift
 -> POS order / cash ledger
```

A shift is only trustworthy after the backend can prove the physical terminal, branch and employee operating it. That dependency is why Phase 1 preceded Phase 2. External processor settlement, refunds, inventory, accounting and hardware integrations remain downstream and were not pulled forward.

## Implemented architecture and contracts

Supabase/server remains the authority for identity, role, branch scope, terminal identity, shift state, tender/payment classification and reconciliation facts.

Trusted Phase 2 resources:

```text
public.shifts
public.cash_movements
public.orders.shift_id
public.orders.tender_type
public.orders.payment_state
public.orders.paid_at
```

Shift authority now includes:

- UUID shift identity;
- branch, sales point and terminal attribution resolved from the enrolled terminal credential;
- opening/current operator identity;
- lifecycle `open`, `locked`, `closed`;
- optimistic `status_version` transitions;
- opening float in integer sen;
- server timestamps for open/lock/resume/close;
- close actor and optional Admin/Owner variance approval;
- one live open/locked shift per terminal;
- one live open/locked shift per operator.

Cash authority now includes:

- append-only `cash_in` and `cash_out` movements;
- integer-sen amounts;
- mandatory reason and actor identity;
- server-derived expected cash from opening float, trusted cash movements and cash-paid POS sales;
- actual counted cash and server-derived closing variance;
- non-zero variance close rejected for ordinary staff and permitted only under Admin/Owner authority.

POS order authority now includes:

- a valid open shift is mandatory for new live POS placement;
- the shift must match the enrolled terminal, sales point, branch and authenticated operator;
- `shift_id`, tender type and payment state are persisted by server authority and protected from ordinary mutation;
- Phase 2 supports only `cash` and `unpaid` internal tender semantics;
- cash tender is persisted as paid with server `paid_at`;
- customer orders remain shift-free and unpaid;
- paid cash orders cannot be cancelled because a trusted refund authority does not yet exist;
- changing tender changes the logical placement identity so idempotent retries cannot silently change settlement semantics.

## Security boundary

Dashboard privileged operations remain behind same-origin BFF handlers. The browser receives neither a reusable employee bearer token nor the terminal credential.

The BFF:

- validates the employee HttpOnly session;
- forwards the caller JWT to Supabase;
- reads the terminal credential only from the HttpOnly server request cookie;
- applies same-origin checks to mutations;
- never uses a service-role secret for normal operational flows.

Supabase enforcement:

- `shifts` and `cash_movements` have RLS and FORCE RLS;
- anonymous shift/cash RPC execution is denied;
- authenticated clients have no direct shift/cash mutation grants;
- public RPCs call internal authority functions that validate `auth.uid()`, role, branch, terminal and operator consistency;
- the cash movement ledger is append-only;
- persisted order shift/payment fields are immutable after trusted finalization.

## Dashboard implementation

Live POS no longer invents shift state.

Implemented live paths:

```text
GET  /api/v1/shifts/current
POST /api/v1/shifts/open
POST /api/v1/shifts/lock
POST /api/v1/shifts/resume
POST /api/v1/shifts/cash-movement
GET  /api/v1/shifts/reconciliation
POST /api/v1/shifts/close
GET  /api/v1/admin/shifts
```

Live POS behavior:

- terminal authority is validated first;
- no active shift blocks the sale workspace and presents trusted shift opening;
- locked shift blocks the sale workspace until trusted resume;
- opening float is converted to integer sen before the BFF call;
- live expected cash comes only from the server snapshot;
- cash-in/out controls append to the server ledger and consume the returned shift snapshot;
- close sends actual counted cash, notes and expected version, never a browser-owned expected cash value;
- cash/unpaid tender is explicitly selected at checkout;
- order responses are rejected client-side if shift/tender/payment authority is structurally inconsistent;
- paid cash orders do not expose cancellation until a later trusted refund workflow exists;
- UI Preview remains explicitly fixture-backed and non-authoritative.

## Canonical Supabase migrations

Only `Hermann-33/Aida_System/supabase/migrations/` owns canonical migrations.

```text
20260911235419 create_shift_cash_authority_schema
20260911235626 implement_shift_cash_authority_functions
20260911235651 harden_shift_cash_authority_permissions
20260912000002 index_shift_cash_foreign_keys
```

The AIDA Supabase project migration history was re-read on 2026-09-12 and contains all four migrations.

## Validation evidence

### Backend clean-database replay

Backend branch head used for final Phase 2 SQL validation:

`84b25f12f066bf9c58e53003d897720c01f47875`

Backend database audit run **#45** — `COMPLETE`:

```text
branch authority regression                 COMPLETE
operational topology regression            COMPLETE
order regression                           COMPLETE
scheduled-order operations regression      COMPLETE
shift and cash authority regression        COMPLETE
```

The legacy Phase 1/order tests were deliberately evolved to open a trusted zero-float shift before POS placement. The production open-shift requirement was not weakened to preserve old tests.

### Affected customer release validation

Customer release audit run **#137** on the same backend Phase 2 branch — `COMPLETE`.

No customer request contract was expanded with shift or terminal payment authority.

### Dashboard validation

Dashboard Phase 2 code head before documentation-only closeout:

`87a0e1013e3842e36b2ce3aad6ea8ce631bdb288`

Dashboard CI run **#58** — `COMPLETE`:

```text
npm dependency install      COMPLETE
lint                        COMPLETE
TypeScript typecheck        COMPLETE
unit tests                  COMPLETE
production build            COMPLETE
```

Coverage added for:

- same-origin shift BFF and caller-JWT forwarding;
- terminal credential never returned to JavaScript;
- open-shift gating of live POS;
- trusted integer-sen shift client parsing;
- cash movement calls and server-returned balance state;
- cash/unpaid checkout tender semantics;
- idempotency separation when tender changes;
- shift/payment order snapshot validation;
- paid cash cancellation hidden until refund authority exists.

### Live Supabase verification

Fresh 2026-09-12 invariant query:

```text
shifts                                  0
cash movements                          0
orders with shift                       0
invalid customer payment authority      0
authenticated open_shift execute        true
anonymous open_shift execute            false
authenticated direct shifts insert      false
authenticated direct cash insert        false
```

Zero live shift/order rows are expected because no production POS shift has been opened since the new authority was deployed.

Fresh security advisor:

- only the pre-existing `auth_leaked_password_protection` warning remains;
- no Phase 2-created security advisor finding exists.

Fresh performance advisor:

- only INFO-level unused-index observations remain;
- no unindexed Phase 2 foreign-key finding remains after `index_shift_cash_foreign_keys`.

## Deferred and non-goals

Phase 2 intentionally does not implement:

- external card/e-wallet/payment-processor settlement;
- cash refunds, returns or partial refunds;
- tax/accounting exports;
- inventory/recipe depletion;
- employee Auth-user provisioning or credential lifecycle;
- physical cash-drawer control;
- printer/KDS/payment-device health;
- branch hours/closures/capacity;
- delivery.

These boundaries are deliberate. Implementing processor/refund or deployment-heavy work here would couple later financial/integration authority into an unfinished dependency chain.

## App Store impact

Phase 2 changes staff Dashboard/POS operations only.

It adds:

- no customer iOS protected-data permission;
- no tracking SDK;
- no subscription or digital purchase;
- no new customer personal-data collection;
- no StoreKit/IAP requirement.

Café food/drink remains a physical-goods transaction. Phase 3 remains responsible for customer privacy, account deletion and App Store account requirements.

## Handoff

Phase 2 is `COMPLETE` and frozen as an unmerged audit boundary.

Phase 2 PRs:

```text
Hermann-33/Aida_System            PR #21 — draft, unmerged
Hermann-33/Aida_System-Dashboard  PR #18 — draft, unmerged
```

Do not merge either PR merely because implementation is complete.

Next dependency-ordered work is **Phase 3 — customer privacy and App Store account requirements**. Before any Phase 3 implementation, document its bounded plan in both repositories. After Phase 3 becomes `COMPLETE`, stop implementation and prepare the combined Phase 1–3 Astra audit boundary. Do not begin Phase 4 before that audit boundary is resolved or explicitly accepted.
