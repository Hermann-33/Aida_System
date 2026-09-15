# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and backend behavior exposed by it.  
**Reviewed:** 2026-09-15  
**Current implementation verdict:** Phases 1–6 `COMPLETE`; final App Store release gate remains later work.

Official Apple guidance must be re-checked before submission.

## Standing rules

AIDA sells physical café food/drink, so StoreKit/In-App Purchase is not the payment path. Customer account creation requires an easy-to-find production whole-account deletion path. Public catalogue and Privacy/Terms/Support information should not require unnecessary authentication.

## Phase 3 privacy boundary

Whole-account deletion is caller-bound to `auth.uid()`, accepts no target user ID, removes customer-owned identity/state and anonymizes legitimately retained commercial history. Retained customer-authored free text and the original customer request digest are scrubbed. Marketing preference defaults off.

## Phase 4–5 impact

Branch pickup scheduling and inventory/recipes add operational/commercial authority only. They introduce no tracking SDK, protected-device permission, StoreKit path, processor or new customer identity category.

## Phase 6 — loyalty, rewards and vouchers

**Verdict:** `COMPLETE`

Loyalty/rewards/vouchers apply to physical café purchases. Phase 6 adds no StoreKit/IAP, subscription, digital-content entitlement, tracking/advertising SDK, protected-device permission or external payment processor.

Customer-owned loyalty accounts, point/stamp ledgers and vouchers are included in whole-account deletion. Retained accepted-order voucher/award facts keep only legitimate non-identifying commercial snapshots after identifying loyalty references are detached.

The customer app can browse public catalogue/legal/support surfaces without creating an anonymous Supabase Auth user. Personalized membership, wallet, order and deletion surfaces require authentication.

## iOS permission/data audit

`docs/context/PHASE_3_IOS_DATA_PERMISSION_AUDIT.md` remains the current complete protected-permission audit. Phases 4–6 did not add a capability that reopens it. `qr_flutter` renders a membership QR and does not justify camera permission.

## Remaining final release gate

Before App Store submission the release candidate still requires operational public Privacy/Support URLs, final App Privacy/privacy-manifest reconciliation, physical verification of whole-account deletion against production release infrastructure, review credentials/demo path, and screenshots/metadata matching the submitted binary. Reopen the permission audit if a later phase adds notifications, camera, location, tracking or another protected capability.

## Governance

Phase completion is not an App Store submission verdict and does not authorize automatic PR merge.