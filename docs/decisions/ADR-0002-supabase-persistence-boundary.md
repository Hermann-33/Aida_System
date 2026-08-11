# ADR-0002: Supabase persistence boundary

- **Status:** Accepted direction; schema implementation pending
- **Date:** 2026-08-11
- **Decision owners:** Current AIDA project direction

## Context

The current task states that the Supabase database was reset/cleaned for actual implementation. Older AIDA specs describe Supabase versus an Express/Postgres rebuild as undecided, but current project direction resolves the intended managed persistence platform. The repository itself contains no Supabase dependency, configuration, migration, schema, or connection.

The Flutter prototype currently computes or generates sensitive outcomes locally: prices/subtotals, member codes/IDs, order numbers, ready status, loyalty display/affordability, and verification presentation.

## Decision

Supabase is the intended persistence/auth/storage boundary for the upcoming implementation. Actual database design begins from verified reset state and reviewed repository migrations; no old schema or proof table is assumed.

The untrusted frontend must not be authoritative for:

- item/modifier prices, discounts, quotes, taxes/fees, or order totals;
- points, stamps, loyalty ledgers, reward eligibility, voucher validity/use, or balances;
- customer/staff/admin roles or student verification status;
- member identifiers/codes, order identifiers, or status transitions;
- access control, ownership, audit history, or reporting facts.

Where simple table access cannot safely express an atomic business operation, use a controlled server/database operation with explicit authorization and idempotency. The exact API/table/function design is deferred to the foundation task.

## Security requirements

- Frontends receive only approved public/publishable client configuration—never secret/service-role keys.
- Every exposed table has RLS and explicit ownership/operational authorization.
- Authentication alone is not authorization; cross-user and role-abuse tests are required.
- User-editable metadata cannot grant roles or verification.
- Price/order/loyalty/voucher operations are revalidated and applied atomically on the trusted boundary.
- Storage buckets, views, and functions receive the same explicit access review as tables.

## Consequences

- Phase 2 must establish migration, local-dev, seed/test, RLS-test, type-generation, advisor, and rollback conventions before feature wiring.
- UI mock models guide requirements but do not dictate the database schema.
- `MemberRepository` remains a useful port, but additional capability-specific write/quote/order ports are likely required.
- Current mock/session features must retain their prototype label until their Supabase path and security tests exist.

## Evidence and limits

- Project direction: TASK-WF-001 context supplied by the owner.
- Current mock binding: `apps/customer/lib/application/providers.dart`.
- Current local calculations/IDs: `domain/model/cart.dart`, `features/cart/cart_screen.dart`, `features/auth/login_screen.dart`.
- Schema absence: repository inventory and `docs/context/SUPABASE_STATUS.md`.

No Supabase project or database object was inspected in this documentation-only task.
