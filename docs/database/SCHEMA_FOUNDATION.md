# Database Schema Foundation

Updated: 2026-08-12

## Identity/member foundation

`user_profiles`, `members` and `student_verifications` remain the trusted identity/membership foundation under forced RLS.

## Shared catalogue foundation

TASK-MENU-001 adds:

- `catalogue_categories` — server UUID, slug/name/image, sort, active state.
- `catalogue_items` — server UUID/SKU/slug, category, product/addon kind, integer-sen base price, publication/availability/merchandising flags, image/volume/prep route/sort.
- `catalogue_item_variants` — item-specific option label/code, sen delta, default/availability/sort.
- `catalogue_item_addons` — normalized product-to-addon compatibility.
- `catalogue_revision` — singleton public read-only invalidation counter; only catalogue table in Realtime publication.
- `catalogue_audit_events` — append-only trusted write evidence; no ordinary client table grant.

Controlled RPCs: `get_catalogue()`, `save_catalogue_category(jsonb)`, `save_catalogue_item(jsonb)`.

All exposed catalogue tables force RLS. Canonical migrations are `20260812231500_create_shared_catalogue.sql` and `20260812235000_harden_catalogue_rls_policies.sql`.
