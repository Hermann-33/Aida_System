# Supabase Status

**Status date:** 2026-08-12
**Project:** Aida System
**Ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`

## Identity/membership

Existing TASK-DB-001/TASK-AUTH-001 objects remain live, including forced-RLS `user_profiles`, `members`, `student_verifications` and admin/owner member-directory RPC.

## Catalogue — TASK-MENU-001

Applied canonical migrations:

1. `20260812231500_create_shared_catalogue.sql`
2. `20260812235000_harden_catalogue_rls_policies.sql`

Live objects:
- `catalogue_categories`
- `catalogue_items`
- `catalogue_item_variants`
- `catalogue_item_addons`
- `catalogue_revision`
- `catalogue_audit_events`
- `get_catalogue()`
- `save_catalogue_category(jsonb)`
- `save_catalogue_item(jsonb)`

Seed: 4 categories, 16 items, 27 variants, 27 compatible add-on links. Only `catalogue_revision` is in the `supabase_realtime` publication.

Canonical catalogue SQL regression passed live in a rolled-back transaction: public read, admin create/update, revision advance, audit evidence, customer mutation denial and unpublished-item hiding.

Security advisor: **0 lints**. Performance advisor: only unused-index INFO on the new no-traffic schema.
