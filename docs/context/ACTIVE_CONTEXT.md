# Active Context

**As of:** 2026-08-12
**Current implementation task:** `TASK-MENU-001 — shared catalogue/menu persistence and dual-client integration`
**Current task verdict:** PARTIAL

## Current product reality

Customer auth/member source from TASK-AUTH-001 is implemented but its final client/deployment validation remains deferred by user instruction. TASK-AUTH-002 dashboard BFF source also remains stacked/unmerged.

TASK-MENU-001 now adds the shared catalogue on top of that stack:

- live Supabase tables for categories, items, per-item variants, compatible add-ons, revision and audit evidence;
- 4 categories / 16 customer menu items / 27 variants / 27 add-on links seeded from the former customer hardcodes;
- customer Flutter runtime reads `public.get_catalogue()` and has no production menu fixture fallback;
- customer watches the singleton `catalogue_revision` Realtime signal and re-fetches the RLS-filtered snapshot after Admin changes;
- Admin Menu reads and writes the shared catalogue through the same-origin BFF using the administrator caller JWT;
- size deltas and add-on compatibility are database data; the old Dart `ItemSize` enum and runtime menu constants are removed;
- fake ratings/reward bonus values were not promoted to catalogue truth.

Live Supabase catalogue regression passes transactionally. Security advisor is 0 lints; performance advisor has only expected unused-index INFO on the new schema.

## Deliberately still preview

POS cart/order/payment transaction state and its checkout-specific preview wiring are not made authoritative by this menu task. Trusted quote/order pricing remains a separate backend task.

## Deferred validation debt

Per explicit user direction, Flutter analyzer/tests, dashboard lint/typecheck/tests/build and deployed Admin-write -> customer-app E2E are deferred. ADR-0004 therefore keeps the formal verdict `PARTIAL` even though the requested source/data implementation is present.

## Next product task

`TASK-ORDER-001 — authoritative quote/cart/order foundation` after the user chooses to proceed. Auth/menu validation debt remains tracked and must be closed before release.
