# Phase 3 — Customer Privacy and App Store Account Requirements Plan

**Task:** `TASK-PRIVACY-001`  
**Status:** `PARTIAL` — plan committed; implementation begins from this boundary  
**Branch:** `codex/phase-3-customer-privacy-account-requirements`  
**Audit policy:** Astra remains deferred. After Phase 3 is `COMPLETE`, stop implementation and prepare the combined Phase 1–3 Astra audit boundary. Do not begin Phase 4.

## Objective

Close the customer privacy/account boundary required before an App Store release candidate without weakening the trusted commercial and operational history established in Phases 1–2.

Phase 3 must provide:

- production self-service whole-account deletion initiated inside the customer app;
- explicit deletion/anonymization versus retained transaction-data rules;
- customer privacy/notification preferences with marketing default-off;
- accessible privacy policy, terms and support/contact surfaces;
- explicit guest/public versus authenticated feature boundaries;
- an iOS permission/data-minimization audit;
- executable authorization/deletion/retention regressions and customer release validation.

## Dependency rationale

Account deletion cannot be implemented safely before authoritative orders exist. Existing customer orders contain immutable commercial and operational records that may need to survive account deletion for accounting/audit purposes while losing their customer identity linkage.

Phase 3 therefore depends on the Phase 1–2 chain:

```text
trusted customer identity
 -> authoritative order history
 -> trusted branch/terminal/shift/payment attribution
 -> deletion/anonymization boundary
```

External payment processors, refunds, inventory, branch scheduling and deployment-heavy integrations remain downstream and must not be pulled into this phase.

## Current starting state

A preserved draft already exists:

- `supabase/drafts/20260826120000_add_customer_account_deletion.sql`;
- Flutter `deleteAccount()` repository/provider wiring;
- Settings-screen deletion confirmation UI;
- feature gate `AIDA_ENABLE_ACCOUNT_DELETION_DRAFT`, default `false`.

The draft is evidence only, not production authority. It uses a permanent placeholder row inside `auth.users` to retain `orders.created_by_user_id`. Phase 3 will not promote that placeholder pattern unchanged.

Current order schema behavior matters:

- `orders.customer_user_id` uses `on delete set null`;
- `orders.member_id` uses `on delete set null`;
- `orders.created_by_user_id` is currently `not null` + `on delete restrict`;
- the order immutability trigger blocks arbitrary identity reassignment;
- customer order constraints currently assume customer/member identity is present.

## Data classification and retention contract

### Delete with the customer account

The following customer identity/personal records must be removed when deletion completes unless a later documented legal requirement says otherwise:

- Supabase Auth user/identities/sessions and refresh-token authority;
- `user_profiles` PII: email, display name, phone, avatar;
- `members` customer/member identity and member code;
- student-verification records and campus identifier;
- customer privacy/marketing preference row;
- customer-device/local cached membership data;
- any future personal profile fields explicitly classified as deletable.

### Retain only in anonymized transaction history

The following commercial/operational facts may remain because they are transaction/audit records rather than a continuing customer profile:

- order number and immutable line snapshots;
- quantities/prices/totals/currency/pricing version;
- fulfilment/status timestamps;
- branch/sales-point/terminal/shift attribution;
- tender/payment-state facts;
- operational order events needed for fulfilment/audit.

Retained rows must no longer contain a stable customer/member/Auth identifier after deletion.

### Prohibited retention

Do not keep a synthetic permanent customer Auth account merely to satisfy an order foreign key. Do not retain customer email, phone, member code, student campus ID or equivalent profile identifiers in retained transaction rows.

## Backend design

### 1. Anonymized retained-order state

Extend `orders` with explicit deletion/anonymization state rather than inventing a fake customer identity.

Planned invariant:

```text
active customer order:
  customer_user_id != null
  member_id != null
  created_by_user_id != null
  customer_deleted_at == null

anonymized retained customer order:
  customer_user_id == null
  member_id == null
  created_by_user_id == null
  customer_deleted_at != null
```

POS/staff order actor retention must not be weakened by the customer deletion path.

The order immutability trigger will permit only one narrowly scoped internal transition from an active customer order to the anonymized retained state. Ordinary clients must remain unable to mutate identity/commercial fields.

### 2. Self-service deletion RPC

Create an authenticated no-target-parameter RPC such as `delete_own_account()`.

Requirements:

- `auth.uid()` is mandatory;
- trusted application role must be `customer`;
- only rows owned by the caller may be anonymized;
- transaction history is anonymized before Auth deletion;
- profile/member/student/preference records disappear through explicit deletion/cascade rules;
- the caller cannot nominate another user ID;
- `anon`/`public` execution is denied;
- direct client DML on retained order identity fields remains denied;
- operation is atomic from the database perspective.

Deleting the Auth user removes refresh/session authority, but existing stateless access tokens can remain cryptographically valid until expiry. Sensitive customer RPCs must continue to require trusted profile/member state so a deleted identity cannot regain personalized access with a stale token.

### 3. Customer privacy and notification preferences

Add a customer-owned preference record with an explicit server contract.

Initial fields:

```text
marketing_notifications_enabled boolean default false
transactional_notifications_enabled boolean default true
updated_at timestamptz
```

Marketing must be opt-in, not inferred from account creation. No notification provider is introduced in Phase 3; this phase establishes authoritative preference state only.

### 4. Customer app production flow

Promote the existing gated deletion flow only after backend authority and regression tests pass.

Required behavior:

- Delete Account remains easy to find in Settings;
- confirmation clearly states account/profile deletion and anonymized transaction retention;
- backend deletion must succeed before local state reports success;
- local cached member data is removed;
- customer returns to unauthenticated state;
- no disabled feature flag may hide the production deletion path at Phase 3 closeout.

Add privacy preferences and legal/support surfaces to Settings with real destinations/content rather than `Coming soon` placeholders.

### 5. Guest/public versus authenticated boundary

Document and test the intended split:

Public/guest-capable where practical:

- catalogue browsing;
- public store/branch information when available;
- privacy policy, terms and support information.

Authenticated-only:

- membership identity/QR;
- profile editing;
- order placement/history;
- student verification;
- preferences tied to an account;
- account deletion.

Do not auto-create anonymous Supabase users merely to represent guests.

### 6. iOS permission/data minimization audit

Review iOS project configuration and dependencies for camera, location, contacts, photos, microphone, tracking and notification permissions.

Phase 3 must not add a protected-data permission unless a shipping feature strictly requires it and the purpose/consent/App Privacy impact is documented.

## Security rules

- Supabase/server remains authority for identity and deletion state;
- never trust `raw_user_meta_data`/`user_metadata` for authorization;
- no service-role/secret key in Flutter or Dashboard browser code;
- no browser-readable employee bearer token;
- account deletion cannot accept a target user ID from the client;
- retained financial records must be anonymized, not silently deleted if they are part of the documented retention set;
- personalized RPCs must fail after profile/member deletion even if an old access token has not yet expired;
- preference reads/writes are owner-scoped under RLS/RPC validation.

## Validation plan

Database regression must prove at minimum:

- `anon` cannot invoke account deletion or preference mutation;
- customer A cannot delete customer B;
- customer with no orders can delete successfully;
- customer with historical/current orders can delete successfully;
- profile/member/student/preference rows are removed;
- retained customer orders are anonymized with no customer/member/creator ID;
- commercial/order/branch/terminal/shift/payment facts remain unchanged;
- POS/staff actor retention is not weakened by customer-deletion logic;
- ordinary clients cannot force anonymization or set `customer_deleted_at`;
- stale deleted-user identity cannot read personalized member/order data;
- preference defaults and owner-only mutation are enforced.

Customer release validation must include:

- deletion repository/provider behavior;
- confirmation UI success/failure handling;
- local cache cleanup;
- preference UI/client behavior;
- privacy/terms/support accessibility;
- static analysis, tests and release build.

Supabase security/performance advisors must be reviewed after schema changes. Any Phase 3-created finding is a completion blocker.

## App Store impact

Apple requires apps that support account creation to let users initiate whole-account deletion in the app; temporary deactivation alone is insufficient. Retained data must be limited to legitimate retention requirements and the user must be told what remains.

Phase 3 therefore closes the currently known account-deletion blocker. It adds no StoreKit/IAP requirement because AIDA sells physical café goods.

## Deferred / non-goals

- external payment processor/card/e-wallet settlement;
- refunds/partial refunds;
- inventory/recipes/depletion;
- branch hours/closures/capacity;
- loyalty/reward authority;
- promotions/discounts;
- tax/accounting export beyond preserving transaction records;
- employee Auth-user lifecycle;
- printer/KDS/payment-device integrations;
- marketing campaign delivery provider;
- deployment-heavy production infrastructure changes unrelated to Phase 3.

## Completion gate

Phase 3 may be marked `COMPLETE` only after backend/client implementation, clean-database regressions, customer release validation, Supabase advisor review, iOS permission audit, App Store impact review and synchronized closeout/handoff documentation in both repositories.

After that, stop implementation. Prepare the combined Phase 1–3 Astra audit boundary; do not begin Phase 4.
