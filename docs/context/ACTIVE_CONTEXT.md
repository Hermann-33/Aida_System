# Active Context

**As of:** 2026-09-12  
**Current boundary:** Phase 2 — shift and cash authority  
**Current verdict:** `COMPLETE`  
**Next dependency:** Phase 3 — customer privacy and App Store account requirements  
**Audit state:** Phases 1 and 2 are frozen, draft, unmerged boundaries. Astra audit remains intentionally deferred until Phase 3 is `COMPLETE`.

## Product topology

AIDA Café is one product across:

- Flutter customer app — `Hermann-33/Aida_System`;
- React Dashboard/Admin/POS — `Hermann-33/Aida_System-Dashboard`;
- shared Supabase project `eswovqxqzfevcdwwcmuh`.

Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Trusted authority through Phase 2

The backend authority chain is now:

```text
branch
 -> sales point
 -> terminal
 -> employee branch scope
 -> shift
 -> POS order / cash ledger
```

Supabase/server owns trusted identity, role, disabled state, branch assignment, terminal identity, shift state, tender/payment classification, commercial pricing/order state and reconciliation facts.

Dashboard privileged operations remain behind the same-origin BFF:

- browser receives HttpOnly employee session cookies;
- terminal credential stays HttpOnly and server-readable only;
- BFF forwards the caller JWT to Supabase;
- no service-role secret is used for ordinary operational flows;
- no browser-readable employee bearer token is introduced.

Explicit UI Preview may continue to use fixtures, but preview identifiers and balances are never backend authority.

## Phase 2 implemented boundary

Trusted resources added or extended:

```text
public.shifts
public.cash_movements
public.orders.shift_id
public.orders.tender_type
public.orders.payment_state
public.orders.paid_at
```

Trusted behavior:

- open, lock, resume and close shift lifecycle;
- one live open/locked shift per terminal and per operator;
- integer-sen opening float;
- append-only `cash_in` / `cash_out` ledger;
- server-derived expected cash;
- actual count + server-derived variance at close;
- non-zero variance requires Admin/Owner authority;
- new live POS placement requires an open shift matching terminal, branch, sales point and authenticated operator;
- persisted shift/tender/payment attribution is protected from ordinary mutation;
- Phase 2 tender semantics are limited to `cash` and `unpaid`;
- customer orders remain shift-free and unpaid;
- paid cash cancellation is blocked until trusted refund authority exists.

Live Dashboard/POS Phase 2 paths:

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

## Phase 2 validation evidence

Documentation-only final heads before this context refresh:

```text
Aida_System
  b9e9eaa98c338a020dacc0d3374f710e1182b6d7
  Backend database audit #46   COMPLETE
  Customer release audit #138 COMPLETE

Aida_System-Dashboard
  fe5aebdb22264e21646bfcf5ca49b1fd0d9bfe2d
  Dashboard CI #59             COMPLETE
```

Phase 2 closeout evidence:

`docs/context/PHASE_2_SHIFT_CASH_CLOSEOUT_2026-09-12.md`

Phase 2 PRs remain draft/unmerged:

```text
Aida_System PR #21
Aida_System-Dashboard PR #18
```

Canonical Phase 2 migrations:

```text
20260911235419 create_shift_cash_authority_schema
20260911235626 implement_shift_cash_authority_functions
20260911235651 harden_shift_cash_authority_permissions
20260912000002 index_shift_cash_foreign_keys
```

The recorded closeout advisor review found no Phase 2-created security blocker. The only security warning was the pre-existing leaked-password-protection setting; performance findings were INFO-level unused-index observations after Phase 2 FK indexing was fixed.

## Deferred after Phase 2

Still outside the trusted boundary:

- production customer account deletion and privacy retention rules;
- customer consent/preferences and marketing notification controls;
- branch hours/closures/capacity and explicit customer pickup branch;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discount authority;
- tax/accounting/reporting;
- external payment capture/refunds/processor settlement;
- employee Auth-user provisioning and credential lifecycle;
- printer/KDS/payment-device hardware integrations;
- delivery and hosted deployment-heavy work.

## App Store state

Phase 2 changed staff Dashboard/POS behavior only. It added no customer iOS protected-data permission, tracking SDK, digital purchase, subscription or new customer personal-data field. Café food/drink remains a physical-goods transaction outside StoreKit/IAP.

The blocking App Store requirement is Phase 3: production whole-account deletion plus explicit personal-data retention/deletion and customer privacy/consent surfaces.

## Next boundary

Before Phase 3 implementation, commit a bounded Phase 3 plan to both repositories on dedicated Phase 3 branches derived from the frozen Phase 2 heads. After Phase 3 becomes `COMPLETE`, stop implementation and prepare the combined Phase 1–3 Astra audit boundary. Do not begin Phase 4.
