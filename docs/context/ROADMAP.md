# Roadmap

Updated: 2026-09-15

## Current status

Phases 1–5 are individually `COMPLETE`. Phase 6 — loyalty, rewards and vouchers — is the current `PARTIAL` implementation boundary. Phase PRs remain draft/unmerged unless explicitly authorized.

```text
Phase 1 — operational topology                         COMPLETE
Phase 2 — shift and cash authority                    COMPLETE
Phase 3 — customer privacy/account requirements       COMPLETE
Phase 4 — branch scheduling and pickup authority      COMPLETE
Phase 5 — inventory and recipes                       COMPLETE
Phase 6 — loyalty, rewards and vouchers               PARTIAL
Phase 7 — promotions and discounts                    blocked by Phase 6
Phase 8 — reporting/accounting/audit                  deferred
Phase 9 — payments/refunds/external integrations      deferred
Phase 10 — App Store final release gate               deferred
```

Latest completed-phase evidence is recorded in `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`.

## Trusted foundation through Phase 5

The product now has server-owned authority for:

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
- transactionally enforced stock consumption and cancellation reversal.

Dashboard privileged operations remain behind the same-origin HttpOnly BFF with caller-JWT forwarding. Customer Flutter submits intent through caller-bound public RPCs. Preview fixtures never become backend authority.

## Dependency-ordered continuation

### Phase 6 — loyalty, rewards and vouchers

Current plan: `docs/context/PHASE_6_LOYALTY_REWARDS_VOUCHERS_PLAN.md`.

Required completion boundary:

- append-only point/stamp ledger tied idempotently to trusted completed orders;
- server-derived loyalty balances;
- reward catalogue and trusted points costs;
- atomic points redemption;
- server-issued vouchers with expiry/status authority;
- authoritative voucher quote/application/consumption with stable commercial snapshots;
- customer wallet integration;
- Admin/Owner live support/configuration flows through the BFF;
- customer/POS order compatibility where member/voucher intent is supported;
- clean migration replay, transactional regressions, client CI/builds and Supabase advisors;
- synchronized architecture/contracts/security/status/handoff/App Store documentation.

### Phase 7 — promotions and discounts

Blocked until Phase 6 is `COMPLETE`.

Scope:

- promotion definitions and activation windows;
- branch/channel/member/student/item eligibility;
- fixed/percentage discount calculation;
- stacking/exclusion policy;
- authoritative quote/place enforcement;
- immutable applied-discount snapshots;
- Admin management through trusted BFF paths;
- abuse/security/regression coverage.

### Phase 8 — reporting, accounting and audit

Do not begin before Phase 7 closeout. Scope includes trusted sales/operations projections, branch/terminal/staff/shift breakdowns, tax-ready transaction records, export and privileged audit events.

### Phase 9 — payments, refunds and external integrations

External processor capture/settlement/refunds, processor idempotency/webhooks, accounting/device integrations and deployment-heavy work remain intentionally deferred until the internal authority layers are stable.

### Phase 10 — App Store release gate

Final iOS compatibility/release build, privacy manifest/App Privacy answers, physical account-deletion verification, production support/privacy URLs, review credentials/notes and final device/accessibility validation.

## Dependency rule

Do not skip ahead when a later domain depends on an earlier authority boundary.

```text
branch/topology
 -> shift/cash
 -> privacy/account boundary
 -> scheduling/capacity
 -> inventory/recipes
 -> loyalty/rewards/vouchers
 -> promotions/discounts
 -> reporting
 -> payments/refunds
```

Phases 1–5 have closed that chain through inventory. Phase 6 must close before Phase 7 starts.

## Independent audit policy

ADR-0013 permits the owner-directed Phase 1–3 Codex audit to run in parallel with Phases 4–7. A valid blocking finding reopens the affected earlier phase. Completed implementation does not authorize automatic PR merge.

## Deployment boundary

Hosted production deployment, external settlement/device integrations and final store submission remain deferred. A phase `COMPLETE` verdict proves its defined implementation/validation/documentation boundary; it does not imply those later deployment gates are complete.
