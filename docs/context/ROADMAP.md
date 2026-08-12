# Roadmap

Updated: 2026-08-13

## Completed foundations

- WF governance/import tasks: COMPLETE.
- DB-001 identity/member foundation: COMPLETE for scoped DB foundation.

## Auth/member

Customer source, analyzer, all Flutter tests, reviewed goldens, canonical live SQL regression, cleanup checks, and the ADR-0003 minimum offline member-code cache pass. Deployed/device Auth E2E remains open because real identities and deployment are absent. Formal status: PARTIAL under ADR-0004.

## Shared catalogue — TASK-MENU-001

Implemented:
- authoritative Supabase catalogue schema + RLS/audit/revision;
- former customer hardcoded 16-item menu seeded live;
- Flutter reads the shared catalogue and responds to revision invalidation;
- Admin Menu creates/updates shared categories/items/variants/add-on compatibility through caller-JWT BFF;
- production customer menu hardcodes and `ItemSize` removed.

Live database regression/security checks, the full Flutter suite, reviewed goldens, production-hardcode searches, provider-level Realtime invalidation, migration-ledger reconciliation, and mirrored fact synchronization pass. Dashboard lint/typecheck/85 tests/build and Playwright 6/6 also pass at commit `238e0ff211fe550f42ec4d4423724e3642282295`; Admin and POS browse the shared catalogue without runtime preview fallback. Deployed Admin-write -> customer UI E2E remains open. Formal status remains PARTIAL.

## Validation debt — TASK-AUTH-003

Provision approved real identities and deployment targets, then run deployed/device customer Auth and Admin-write -> customer-Realtime cross-client E2E. Do not use the shared catalogue result to promote preview checkout, totals, orders, or payments to trusted status.

## Next product phase

`TASK-ORDER-001 — authoritative quote/cart/order foundation` should establish server-owned pricing validation, quote/order IDs, idempotency and legal order transitions. Payment, loyalty, inventory and reporting follow later.
