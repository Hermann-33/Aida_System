# Frontend Security Review

**Review date:** 2026-08-11
**Scope:** repository-only frontend/documentation audit
**Verdict:** prototype posture; not production-ready

## Current posture

The app has no live credential, API, database, or payment integration, which limits current external attack surface. It also means security controls are mostly comments/types rather than exercised controls. `MockMemberRepository` accepts all auth operations, the local auth gate is a boolean, and sensitive business outcomes are simulated in the client.

Positive foundations:

- currency uses integer sen;
- typed failure classes exist;
- repository comments state the server should own balances/eligibility;
- QR semantics and image fallbacks support usability;
- specs recognize cache isolation, static-QR sharing, idempotent redemption, and secure token-storage concerns.

None of those substitute for authenticated integration, RLS, trusted operations, or security tests.

## Secret exposure check

The audit searched tracked filenames/content for environment files, keys, credentials, tokens, database URLs, Supabase references, and common secret names. No `.env`, private key, credential file, Supabase config, migration, API key, service-role key, token value, password value, or private database URL was found.

The PRD names environment variable identifiers and public URLs but does not disclose their values. The demo member data is personal-looking fixture content, not a secret, but should not be confused with a real person or retained in production seeds.

This was a repository text/filename audit, not a full entropy/history/remote secret scan. Git history and external deployment settings were not audited.

## Client-side trust risks

| Risk | Current evidence | Required control |
|---|---|---|
| Price/total tampering | `cart.dart`, `cart_screen.dart` compute from client menu | Server quote and order creation revalidate IDs/configuration and calculate totals |
| Member/order identifier forgery | `login_screen.dart` and `cart_screen.dart` generate IDs | Server-generated unique identifiers; ignore client claims |
| Role/verification spoofing | `Member.studentStatus` comes from mock/session object | Trusted role/verification records; RLS/server authorization |
| Order-status forgery | timer and `OrderStatus.ready` | Valid staff-driven server transition model |
| Loyalty/reward manipulation | mock balance and local affordability comparison | Ledger-derived balance and atomic redemption/use operations |
| UI-only authorization | boolean auth gate and hidden/missing admin UI | Authenticated server identity plus ownership/role checks on every operation |

The client may provide intent and display estimates. It must never be the final authority for value, identity, authorization, or operational state.

## Authentication and session risks

- Any sign-in attempt succeeds and no token/session exists.
- Sign-up provisions a session identity locally.
- Logout clears only auth/member edits, leaving cart, favorites, history, and navigation state alive inside the same `ProviderScope`.
- No startup loading/refresh/revocation state exists.
- No secure/durable storage or per-user cache namespace exists.
- Social login controls are visual placeholders.
- Password reset is simulated and has no redirect/deep-link validation.

Required direction:

- Supabase Auth session bootstrap/refresh/logout/revocation behavior;
- generic recovery responses and approved redirect allow-list;
- shared-device/user-switch cache isolation;
- reauthentication for destructive/sensitive actions;
- roles/verification from trusted app metadata or database records—not user-editable metadata;
- awareness that JWT authorization claims may be stale until refresh and that user deletion alone does not necessarily invalidate issued tokens.

## QR sharing and membership risks

The QR directly encodes a permanent member code. A screenshot can be shared. The design spec accepts this risk for offline access and proposes staff name verification, but no POS app or verification operation exists here.

Controls required before launch:

- treat the code as a lookup identifier, not proof of identity;
- limit data returned by lookup and rate-limit enumeration;
- require staff authorization for member/value operations;
- show sufficient member context for human verification without excessive personal disclosure;
- audit reward/voucher/order-affecting uses;
- define response to lost/shared codes and observed abuse;
- test offline card availability without persisting session tokens or unrelated sensitive data.

## Loyalty fraud risks

- Client shows points/stamps/rewards and decides button affordability.
- Redemption currently does nothing, but a naïve integration could subtract points in Dart.
- Voucher Apply currently relies on showing the screen to staff.
- Concurrent/replayed redeem or consume operations could double-spend.
- Local daily check-in could be automated or clock-manipulated if tied to value.

Required controls:

- append-only or equivalently auditable loyalty events;
- atomic, idempotent balance check and entitlement issuance;
- atomic staff-authorized voucher consumption linked to an order;
- server time, expiry, eligibility, and uniqueness rules;
- concurrency/replay/insufficient-balance/expired-voucher tests;
- no direct client write to balances or verification flags.

## Order and price tampering risks

The client currently holds prices, modifier compatibility, subtotal, payment label, order number, and status. A real create-order call must not accept these as facts.

The trusted boundary must:

- load current published item/variant/modifier records;
- reject unavailable or incompatible selections;
- calculate discounts, fees/tax, loyalty effects, and total;
- expire quotes and handle catalogue changes;
- bind idempotency to user and payload;
- let only authorized operations set paid/accepted/preparing/ready/completed/cancelled states;
- preserve immutable receipt line descriptions/prices after purchase.

Raw card/payment credentials must stay with an approved provider; the AIDA client/database should store only necessary references/status under a reviewed payment model.

## Supabase/RLS expectations

No RLS exists in this repository. Before client access:

- enable RLS on every table in exposed schemas;
- treat Data API grants and RLS as separate controls;
- restrict customer rows with ownership predicates, not `authenticated` alone;
- use both `USING` and `WITH CHECK` for ownership-preserving updates;
- test cross-user select/insert/update/delete and anonymous access;
- restrict staff/admin scope by trusted records/claims and test role removal/freshness;
- protect views with invoker behavior or keep them unexposed;
- avoid privileged definer functions as a shortcut; keep genuinely privileged operations private, explicitly granted, identity-checking, and audited;
- apply equivalent policies to Storage objects and Realtime subscriptions;
- never embed secret/service-role keys in Flutter/web builds.

## Privacy and data handling

The product anticipates names, emails, phone numbers, birthdays, campus IDs, membership/order/loyalty history, and potentially images. Retention, consent, access/export, correction, deletion/anonymization, staff visibility, audit retention, and backup deletion remain unresolved. Implementing account deletion before these rules are decided risks either privacy non-compliance or broken sales/audit records.

## Unresolved security decisions

1. Student verification method and evidence retention.
2. Staff/admin role source, scope, approval, revocation, and MFA expectations.
3. Static QR abuse threshold and fallback/rotation policy.
4. Voucher expiry/refund/consume and dispute rules.
5. Scheduled order payment/cancellation/no-show rules.
6. Account deletion versus anonymization and legal retention.
7. Offline cache content, encryption, expiry, and logout behavior per platform.
8. Payment provider and boundary.
9. POS/admin repository/deployment ownership and shared contracts.
10. Security logging, incident response, backup/restore, and production environment separation.

## Required security gates

Security completion requires migration-reviewed schema, RLS policy tests, adapter/integration abuse tests, no-secret build verification, dependency review, Supabase advisors, auth/session/shared-device tests, order/loyalty concurrency/idempotency tests, and an updated threat-focused review before UAT/deployment.
