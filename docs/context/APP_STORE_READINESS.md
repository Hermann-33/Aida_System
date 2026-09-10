# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and backend behavior exposed by it.  
**Reviewed:** 2026-09-11 against Apple App Review Guidelines last updated 2026-06-08 and Apple's account-deletion guidance.  
**Source of truth:** Apple's current published guidance; re-check before every release.

Official references:

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/support/offering-account-deletion-in-your-app/

## Standing architecture rules

### Physical goods payments

AIDA sells café food/drink consumed outside the app. These are physical goods/services outside the app and must use non-IAP payment methods. Do not introduce StoreKit/In-App Purchase for café orders.

Future Apple Pay/card/e-wallet work belongs to the physical-goods payment path.

### Account creation and deletion

The customer app supports account creation. Production iOS therefore must provide an easy-to-find in-app path to initiate deletion of the whole account and associated personal data except data legally required to be retained.

Temporary deactivation alone is insufficient. The current preserved account-deletion draft is not a production-compliant feature until promoted through its dedicated phase.

### Login boundary

AIDA currently uses its own email/password account system. If third-party/social primary login is added later, re-review the current Apple login requirements before implementation.

Public catalogue/branch information should remain usable without unnecessary authentication where practical. Personalized member/order features may require authentication.

### Privacy and data minimization

Only collect data required for a defined feature. For every new personal or device-related field/SDK, document purpose, access, retention/deletion, sharing and permission/consent requirements.

Do not request location, camera, contacts, photos, tracking or notification permission merely for convenience. Prefer non-permission alternatives where practical.

### Notifications and marketing

Push notifications must not be required for core functionality. Promotional/direct-marketing notification behavior requires explicit user control and must remain distinguishable from transactional order communication.

### Security

Continue AIDA's standing rules:

- public/publishable key only in the customer app;
- no service-role/secret credential in customer code;
- trusted prices, roles, identifiers and commercial/operational state validated server-side;
- RLS/authorization around personal data;
- QR/member possession is not authentication.

### App completeness/review

Before App Store submission:

- required backend services must be live and accessible;
- review credentials/demo mode and any required sample resource must be provided;
- non-obvious flows should be explained in App Review notes;
- support/privacy URLs must work;
- screenshots/metadata must match the submitted build;
- hidden/dormant development features must not become undocumented accessible production functionality.

## Phase 1 review — operational topology

**Task:** `TASK-OPS-002`  
**Reviewed:** 2026-09-11  
**Result:** no new App Store blocker introduced.

```text
Apple guideline impact:
- account/login:
    No customer account/login behavior changed.

- payments:
    No processor, StoreKit, Apple Pay, card or e-wallet settlement was added.
    Existing pay-at-counter/unpaid semantics remain.

- privacy/data collected:
    Phase 1 adds operational branch, sales-point, terminal, employee branch
    assignment and POS workstation attribution in the backend/Dashboard.
    No new customer personal-data field was introduced.

- permissions:
    No iOS protected-data permission was added.

- notifications:
    No notification behavior changed.

- third-party SDKs:
    None added by Phase 1.

- review/demo implications:
    No new customer-app hardware permission or payment flow.
    Backend must remain available during any future review as already required.

- App Store blocker introduced? no
```

Operational terminal enrolment is a Dashboard/POS concern and does not require customer iOS hardware permission or expose a terminal credential to the customer app.

## Existing release blocker not caused by Phase 1

Production account deletion remains mandatory before an App Store release candidate because the customer app supports account creation. This is assigned to the dedicated customer privacy/App Store phase and remains intentionally separate from Phase 1.

## Future phase review template

At every phase closeout record:

```text
Apple guideline impact:
- account/login:
- payments:
- privacy/data collected:
- permissions:
- notifications:
- third-party SDKs:
- review/demo implications:
- App Store blocker introduced? yes/no
```

A phase-created App Store blocker must have an explicit release-gate resolution before an App Store candidate is declared ready.
