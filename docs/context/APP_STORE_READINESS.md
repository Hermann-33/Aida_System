# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and backend behavior exposed by it.  
**Reviewed:** 2026-09-12  
**Source of truth:** Apple's current published App Review and account-deletion guidance; re-check before release.

Official references:

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/support/offering-account-deletion-in-your-app/

## Standing rules

AIDA sells physical café food/drink. These are physical goods/services consumed outside the app, so StoreKit/In-App Purchase is not the payment path.

The customer app supports account creation. A production iOS build therefore requires an easy-to-find in-app path to initiate deletion of the whole account and associated personal data except records that must legitimately be retained. Temporary deactivation alone is insufficient.

Public catalogue/branch information should remain usable without unnecessary authentication where practical. Personalized membership/order features may require authentication.

Only collect data required for a defined feature. Do not request location, camera, contacts, photos, tracking or notification permission merely for convenience. Promotional/direct-marketing notifications require explicit customer control and must remain separable from transactional order communication.

Security guardrails:

- publishable/public key only in customer code;
- no service-role/secret credential in the app;
- trusted prices, roles, identifiers and commercial/operational state validated server-side;
- RLS/authorization around personal data;
- QR/member possession is not authentication.

## Phase 1 review — operational topology

**Task:** `TASK-OPS-002`  
**Verdict:** `COMPLETE`

Phase 1 changed Dashboard/POS operational topology only. It added no customer login change, processor, iOS permission, notification behavior, tracking SDK or customer personal-data field.

## Phase 2 review — shift and cash authority

**Task:** `TASK-OPS-003`  
**Verdict:** `COMPLETE`

Phase 2 impact:

```text
account/login:
  No customer account/login contract change.

payments:
  Internal POS tender classification is limited to cash/unpaid.
  No external processor, Apple Pay, StoreKit, subscription or digital purchase was added.

privacy/data collected:
  Shift/operator/cash reconciliation data is staff operational data.
  No new customer personal-data field was introduced.

permissions:
  No iOS protected-data permission was added.

notifications:
  No notification behavior changed.

third-party SDKs:
  None added by Phase 2.

review/demo implications:
  No new customer hardware permission or payment review path.
  Backend availability remains required during future review.

App Store blocker introduced:
  No new blocker introduced by Phase 2.
```

## Mandatory Phase 3 blocker

Before any App Store release candidate, Phase 3 must deliver and validate:

- production whole-account deletion initiated from inside the app;
- explicit personal-data deletion versus legally retained transaction-record policy;
- accessible privacy policy, terms and support/contact surfaces;
- explicit customer consent/preferences and marketing-notification opt-in/out;
- guest/public versus authenticated feature boundary;
- proof that no unnecessary iOS protected-data permission is requested;
- release validation of the complete deletion path.

The preserved/dormant account-deletion draft is not production authority until promoted through Phase 3 with backend authorization, retention semantics and executable regression coverage.

## Release gate

Before submission:

- required backend services must be live and accessible;
- support/privacy URLs must work;
- account deletion must be physically verified end-to-end;
- App Privacy answers and privacy manifest must match actual SDK/data behavior;
- screenshots/metadata must match the submitted build;
- review credentials/demo path must be usable;
- hidden/dormant development functionality must not appear as undocumented production behavior.

After Phase 3 becomes `COMPLETE`, implementation stops for the combined Phase 1–3 Astra audit before Phase 4 begins.
