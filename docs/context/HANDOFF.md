# Current Handoff

Updated: 2026-08-12

## Current task

`TASK-MENU-001 — shared catalogue/menu persistence and dual-client integration`

**Verdict:** PARTIAL because validation was explicitly deferred.

Branch in both repos: `codex/task-menu-001-shared-catalogue`, stacked on TASK-AUTH-002.

## Implemented

- Live Supabase catalogue with forced RLS, audit evidence and Realtime revision signal.
- Seeded the exact 16 customer menu items that were previously hardcoded, including original prices/availability/images/flags.
- Moved Small/Medium/Large deltas into 27 per-item variant rows and drink add-on compatibility into 27 normalized links.
- Customer `CatalogueRepository` reads `get_catalogue()`; no production mock fallback exists.
- Flutter watches `catalogue_revision` and re-fetches after Admin writes.
- Admin Menu list/category creation/item editor now read/write shared DB data through BFF caller-JWT RPCs.
- Old customer runtime menu constants and `ItemSize` enum removed.
- Fake rating/bonus-points catalogue presentation removed rather than persisted.
- Live catalogue SQL regression passes; security advisor 0 lints.

## Deferred by user instruction

- Flutter analyzer/tests.
- Dashboard lint/typecheck/unit/build checks.
- Deployed Admin edit -> Realtime -> customer app browser/device E2E.
- Prior auth deployment/admin bootstrap validation.

## Non-goal retained

Dashboard POS checkout still contains preview transaction/catalogue wiring. It is not Admin catalogue authority and should be replaced with the trusted quote/order path, not patched piecemeal in this menu task.

## Next product task

`TASK-ORDER-001 — authoritative quote/cart/order foundation`.
