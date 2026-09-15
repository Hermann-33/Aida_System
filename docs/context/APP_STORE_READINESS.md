# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and backend behavior exposed by it.  
**Reviewed:** 2026-09-15  
**Current implementation verdict:** Phases 1–7 `COMPLETE`; final App Store release gate remains Phase 10.

Official Apple guidance must be re-checked before submission.

## Standing rules

AIDA sells physical café food/drink. Under App Review Guideline 3.1.3(e), purchases of physical goods/services consumed outside the app must use payment methods other than In-App Purchase. AIDA therefore must not route café food/drink payment through StoreKit/IAP.

Customer account creation requires an easy-to-find production whole-account deletion path. Public catalogue and Privacy/Terms/Support information should not require unnecessary authentication. Promotions and advertised prices must accurately reflect the server-authoritative commercial result shown to the customer.

## Privacy boundary

Whole-account deletion is caller-bound to `auth.uid()`, accepts no target user ID, removes customer-owned identity/state and anonymizes legitimately retained commercial history. Retained customer-authored free text and the original customer request digest are scrubbed. Marketing preference defaults off.

## Phase 4–7 impact

Scheduling, inventory, loyalty/vouchers and generalized promotions add operational/commercial authority only. They introduce no tracking SDK, protected-device permission, StoreKit path or digital-content entitlement.

Phase 7 promotions apply to physical café goods. Promotion eligibility and accepted discount amounts are server-owned; clients cannot author accepted promotion IDs, discounts or totals. Quote/order responses expose separate voucher and promotion discount components and immutable accepted commercial snapshots, supporting accurate price presentation.

The Admin campaign surface is an internal operations tool. Preview mode uses fixtures only and does not contact privileged promotion endpoints.

Live Phase 7 deployment and fresh Supabase advisors completed on 2026-09-15 without introducing a new App Store-specific blocker.

## iOS permission/data audit

`docs/context/PHASE_3_IOS_DATA_PERMISSION_AUDIT.md` remains the current protected-permission audit. Phases 4–7 did not add a capability that reopens it. `qr_flutter` renders a membership QR and does not justify camera permission.

## Remaining final release gate

Before App Store submission the release candidate still requires operational public Privacy/Support URLs, final App Privacy/privacy-manifest reconciliation, physical verification of whole-account deletion against production release infrastructure, review credentials/demo path, and screenshots/metadata matching the submitted binary. Reopen the permission audit if a later phase adds notifications, camera, location, tracking or another protected capability.

External card/e-wallet processor settlement remains Phase 9. When added, it must continue to follow the physical-goods/non-IAP boundary and must not create a misleading in-app price/discount path.

## Governance

Phase completion is not an App Store submission verdict and does not authorize automatic PR merge. Phase 8–10 remain frozen pending explicit owner authorization.
