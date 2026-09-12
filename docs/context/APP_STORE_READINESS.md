# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and backend behavior exposed by it.  
**Reviewed:** 2026-09-12  
**Current implementation verdict:** Phase 3 privacy/account boundary `COMPLETE`; final App Store release gate remains later work.

Official references must be re-checked before submission:

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/support/offering-account-deletion-in-your-app/

## Standing rules

AIDA sells physical café food/drink, so StoreKit/In-App Purchase is not the payment path.

Customer account creation requires an easy-to-find in-app whole-account deletion path. Temporary deactivation alone is insufficient. Personal data not legitimately required for retained transaction/audit history must be deleted or anonymized.

Only collect/request protected data required for a defined shipping feature. Public catalogue and legal/support information should not require unnecessary authentication. Personalized membership/order/account features may require authentication.

## Phase 1 — operational topology

**Verdict:** `COMPLETE`

Dashboard/POS topology authority changed only. No customer iOS permission, tracking SDK, customer personal-data field or processor path was added.

## Phase 2 — shift and cash authority

**Verdict:** `COMPLETE`

Shift/operator/cash reconciliation is staff operational data. Phase 2 adds only internal `cash | unpaid` tender/payment classification; no external processor, Apple Pay, StoreKit, subscription or digital purchase. No iOS permission or customer personal-data field was added.

## Phase 3 — customer privacy and account requirements

**Verdict:** `COMPLETE`

The known account-deletion/privacy implementation blocker is closed at the code/backend boundary.

Delivered:

- production whole-account deletion initiated from Settings;
- deletion RPC accepts no target user ID and is caller-bound to `auth.uid()`;
- customer Auth/profile/member/student/preference identity deletion;
- anonymized retention of legitimate transaction/audit facts;
- customer/member/Auth IDs removed from retained customer orders;
- customer-authored retained `order_lines.note` and `order_events.reason` scrubbed;
- POS/staff audit identity preserved;
- privacy/notification preferences with marketing default-off;
- Privacy Policy, Terms and Support surfaces;
- signed-out access to legal/support information;
- explicit public/guest versus authenticated feature split;
- customer release and clean-database deletion/retention regressions.

Implementation evidence:

```text
Aida_System head 10ca26a776994e59b76f8afbd7227e296270cd68
Backend database audit #90   COMPLETE
Customer release audit #182 COMPLETE
```

Detailed closeout: `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_CLOSEOUT_2026-09-12.md`.

## iOS permission/data audit

`docs/context/PHASE_3_IOS_DATA_PERMISSION_AUDIT.md` is `COMPLETE` for the Phase 3 code boundary.

Phase 3 introduces no camera, photo-library, location, contacts, microphone, Bluetooth, calendar/reminder, tracking/ATT or notification authorization request. It adds no advertising/tracking SDK. Privacy preference state is not OS push permission and is not cross-app tracking consent.

`qr_flutter` renders the membership QR and does not justify a camera purpose string.

## Guest/auth boundary

Public/guest-capable:

- catalogue browsing;
- Privacy Policy, Terms and Support information.

Authenticated-only:

- membership identity/QR;
- profile mutation;
- order placement/history;
- student verification;
- account privacy preferences;
- whole-account deletion.

No anonymous Supabase user is created merely to represent a guest.

## Security guardrails

- publishable/public Supabase configuration only in customer code;
- no service-role/secret credential in Flutter/browser code;
- trusted roles, prices, identifiers, commercial/operational/payment/privacy state validated server-side;
- customer self-deletion is caller-bound and cannot target another user;
- RLS/RPC authorization around personal data;
- preview fixtures are never production authority;
- QR/member possession is not authentication.

## Remaining final release gate

Phase 3 completion is not an App Store submission verdict. Before submission, the release candidate still requires:

- operational public Privacy Policy and Support URLs matching the in-app disclosures;
- App Privacy answers and privacy manifests reconciled against the complete release build and all linked SDK manifests;
- physically verified whole-account deletion against production release infrastructure;
- usable review credentials/demo path;
- screenshots/metadata matching the submitted binary;
- reopening the permission audit if a later phase adds notifications, camera scanning, location, tracking or another protected capability.

## Governance

Phases 1–3 are `COMPLETE` but remain draft/unmerged. Implementation stops for `docs/context/PHASE_1_3_ASTRA_AUDIT_BOUNDARY_2026-09-12.md`, whose verdict remains `PARTIAL` until Astra review is executed/accepted. Do not begin Phase 4 before that boundary is resolved.