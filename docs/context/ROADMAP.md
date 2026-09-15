# Roadmap

Updated: 2026-09-15

## Current status

Phases 1–6 are `COMPLETE`. Phase 7 — promotions and discounts — has completed repository implementation and validation but remains `PARTIAL` because the live AIDA Supabase deployment/advisor gate is currently inaccessible from the connected Supabase account. Phase 8–10 remain frozen.

```text
Phase 1 — operational topology                         COMPLETE
Phase 2 — shift and cash authority                    COMPLETE
Phase 3 — customer privacy/account requirements       COMPLETE
Phase 4 — branch scheduling and pickup authority      COMPLETE
Phase 5 — inventory and recipes                       COMPLETE
Phase 6 — loyalty, rewards and vouchers               COMPLETE
Phase 7 — promotions and discounts                    PARTIAL
Phase 8 — reporting/accounting/audit                  FROZEN
Phase 9 — payments/refunds/external integrations      FROZEN
Phase 10 — App Store final release gate               FROZEN
```

## Trusted foundation through Phase 7 code

The validated repository implementation now has server-owned authority for:

- customer/employee identity and trusted role/disabled state;
- membership identity and customer privacy/account deletion;
- catalogue/modifier compatibility and integer-sen pricing;
- authoritative quote/order identity/status/commercial snapshots;
- branch/sales-point/terminal topology and employee branch scope;
- terminal enrolment/revocation with HttpOnly BFF credential handling;
- shift lifecycle, cash ledger, expected drawer and variance;
- POS shift/tender/payment attribution;
- branch-local service windows, dated exceptions and scheduled slot capacity;
- explicit customer pickup-branch validation;
- inventory items, branch balances, recipes/components and append-only movement history;
- transactionally enforced stock consumption and cancellation reversal;
- loyalty points/stamps, rewards, issued vouchers and atomic voucher consumption;
- generalized fixed/percentage promotions with branch/catalogue targeting, time windows, subtotal thresholds, stacking, voucher coexistence, member/global usage limits and immutable application snapshots.

Dashboard privileged operations remain behind the same-origin HttpOnly BFF with caller-JWT forwarding. Customer Flutter submits intent through caller-bound public RPCs. Preview fixtures never become backend authority.

## Phase 7 — promotions and discounts

**Repository implementation:** complete.  
**Formal phase verdict:** `PARTIAL` pending live AIDA deployment/advisors.

Implemented scope:

- promotion definitions and activation windows;
- fixed and percentage discount calculation with optional cap;
- branch/product/variant/add-on targeting;
- optional member requirement, minimum subtotal and usage limits;
- exclusive/stackable policy plus explicit voucher coexistence;
- automatic server-side promotion selection during quote;
- locked re-evaluation during placement;
- immutable accepted-promotion commercial snapshots;
- final-use concurrency protection;
- Admin management through trusted BFF paths;
- strict Flutter and Dashboard promotion/voucher commercial reconciliation;
- POS promotion presentation and preview isolation.

Validated implementation heads:

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Remaining Phase 7 completion work:

- regain authorized access to Supabase project `eswovqxqzfevcdwwcmuh`;
- deploy/reconcile canonical Phase 7 migrations `20260915100000`, `20260915101000`, `20260915101100`;
- run live smoke verification;
- run fresh security/performance advisors;
- resolve any blocking findings and record final evidence.

## Phase 8 — reporting, accounting and audit

Do not begin before Phase 7 is `COMPLETE` and the owner explicitly authorizes continuation. Scope includes trusted sales/operations projections, branch/terminal/staff/shift breakdowns, tax-ready transaction records, export and privileged audit events.

## Phase 9 — payments, refunds and external integrations

External processor capture/settlement/refunds, processor idempotency/webhooks, accounting/device integrations and deployment-heavy work remain intentionally deferred until the internal authority layers are stable.

## Phase 10 — App Store release gate

Final iOS compatibility/release build, privacy manifest/App Privacy answers, physical account-deletion verification, production support/privacy URLs, review credentials/notes and final device/accessibility validation.

## Dependency rule

```text
branch/topology
 -> shift/cash
 -> privacy/account boundary
 -> scheduling/capacity
 -> inventory/recipes
 -> loyalty/rewards/vouchers
 -> promotions/discounts
 -X-> reporting while Phase 7 is PARTIAL
 -> payments/refunds
 -> final release gate
```

A repository-green phase is not automatically a live-complete phase. Deployment/advisor evidence must be recorded when the phase changes the live Supabase authority surface.
