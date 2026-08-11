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

This foundation does not implement menu, cart, server quotes, orders, loyalty ledgers, rewards, vouchers, payments, staff POS, admin screens, marketing, storage buckets, or Flutter client wiring.
