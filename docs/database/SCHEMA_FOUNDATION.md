# Database Schema Foundation

Updated: 2026-08-11

## Verdict

`TASK-DB-001` establishes the first real Supabase/Postgres foundation for AIDA Café. It is intentionally narrow: identity, trusted profile records, server-issued membership records, and student verification submissions/review state.

It does **not** implement menu, cart, quotes, orders, payments, loyalty ledgers, vouchers, POS/admin, reporting, marketing, or client wiring.

## Applied remote state

Remote project:

- Name: Aida System
- Project ref: `eswovqxqzfevcdwwcmuh`
- Region: `ap-southeast-1`

Before migration, the project was verified clean:

- `public` base tables: 0
- `public` enum types: 0
- `public` functions: 0
- old proof buckets `menu-images` and `marketing-assets`: absent

After migration, the foundation contains:

| Type | Objects |
|---|---|
| Schemas | `public`, `private` helper schema |
| Tables | `public.user_profiles`, `public.members`, `public.student_verifications` |
| Enums | `app_user_role`, `member_type`, `student_verification_status` |
| Public functions | `set_updated_at`, `generate_member_code`, `handle_new_auth_user` |
| Private RLS helpers | `private.current_app_role`, `private.is_staff_or_above` |
| Trigger on Auth | `on_auth_user_created_aida_profile` on `auth.users` |

## Tables

### `public.user_profiles`

Trusted application profile and role record keyed by Supabase Auth user ID.

Important columns:

- `user_id`: primary key, references `auth.users(id)`.
- `email`: copied from Auth at account creation.
- `display_name`, `phone`, `avatar_url`: basic profile fields.
- `app_role`: trusted application role; defaults to `customer`.
- `disabled_at`: application-level disable marker.
- timestamps: `created_at`, `updated_at`.

Customer updates are limited by column grants to basic profile fields. Role assignment is not intended to be user-editable.

### `public.members`

Server-owned AIDA membership identity.

Important columns:

- `id`: internal UUID.
- `user_id`: one-to-one link to `user_profiles`.
- `member_code`: server-issued stable code, format `AIDA-[A-Z0-9]{10}`.
- `member_type`: `standard`, `student`, or `staff`.
- `student_status`: `not_submitted`, `pending`, `verified`, `rejected`, or `expired`.
- `qr_payload_version`: positive integer for future QR payload evolution.
- `active`: membership active flag.

The frontend must not generate authoritative member codes.

### `public.student_verifications`

Student declaration and review workflow.

Important columns:

- `member_id`: linked member.
- `campus_id`: submitted campus/student identifier.
- `status`: pending/reviewed state.
- `reviewed_by`, `reviewed_at`, `review_note`: trusted reviewer state.

A customer can insert a pending submission for their own member record. Review/update is reserved for staff/admin/owner roles.

## RLS posture

All foundation tables have RLS enabled and forced.

| Table | Customer access | Staff/admin/owner access |
|---|---|---|
| `user_profiles` | Select/update own basic profile fields | Select all through trusted role helper |
| `members` | Select own membership record | Select all through trusted role helper |
| `student_verifications` | Select/insert own pending submissions | Select/update review state through trusted role helper |

Role checks use functions in the non-exposed `private` schema. The public schema does not expose RPC role helper functions.

## Advisor results

Security advisor after hardening:

- security lints: 0

Performance advisor after optimization:

- no RLS init-plan warnings remained;
- only unused-index INFO lints remained, expected on a new schema with no traffic.

## Migration files

| Migration | Purpose |
|---|---|
| `supabase/migrations/20260811101100_create_identity_membership_foundation.sql` | Foundation schema, triggers, grants and first RLS policies |
| `supabase/migrations/20260811102200_harden_foundation_role_helpers.sql` | Move role helpers out of exposed public schema |
| `supabase/migrations/20260811102700_optimize_foundation_rls_policies.sql` | Add reviewed-by index and optimize RLS calls |

## Next schema work

The next database task should not immediately wire Flutter. Recommended next step:

`TASK-DB-002: Design and migrate the published menu/catalogue foundation with public read policy, admin ownership boundary, and image/storage decision.`

That task should define menu categories, items, variants/modifiers, availability, and storage only after confirming owner menu fields and price rules.
