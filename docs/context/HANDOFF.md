# Current Handoff

Updated: 2026-09-12

## Current boundary

`TASK-OPS-003 — Phase 2 shift and cash authority`

**Verdict:** `COMPLETE`  
**State:** frozen, draft and unmerged. Astra audit is intentionally deferred until Phase 3 is also `COMPLETE`.

Detailed evidence:

`docs/context/PHASE_2_SHIFT_CASH_CLOSEOUT_2026-09-12.md`

Phase 2 branches:

```text
Hermann-33/Aida_System
  codex/phase-2-shift-cash-authority

Hermann-33/Aida_System-Dashboard
  codex/phase-2-shift-cash-authority
```

Phase 2 PRs:

```text
Customer/backend PR #21 — draft, unmerged
Dashboard/POS PR #18 — draft, unmerged
```

## Trusted state handed off

AIDA now has authoritative operational topology through shift/cash attribution:

```text
branch
 -> sales point
 -> terminal
 -> employee branch scope
 -> shift
 -> POS order / cash ledger
```

Backend authority covers:

- trusted employee role/disabled state and branch assignments;
- trusted sales points and terminals;
- one-time manager-issued terminal enrolment with HttpOnly credential storage;
- open/lock/resume/close shift lifecycle;
- one live open/locked shift per terminal and per operator;
- integer-sen opening float;
- append-only non-sale cash movements;
- server-derived expected cash and closing variance;
- Admin/Owner authority for non-zero variance close;
- immutable shift/tender/payment attribution on new POS orders;
- cash/unpaid Phase 2 tender semantics;
- customer orders remain shift-free and unpaid;
- paid cash cancellation is blocked until a trusted refund flow exists.

Dashboard authority rules remain unchanged:

- same-origin HttpOnly BFF;
- caller JWT forwarded upstream;
- terminal credential readable only by the server request path;
- no browser-readable employee bearer token;
- no service-role secret in normal privileged flows;
- preview fixtures never act as backend authority.

## Validation evidence

Final documentation-only Phase 2 heads before the governance refresh:

```text
Aida_System
  b9e9eaa98c338a020dacc0d3374f710e1182b6d7
  Backend database audit #46   COMPLETE
  Customer release audit #138 COMPLETE

Aida_System-Dashboard
  fe5aebdb22264e21646bfcf5ca49b1fd0d9bfe2d
  Dashboard CI #59             COMPLETE
```

The clean backend replay includes:

```text
branch authority regression                 COMPLETE
operational topology regression            COMPLETE
order regression                           COMPLETE
scheduled-order operations regression      COMPLETE
shift and cash authority regression        COMPLETE
```

Canonical Phase 2 migrations:

```text
20260911235419 create_shift_cash_authority_schema
20260911235626 implement_shift_cash_authority_functions
20260911235651 harden_shift_cash_authority_permissions
20260912000002 index_shift_cash_foreign_keys
```

The Phase 2 advisor review recorded no new security blocker. The remaining leaked-password-protection warning predates Phase 2; performance output contains only INFO-level unused-index observations after Phase 2 FK coverage was corrected.

## App Store handoff

Phase 2 affects staff Dashboard/POS operations only. It adds no customer iOS protected-data permission, tracking SDK, subscription, digital purchase or new customer personal-data field. Physical café sales remain outside StoreKit/IAP.

Production whole-account deletion and explicit personal-data retention/deletion remain mandatory Phase 3 work before any App Store release candidate.

## Deferred/non-goals

Still deferred:

- production customer account deletion/privacy retention;
- customer consent/preferences and marketing notification controls;
- branch hours/closures/capacity and explicit customer pickup branch;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- reporting/tax/accounting;
- payment processor settlement and refunds;
- employee credential lifecycle;
- printer/KDS/payment-device hardware integrations;
- delivery and deployment-heavy work.

## Next action

Create dedicated Phase 3 branches from the corrected Phase 2 heads and first commit a mirrored Phase 3 plan covering customer privacy and App Store account requirements. Do not merge Phase 1 or Phase 2. After Phase 3 becomes `COMPLETE`, stop implementation and prepare the combined Phase 1–3 Astra audit boundary. Do not begin Phase 4.
