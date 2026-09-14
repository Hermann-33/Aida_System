# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and backend behavior exposed by it.  
**Reviewed:** 2026-09-15  
**Current implementation verdict:** Phases 1–5 `COMPLETE`; Phase 6 is next; final App Store release gate remains later work.

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

Delivered production whole-account deletion, caller-bound deletion authority, customer identity deletion/anonymized legitimate transaction retention, retained free-text scrubbing, privacy/notification preferences with marketing default-off, public Privacy/Terms/Support surfaces, and the iOS data/permission audit.

Detailed closeout: `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_CLOSEOUT_2026-09-12.md`.

## Phase 4 — branch scheduling and pickup authority

**Verdict:** `COMPLETE`

Phase 4 adds branch selection and pickup scheduling for physical café orders only. It adds no new customer identity category, tracking, advertising SDK, device permission, StoreKit/IAP or external payment processor. Detailed closeout: `docs/context/PHASE_4_BRANCH_SCHEDULING_PICKUP_CLOSEOUT_2026-09-15.md`.

## Phase 5 — inventory and recipes

**Verdict:** `COMPLETE`

Inventory items, branch stock balances, recipes, stock movements and depletion are operational business data. The customer app sends existing catalogue/quantity intent; it does not collect a new customer personal-data category or expose inventory administration.

Phase 5 introduces no tracking/advertising SDK, protected-device permission, push-notification request, StoreKit/IAP path, external payment processor or new customer identity field. Inventory sufficiency can reject a physical-goods order at quote/placement; that is commercial availability authority, not a new privacy permission or digital-goods purchase mechanism. Existing Phase 3 whole-account deletion remains unchanged because inventory/recipe records are not customer-owned personal data.

Validation: Backend database audit #138 `COMPLETE`; Customer release audit #229 `COMPLETE`; Dashboard CI #99 `COMPLETE`; Supabase security/performance advisor boundary `COMPLETE`.

Detailed closeout: `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`.

## iOS permission/data audit

`docs/context/PHASE_3_IOS_DATA_PERMISSION_AUDIT.md` remains the current complete permission audit. Phases 4–5 add no protected iOS permission or tracking capability that would reopen it. `qr_flutter` renders the membership QR and does not justify a camera purpose string.

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
- trusted roles, prices, identifiers, branch/scheduling/inventory/commercial/payment/privacy state validated server-side;
- customer self-deletion is caller-bound and cannot target another user;
- RLS/RPC authorization around personal data and privileged operational data;
- preview fixtures are never production authority;
- QR/member possession is not authentication.

## Remaining final release gate

Implementation phase completion is not an App Store submission verdict. Before submission, the release candidate still requires:

- operational public Privacy Policy and Support URLs matching the in-app disclosures;
- App Privacy answers and privacy manifests reconciled against the complete release build and all linked SDK manifests;
- physically verified whole-account deletion against production release infrastructure;
- usable review credentials/demo path;
- screenshots/metadata matching the submitted binary;
- reopening the permission audit if a later phase adds notifications, camera scanning, location, tracking or another protected capability.

## Governance

The independent Phase 1–3 Codex audit may run in parallel with Phase 4–7 implementation under `docs/decisions/ADR-0013-parallel-audit-and-phase-4-7-implementation.md`. A valid blocking audit finding reopens the affected earlier phase. Completed phase PRs remain draft/unmerged unless explicitly authorized.
