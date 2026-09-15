# Roadmap

Updated: 2026-09-15

## Current status

Phases 1–7 are `COMPLETE` against their defined authority, regression, client, live-deployment and advisor boundaries. Phase 8–10 remain frozen pending explicit owner authorization.

```text
Phase 1 — operational topology                         COMPLETE
Phase 2 — shift and cash authority                    COMPLETE
Phase 3 — customer privacy/account requirements       COMPLETE
Phase 4 — branch scheduling and pickup authority      COMPLETE
Phase 5 — inventory and recipes                       COMPLETE
Phase 6 — loyalty, rewards and vouchers               COMPLETE
Phase 7 — promotions and discounts                    COMPLETE
Phase 8 — reporting/accounting/audit                  FROZEN
Phase 9 — payments/refunds/external integrations      FROZEN
Phase 10 — App Store final release gate               FROZEN
```

## Trusted foundation through Phase 7

The product now has server-owned authority for identity/roles, membership/privacy deletion, catalogue/pricing, topology, terminals, shifts/cash, scheduling/capacity, inventory/recipes, loyalty/rewards/vouchers, generalized promotions and immutable accepted commercial snapshots.

Dashboard privileged operations remain behind the same-origin HttpOnly BFF with caller-JWT forwarding. Customer Flutter submits intent through caller-bound RPCs. Preview fixtures never become backend authority.

## Phase 7 — promotions and discounts

Completed scope:

- fixed/percentage promotion definitions and activation windows;
- optional maximum discount, minimum subtotal and priority;
- branch/product/variant/add-on targeting;
- optional member requirement and global/per-member usage limits;
- exclusive/stackable policy and explicit voucher coexistence;
- automatic server-side promotion selection during quote;
- deterministic locked re-evaluation during placement;
- immutable applied-promotion commercial snapshots;
- final-use concurrency protection;
- Admin management through trusted BFF paths;
- strict Flutter and Dashboard voucher/promotion reconciliation;
- POS promotion presentation and preview isolation;
- live AIDA migration deployment plus fresh advisors.

Validated implementation:

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Live AIDA project `eswovqxqzfevcdwwcmuh` is `ACTIVE_HEALTHY`. Canonical migrations `20260915100000`, `20260915101000`, `20260915101100` were applied through the migration service as live history `20260915120917`, `20260915121057`, `20260915121119`. Fresh advisors have no new blocking Phase 7 finding.

## Phase 8 — reporting, accounting and audit

`FROZEN`. Do not begin until the owner explicitly authorizes continuation. Intended scope includes trusted sales/operations projections, branch/terminal/staff/shift breakdowns, tax-ready transaction records, export and privileged audit events.

## Phase 9 — payments, refunds and external integrations

`FROZEN`. External processor capture/settlement/refunds, processor idempotency/webhooks, accounting/device integrations and deployment-heavy work remain deferred.

## Phase 10 — App Store release gate

`FROZEN`. Final iOS compatibility/release build, privacy manifest/App Privacy answers, physical account-deletion verification, production support/privacy URLs, review credentials/notes and final device/accessibility validation remain later work.

## Dependency rule

```text
branch/topology
 -> shift/cash
 -> privacy/account boundary
 -> scheduling/capacity
 -> inventory/recipes
 -> loyalty/rewards/vouchers
 -> promotions/discounts
 -X-> reporting until owner authorization
 -> payments/refunds
 -> final release gate
```
