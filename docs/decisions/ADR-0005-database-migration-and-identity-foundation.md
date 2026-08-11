# ADR-0005: Database migration and identity foundation

## Status

Accepted

- Date: 2026-08-11
- Type: Database, security, migration workflow
- Supersedes: none
- Preserves: ADR-0002 Supabase persistence boundary; ADR-0004 full-stack completion gate

## Context

AIDA Café is moving from a Flutter customer prototype into real implementation. The customer app currently holds identity, membership, student status, QR/member code, cart/order and loyalty behavior in mock or local/session state.

The Supabase project was reset and verified clean before implementation. The repository had no `supabase/` directory, migrations, schema, local-dev instructions or RLS tests. Starting frontend wiring before a trusted persistence and access-control foundation would let mock assumptions become production architecture.

## Decision

The repository will use version-controlled Supabase migrations as the authority for database schema changes.

`TASK-DB-001` establishes the first database foundation around identity and membership only:

- Supabase Auth remains the source of login identity.
- `public.user_profiles` stores trusted app profile and application role data keyed by `auth.users(id)`.
- `public.members` stores server-issued AIDA membership identity and stable member codes.
- `public.student_verifications` stores student declaration and trusted review state.
- A trigger on `auth.users` provisions profile and member records for new users.
- RLS is enabled and forced on every foundation table.
- Role helper functions live in a non-exposed `private` schema.
- Anonymous users receive no table grants.

The first foundation deliberately excludes menu, cart, quote, order, loyalty, voucher, payment, storage, POS/admin, reporting and frontend wiring.

## Consequences

### Positive

- The project now has a reproducible migration baseline.
- Member codes are server-issued rather than frontend-generated.
- Student verification is represented as a review workflow, not a client-side declaration.
- Staff/admin/owner access is based on trusted database role records rather than editable client metadata.
- Future Flutter work has a clear first persistence boundary.

### Trade-offs

- The schema is incomplete for real ordering and loyalty.
- Staff/admin role assignment is not yet operationalized by UI or controlled function.
- Local and CI RLS tests still need seeded auth users and role scenarios.
- Flutter cannot yet remove the mock repository without additional schema and adapter work.

## Security and data impact

- RLS is mandatory and forced for exposed foundation tables.
- `authenticated` alone is not authorization.
- Customer profile updates are limited through column-level grants.
- Private role helpers are used for RLS and are not exposed as public RPC functions.
- Service-role keys and database secrets must not be committed or sent to Flutter/web builds.
- QR/member code possession remains an identifier, not proof of authorization.

## Alternatives considered

### Option A — Wire Flutter directly to mock-shaped tables

Rejected. It would prematurely encode UI prototype assumptions into production persistence and leave price/order/loyalty trust boundaries unclear.

### Option B — Create the full café schema in one migration

Rejected for this phase. Menu, quote/order, loyalty, voucher and POS/admin models require separate decisions and tests.

### Option C — Delay all database work until frontend integration

Rejected. Integration without a reviewed schema/RLS foundation invites security and drift problems.

### Option D — Use a custom backend before Supabase schema

Rejected for now by ADR-0002. Supabase is the accepted persistence/auth/storage direction unless superseded by a later ADR.

## Scope boundaries

This decision does not authorize:

- Flutter Supabase client wiring;
- adding service-role keys or secrets to the repo;
- menu/catalogue, order, payment, loyalty, voucher, POS/admin or reporting tables;
- changing customer UI behavior;
- granting real staff/admin access without a controlled role-management task;
- treating profile/member foundation as full authentication feature completion.

## Rollback or supersession rule

A later ADR may supersede this if the project changes persistence strategy or splits app/database ownership. Existing applied migrations should not be edited after merge; change the database through new forward migrations or a deliberate reset approved by the owner.

## Activation evidence

- Branch: `codex/task-db-001-supabase-foundation`
- Migrations:
  - `20260811101100_create_identity_membership_foundation.sql`
  - `20260811102200_harden_foundation_role_helpers.sql`
  - `20260811102700_optimize_foundation_rls_policies.sql`
- Remote project: `eswovqxqzfevcdwwcmuh`
- Supabase security advisor after hardening: 0 lints
- Context updates: `SUPABASE_STATUS.md`, `ACTIVE_CONTEXT.md`, `ARCHITECTURE.md`, `CODEBASE_MAP.md`, `ROADMAP.md`, `HANDOFF.md`, `AUDIT_LOG.md`
