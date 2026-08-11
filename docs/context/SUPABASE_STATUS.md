# Supabase Status

**Status date:** 2026-08-11
**Implementation state:** not connected
**Schema confidence:** none from this repository

## Verified repository facts

- `pubspec.yaml` has no Supabase dependency.
- No Supabase initialization or client call exists under `apps/customer/lib`.
- No `supabase/`, `migrations/`, `schemas/`, `config.toml`, seed, generated database types, or environment file was found.
- The active provider binds `MockMemberRepository`; all returned data is in Dart source.
- No repository file proves any table, policy, function, bucket, auth provider, or deployed project exists.

## Project-owner context

The current task states that the Supabase database has been reset/cleaned for actual implementation and positions Supabase as the upcoming persistence boundary. This is authoritative planning context, but the database was not connected or inspected during this documentation-only task.

Therefore:

- treat the database as reset/clean and schema state as **unknown/unverified**;
- assume no production schema until reviewed migrations in this repository prove it;
- do not claim that any old proof, demo, or legacy tables still exist;
- do not use the PRD’s historical Node/Express/Neon descriptions as current Supabase evidence.

## Frontend connection status

The frontend does not connect to Supabase. There is no auth session, database query, realtime subscription, storage access, function call, or public client configuration. `MemberRepository` is an integration seam, not an integration.

## Security and RLS expectations

Before exposing data to the client:

- enable RLS on every table in an exposed schema;
- grant Data API access deliberately and separately from RLS;
- use ownership/tenant/operational predicates—`authenticated` alone is not authorization;
- include `USING` and `WITH CHECK` where an update must preserve ownership;
- never authorize from user-editable metadata; use trusted app metadata or database role records with freshness considerations;
- keep secret/service-role keys out of Flutter and web builds;
- protect privileged functions, views, and storage objects; prefer invoker semantics and explicit grants;
- test customer, staff, admin, anonymous, cross-user, and revoked-session access paths.

These are expectations, not implemented policies.

## Required verification before database implementation

1. Confirm the Supabase organization/project reference, region, environments, and access owners without recording secrets in docs.
2. Inspect the live reset state and enabled Auth providers/extensions/Data API settings.
3. Decide declarative versus imperative migration workflow and commit the configuration first.
4. Translate product concepts into an reviewed schema; do not mirror UI models mechanically.
5. Define identity/profile/member separation, staff/admin authorization source, and student-verification workflow.
6. Define money, quote, order, loyalty-ledger, voucher, idempotency, and audit invariants.
7. Design and test RLS before client integration.
8. Decide Storage buckets and image ownership/validation.
9. Establish local development, seed/test data, type generation, rollback, and advisor/test commands.
10. Update this file with verified evidence and migration paths.

## Unknowns

Project reference, Auth provider configuration, schema objects, migration history, extensions, buckets, RLS posture, API exposure, backups, and retention are all unknown in this repository baseline.
