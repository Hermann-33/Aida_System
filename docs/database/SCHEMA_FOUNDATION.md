# Database Schema Foundation

Updated: 2026-08-12

This reference is mirrored in both repositories. Canonical SQL/migrations currently live only in `Hermann-33/Aida_System/supabase/`.

## Verdict

`TASK-DB-001` established the first real Supabase/Postgres foundation for AIDA Café: identity, trusted profile/application role, server-issued membership identity and student verification. It does not implement catalogue, orders, payments, loyalty, POS operations, inventory, marketing/reporting or client wiring.

## Remote project

- Name: Aida System
- Ref: `eswovqxqzfevcdwwcmuh`
- Region: `ap-southeast-1`

Pre-migration reset verification: 0 public base tables, 0 public enum types, 0 public functions; old `menu-images` and `marketing-assets` buckets absent.

## Current objects

| Type | Objects |
|---|---|
| Tables | `public.user_profiles`, `public.members`, `public.student_verifications` |
| Enums | `app_user_role`, `member_type`, `student_verification_status` |
| Public support/trigger functions | `set_updated_at`, `generate_member_code`, `handle_new_auth_user` |
| Private RLS helpers | `private.current_app_role`, `private.is_staff_or_above` |
| Auth trigger | `on_auth_user_created_aida_profile` |

`user_profiles` keys to Supabase Auth and stores trusted application role/basic profile. `members` stores server-issued stable member code, type, student status, QR payload version and active state. `student_verifications` stores campus ID submission plus trusted review state.

## RLS posture

RLS is enabled and forced on all foundation tables. Anonymous users have no direct table grants. Customers select their own profile/member and can update only permitted profile columns. Student submission is own-member/pending-only. Staff/admin/owner review/select access uses trusted role helpers in non-exposed `private` schema.

Security advisor after hardening: 0 lints. Performance advisor has no remaining auth init-plan warnings; unused-index INFO notices are expected on fresh no-traffic schema.

## Migration files

1. `20260811101100_create_identity_membership_foundation.sql`
2. `20260811102200_harden_foundation_role_helpers.sql`
3. `20260811102700_optimize_foundation_rls_policies.sql`

## Next schema direction

`TASK-DB-002` should define the shared published catalogue using both customer and POS/Admin requirements before implementing client wiring.