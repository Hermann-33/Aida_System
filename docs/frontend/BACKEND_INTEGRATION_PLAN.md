# Customer Backend Integration Plan

Updated: 2026-08-13

## Auth/member

Supabase Auth and owner-scoped member/profile source exist on the auth stack. Canonical live SQL regression and the full Flutter suite pass. ADR-0003's minimum offline QR material is cached durably per user and cleared on logout/user switch. Deployed/device Auth E2E remains open because real test identities and deployment are absent.

## Catalogue — implemented source/data

Customer menu now uses `CatalogueRepository` -> Supabase `get_catalogue()`. One snapshot feeds categories, featured/popular and menu items. `catalogue_revision` Realtime events invalidate that snapshot. Base prices, sold-out state, images, size/variant deltas and compatible add-ons come from DB records.

Production runtime no longer has hardcoded menu items or `ItemSize`. Test-only catalogue fixtures live under `test/support/` and are explicit provider overrides.

A provider regression proves a revision event causes a second catalogue fetch. Live anonymous RPC evidence confirms the Flutter contract contains 4 categories, 16 items, 27 variants and 27 compatible add-on links. Deployed Admin-write -> customer UI E2E remains open.

## Next backend needs

Trusted quote/order creation must re-price all catalogue selections server-side. Loyalty, profile writes, student evidence/review, notifications, and offline policy beyond the minimum member-code cache remain future tasks.
