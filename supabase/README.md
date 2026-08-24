# Supabase Foundation

This directory contains the version-controlled Supabase foundation for AIDA Café.

## Project

- Remote project name: Aida System
- Remote project ref: `eswovqxqzfevcdwwcmuh`
- Region: `ap-southeast-1`
- Database engine observed during setup: Postgres 17

The project ref is not a secret. Do not commit database passwords, service-role keys, access tokens, `.env` files, or generated local credentials.

## Current migration ledger

| Migration | Purpose | Applied to remote |
|---|---|---|
| `20260811101100_create_identity_membership_foundation.sql` | Initial auth/profile/member/student-verification schema, triggers, grants, and RLS | Yes |
| `20260811102200_harden_foundation_role_helpers.sql` | Moves role helper functions into non-exposed `private` schema | Yes |
| `20260811102700_optimize_foundation_rls_policies.sql` | Adds reviewed-by index and optimizes RLS `auth.uid()` init plans | Yes |
| `20260812191500_integrate_customer_auth_member_directory.sql` | Customer Auth/member integration and controlled member directory | Yes |
| `20260812192500_fix_signup_member_code_generation.sql` | Hardens server member-code provisioning | Yes |
| `20260812195500_make_admin_member_directory_security_invoker.sql` | Keeps admin directory under caller authorization | Yes |
| `20260812231500_create_shared_catalogue.sql` | Shared catalogue, seed, RPCs, audit and revision signal | Yes |
| `20260812235000_harden_catalogue_rls_policies.sql` | Catalogue policy hardening | Yes |

The remote ledger records earlier application timestamps for these same names and retains four older setup/history rows. A 2026-08-13 read-only reconciliation compared every stored live statement with its repository migration: all eight current migrations are semantically identical after removing comments and formatting. The live schema contains exactly the expected nine RLS-enabled public tables, no public views or storage buckets, and only `catalogue_revision` in Realtime. This is harmless historical naming drift; preserve it, do not edit applied migrations, and create/commit future timestamped files before applying them.

## Local development commands

From repository root:

```bash
supabase start
supabase status
supabase db reset
supabase migration list
supabase db lint
supabase gen types typescript --local > supabase/types/database.types.ts
```

Linking the remote project is a developer-local action and should not commit secrets:

```bash
supabase login
supabase link --project-ref eswovqxqzfevcdwwcmuh
supabase migration list
```

## Security posture

- Public tables have RLS enabled and forced.
- Anonymous access has no table grants.
- Customer reads are owner-scoped.
- Staff/admin reads use trusted `user_profiles.app_role`, not user-editable auth metadata.
- Role helper functions live in the non-exposed `private` schema.
- Supabase security advisor returned no security lints after the hardening migration.

## Scope boundary

Identity/member and shared-catalogue foundations are implemented. This backend still does not implement authoritative cart/server quotes, orders, loyalty ledgers, rewards, vouchers, payments, staff POS operations, inventory, marketing, or reporting. The customer caches only minimum offline member-code material; that cache is not backend or business authority.
