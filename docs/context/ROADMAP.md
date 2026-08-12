# Roadmap

Updated: 2026-08-12

## Completed foundations

- WF governance/import tasks: COMPLETE.
- DB-001 identity/member foundation: COMPLETE for scoped DB foundation.

## Auth/member

Source implementation exists across customer + dashboard BFF, but final validation/deployment E2E remains deferred. Formal status: PARTIAL under ADR-0004.

## Shared catalogue — TASK-MENU-001

Implemented:
- authoritative Supabase catalogue schema + RLS/audit/revision;
- former customer hardcoded 16-item menu seeded live;
- Flutter reads the shared catalogue and responds to revision invalidation;
- Admin Menu creates/updates shared categories/items/variants/add-on compatibility through caller-JWT BFF;
- production customer menu hardcodes and `ItemSize` removed.

Live database regression/security checks pass. Client/toolchain/deployed E2E validation was explicitly deferred, so formal status remains PARTIAL.

## Next product phase

`TASK-ORDER-001 — authoritative quote/cart/order foundation` should establish server-owned pricing validation, quote/order IDs, idempotency and legal order transitions. Payment, loyalty, inventory and reporting follow later.
