# Supabase Status

**Status date:** 2026-08-12
**Remote project:** Aida System
**Project ref:** `eswovqxqzfevcdwwcmuh`
**Region:** `ap-southeast-1`
**Implementation state:** identity/membership database foundation created; neither frontend connected

## Verified reset and migration history

Before `TASK-DB-001`, remote `public` base tables, public enums and public functions were all verified at 0 and old proof buckets `menu-images` / `marketing-assets` were absent.

Applied migrations:

1. `20260811101100_create_identity_membership_foundation.sql`
2. `20260811102200_harden_foundation_role_helpers.sql`
3. `20260811102700_optimize_foundation_rls_policies.sql`

Canonical files live in `Hermann-33/Aida_System/supabase/`.

## Current objects

Tables:

- `public.user_profiles`
- `public.members`
- `public.student_verifications`

Enums:

- `public.app_user_role`
- `public.member_type`
- `public.student_verification_status`

Public trigger/support functions:

- `public.set_updated_at`
- `public.generate_member_code`
- `public.handle_new_auth_user`

Private RLS helpers:

- `private.current_app_role`
- `private.is_staff_or_above`

## Access posture

- RLS enabled and forced on every foundation table.
- Anonymous users have no direct table grants.
- Customer reads are owner-scoped.
- Basic customer profile updates are column-limited.
- Student submission is owner-scoped and pending-only.
- Review access requires trusted staff/admin/owner role.
- Role authorization uses trusted database records, not user-editable Auth metadata.

Security advisor after hardening: **0 lints**.

Performance advisor after optimization: auth init-plan warnings resolved; remaining unused-index INFO notices are expected on a fresh no-traffic schema.

## Client connection state

### Customer

No Supabase Flutter dependency/client initialization, session bootstrap, database query, Storage access, Realtime subscription or function call. Active adapter remains `MockMemberRepository`.

### Dashboard

No Supabase SDK, migrations, policies, keys or direct Supabase calls. Current preview repositories/fixtures and planned HTTP adapters are not authoritative backend integration.

## Migration ownership rule

Do not create a separate Supabase migration chain inside `Aida_System-Dashboard`. Database changes are committed to the canonical `Aida_System/supabase/` workspace and documented in both repositories. If backend ownership moves to a dedicated repository later, supersede the relevant ADR first.

## Not implemented yet

Branches/locations/terminals/employees, catalogue/modifiers/storage, quotes/orders/KDS, payments/refunds, loyalty/rewards/vouchers, inventory, marketing/publication, reporting/audit persistence and frontend integration.

## Next database task

`TASK-DB-002: Design and migrate the published menu/catalogue foundation using requirements from both customer and POS/Admin UIs, with published-read policy, privileged admin mutation boundary, stable IDs and an explicit image/storage decision.`

Local verification still required from a developer checkout: `supabase db reset`, `supabase db lint`, and seeded RLS scenarios.