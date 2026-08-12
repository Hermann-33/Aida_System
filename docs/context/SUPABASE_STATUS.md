# Supabase Status

**Status date:** 2026-08-13
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

Canonical Auth/member SQL regression also passed live in a rolled-back transaction. Independent cleanup checks found zero synthetic Auth users, regression catalogue rows, or regression audit rows.

An anonymous-role contract query returned 4 categories, 16 items, 27 variants and 27 compatible add-on links with every field required by the Flutter adapter. Revision is 1 and `catalogue_revision` has exactly one publication entry.

Security advisor: **0 lints**. Performance advisor: six `unused_index` INFO notices only:

- `members_student_status_idx`
- `student_verifications_member_id_idx`
- `student_verifications_status_idx`
- `student_verifications_reviewed_by_idx`
- `catalogue_item_addons_addon_idx`
- `catalogue_audit_events_entity_idx`

These are informational on the current low/no-traffic schema and were not removed during validation.

## Migration-ledger discrepancy

The live ledger uses the following application versions for the canonical repository files:

| Repository version | Live version | Name |
|---|---|---|
| `20260811101100` | `20260811101525` | `create_identity_membership_foundation` |
| `20260811102200` | `20260811101620` | `harden_foundation_role_helpers` |
| `20260811102700` | `20260811101641` | `optimize_foundation_rls_policies` |
| `20260812191500` | `20260812112337` | `integrate_customer_auth_member_directory` |
| `20260812192500` | `20260812112457` | `fix_signup_member_code_generation` |
| `20260812195500` | `20260812113040` | `make_admin_member_directory_security_invoker` |
| `20260812231500` | `20260812152607` | `create_shared_catalogue` |
| `20260812235000` | `20260812154805` | `harden_catalogue_rls_policies` |

The live ledger exposes stored statements rather than a checksum. Read-only comparison found the first three files text-identical after line-ending/final-newline normalization; all eight have identical SQL after removing comments and normalizing whitespace/operator formatting. The mismatch is harmless historical timestamp/comment drift from applying the statements before their canonical repository filenames were fixed, not schema drift. Do not rename or rewrite applied migrations and do not manufacture a reconciliation migration. Future work must create and commit the timestamped migration before applying that same version.

Four older ledger rows remain (`create_aida_cafe_app_pos_loyalty_schema`, storage hardening, and a create/drop connection-test pair), but their described legacy public objects and storage buckets are absent. Current inventory is exactly three identity/member and six catalogue public tables, all with RLS enabled; there are no public views or storage buckets, and only `catalogue_revision` is in `supabase_realtime`.
