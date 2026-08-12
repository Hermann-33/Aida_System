# Customer Backend Integration Plan

Updated: 2026-08-12

## Auth/member

Supabase Auth and owner-scoped member/profile source exist on the auth stack; final validation remains deferred.

## Catalogue — implemented source/data

Customer menu now uses `CatalogueRepository` -> Supabase `get_catalogue()`. One snapshot feeds categories, featured/popular and menu items. `catalogue_revision` Realtime events invalidate that snapshot. Base prices, sold-out state, images, size/variant deltas and compatible add-ons come from DB records.

Production runtime no longer has hardcoded menu items or `ItemSize`. Test-only catalogue fixtures live under `test/support/` and are explicit provider overrides.

## Next backend needs

Trusted quote/order creation must re-price all catalogue selections server-side. Loyalty, profile writes, student evidence/review, notifications and offline/cache policy remain future tasks.
