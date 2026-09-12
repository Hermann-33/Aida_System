# Phase 3 — Customer Privacy and App Store Account Requirements Plan

**Task:** `TASK-PRIVACY-001`  
**Status:** `COMPLETE`  
**Branch:** `codex/phase-3-customer-privacy-account-requirements`  
**Closeout:** `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_CLOSEOUT_2026-09-12.md`  
**Audit policy:** implementation stops after Phase 3. The next boundary is the combined Phase 1–3 Astra audit; Phase 4 must not begin before that audit is resolved or explicitly accepted.

## Objective

Close the customer privacy/account boundary required before an App Store release candidate without weakening trusted commercial and operational history established in Phases 1–2.

Completed scope:

- production self-service whole-account deletion initiated inside the customer app;
- explicit deletion/anonymization versus retained transaction-data rules;
- deletion of customer profile/member/student/preference identity state;
- scrubbing of customer-authored retained order free text;
- customer privacy/notification preferences with marketing default-off;
- accessible privacy policy, terms and support/contact surfaces;
- explicit guest/public versus authenticated feature boundaries;
- iOS permission/data-minimization audit;
- executable authorization/deletion/retention regressions and customer release validation.

## Dependency rationale

Account deletion depends on authoritative historical orders. Retained café transaction/audit facts must survive whole-account deletion while losing stable customer/member/Auth identifiers. Phases 1–2 therefore had to establish trusted branch/terminal/shift/payment attribution before this retention boundary could be implemented safely.

External payment processors, refunds, inventory, branch scheduling and deployment-heavy integrations remain downstream and were not pulled into this phase.

## Retention contract

Deleted with the account:

- Supabase Auth identity and session authority;
- `user_profiles` customer PII;
- `members` customer/member identity;
- student-verification identity data;
- privacy/notification preference row;
- active offline membership cache;
- future personal profile fields explicitly classified as deletable.

Retained only as anonymized transaction/audit history:

- order number and immutable product/option snapshots;
- quantities/prices/totals/currency/pricing version;
- fulfilment/status timestamps;
- branch/sales-point/terminal/shift attribution;
- tender/payment-state facts;
- operational events after customer actor/free-text removal.

Not retained:

- customer/member/Auth IDs on retained customer orders;
- customer-authored `order_lines.note`;
- customer-authored/history `order_events.reason`;
- synthetic permanent deleted-customer Auth placeholder;
- customer email, phone, member code or student campus ID in retained transaction rows.

## Backend design delivered

`orders` now supports an explicit retained-anonymized state with `customer_deleted_at`. The order immutability trigger permits only the trusted one-way active-customer -> anonymized-retained identity transition; POS/staff actor retention and Phase 1–2 commercial/topology/shift/payment immutability remain intact.

`delete_own_account()` accepts no target user ID. The public wrapper is `SECURITY INVOKER`; a private caller-bound helper performs privileged anonymization and Auth deletion. Staff/Admin identities cannot use customer self-deletion. A trusted disabled customer can still delete their account, and deletion does not depend on a healthy active member row.

`customer_privacy_preferences` is FORCE-RLS protected with direct browser table grants revoked. Marketing defaults off; transactional notifications default on. No notification provider is introduced.

## Customer app delivered

Settings exposes production account deletion, privacy preferences, Privacy Policy, Terms and Support. Deletion reports success only after the server operation succeeds, then clears customer identity state and offline membership cache best-effort. The former account-deletion feature flag is no longer present.

Public/guest-capable: catalogue and legal/support information. Authenticated-only: membership/QR, profile mutation, order placement/history, student verification, account preferences and deletion. No anonymous Supabase user is created merely to represent a guest.

## iOS/App Store impact

The Phase 3 iOS permission audit is `COMPLETE`. No camera, photos, location, contacts, microphone, tracking/ATT or notification authorization is introduced. No tracking SDK or StoreKit/IAP path is added; AIDA sells physical café goods.

The known in-app whole-account deletion blocker is closed at this code/backend boundary. Final release submission still requires operational policy/support URLs, accurate App Privacy/manifests, review credentials and physical end-to-end release verification.

## Validation

Implementation head `10ca26a776994e59b76f8afbd7227e296270cd68`:

```text
Backend database audit #90   COMPLETE
Customer release audit #182 COMPLETE
```

Dashboard Phase 3 runtime is unchanged; pre-closeout Dashboard head `411056a40edfb1c23fa999504b904d822e151f5d` passed Dashboard CI #66. Final documentation-only heads are revalidated separately.

Supabase advisors show no Phase 3-created security blocker. The only security warning remains the pre-existing leaked-password-protection setting; performance findings are INFO-level unused indexes.

## Deferred / non-goals

- external payment capture/refunds/processor settlement;
- inventory/recipes/depletion;
- branch hours/closures/capacity;
- loyalty/rewards/vouchers;
- promotions/discounts;
- tax/accounting export;
- employee Auth-user lifecycle;
- printer/KDS/payment-device integrations;
- notification/marketing delivery provider;
- deployment-heavy production infrastructure.

## Completion gate

Phase 3 is `COMPLETE`. Implementation is stopped. The prepared next boundary is `docs/context/PHASE_1_3_ASTRA_AUDIT_BOUNDARY_2026-09-12.md`, currently `PARTIAL` until Astra review is executed/accepted.