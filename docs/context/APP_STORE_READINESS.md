# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and any backend behavior exposed by it.  
**Source of truth:** Apple's current App Review Guidelines and linked Apple Developer guidance. Re-check before every release because the guidelines are living documents.

Official references:

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/support/offering-account-deletion-in-your-app/

## Standing architecture rules

### Physical goods payments

AIDA sells coffee/food consumed outside the app. Those purchases must use non-IAP payment methods. Do not add StoreKit/In-App Purchase for café orders.

Future Apple Pay/card/e-wallet integrations belong to the physical-goods payment path.

### Account creation and deletion

The customer app supports account creation, therefore production iOS must offer an easy-to-find in-app account-deletion initiation flow.

Deletion must cover the complete account and associated personal data except data AIDA is legally required to retain. Temporary deactivation alone is not sufficient.

The existing dormant account-deletion draft is not App Store-compliant until it becomes a production, user-accessible path.

### Login boundary

AIDA currently uses its own email/password account system. A separate Apple login option is not required solely because first-party login exists.

If a third-party/social primary login is introduced later, re-review App Review Guideline 4.8 before implementation.

Public catalogue/branch information should remain usable without unnecessary authentication where practical. Account-required features include member identity, loyalty, order ownership/history and other personalized services.

### Privacy and data minimization

Only collect personal data required for a defined feature.

Each new table/field/SDK must document:

- why the data is needed;
- who can access it;
- retention/deletion behavior;
- whether it is shared with a third party;
- consent or system permission requirements.

Do not request location, camera, contacts, photos, tracking or notification access merely for convenience. Provide non-permission alternatives where reasonable.

### Notifications and marketing

Push notifications must not be required for core functionality.

Promotional/direct-marketing notifications require explicit in-app opt-in and an in-app opt-out path.

Transactional order-status notifications must remain distinguishable from marketing preferences.

### Security

Continue the current AIDA rules:

- public/publishable key only in the customer app;
- no service-role/secret credentials in the client;
- trusted prices, roles, identifiers and commercial state validated server-side;
- RLS/authorization around personal data;
- QR/member possession is not authentication.

### App completeness

App Store submissions must not depend on disabled placeholder features, unavailable backends or hidden functionality.

Before submission:

- backend services are live;
- review credentials/sample QR resources are supplied where necessary;
- all URLs work;
- significant functionality is disclosed in Notes for Review;
- screenshots and metadata match the submitted build.

### Hidden/dormant features

Draft database scripts or compile-time-disabled development features must not create undocumented accessible functionality in the submitted app.

Any production feature introduced after review must be documented in the next App Store submission.

## Phase review template

At the close of every implementation phase, record:

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

If a phase introduces an App Store blocker, it cannot be marked COMPLETE without an explicit follow-up task in an earlier release gate.
