# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and backend behavior exposed by it.  
**Reviewed:** 2026-09-16  
**Current implementation verdict:** Phases 1–8 engineering `COMPLETE`; Phase 9 is next; the final App Store release gate remains Phase 10.

Official Apple guidance must be re-checked during Phase 10 before submission-related changes.

## Standing rules

AIDA sells physical café food/drink. These purchases must not be implemented as digital-content StoreKit/IAP entitlements. The payment architecture must remain a physical-goods payment flow using permitted traditional payment rails/Apple Pay-compatible processor flows when Phase 9 processor activation occurs.

Customer account creation requires an easy-to-find production whole-account deletion path. Public catalogue and Privacy/Terms/Support information should not require unnecessary authentication. Promotions and advertised prices must accurately reflect the server-authoritative commercial result.

## Privacy boundary

Whole-account deletion is caller-bound to `auth.uid()`, accepts no target user ID, removes customer-owned identity/state and anonymizes legitimately retained commercial history. Retained customer-authored free text and the original customer request digest are scrubbed. Marketing preference defaults off.

## Phase 4–8 impact

Scheduling, inventory, loyalty/vouchers, promotions and reporting add operational/commercial authority only. They introduce no StoreKit digital entitlement. Phase 8 is read-only reporting and adds no customer permission or mutation surface.

Phase 8 reporting deliberately labels commercial value as accepted order value rather than processor settlement. This prevents the UI from claiming payment facts that do not yet exist.

## Phase 9 guardrails

Payment/refund implementation must:

- keep the server authoritative for payment/refund lifecycle state;
- never accept client-authored paid/captured/settled/refunded truth;
- distinguish authorization, capture, settlement/reconciliation and refund states;
- preserve current cash/unpaid semantics;
- keep physical-goods payment outside IAP;
- avoid embedding provider secrets in Flutter/browser code;
- document any new SDK, permission, tracking/data collection or external disclosure.

Processor-specific production activation requires explicit owner approval for provider choice, merchant setup, credentials/webhook secrets and any cost-bearing service.

## Remaining Phase 10 release gate

Before App Store submission, Phase 10 must re-check current official Apple requirements and verify at minimum:

- release/static/test/golden build gates;
- current iOS SDK/Xcode compatibility;
- permission/SDK inventory and privacy manifests;
- App Privacy answers against actual collected/shared data;
- production whole-account deletion;
- operational Privacy/Support/Terms URLs;
- review credentials/demo path/review notes;
- screenshots/metadata matching the submitted binary;
- production backend configuration and physical-goods payment behavior.

The cumulative independent/Astra/Codex audit is deferred until Phase 10 implementation and normal validation are complete. It is not waived.

Phase completion does not authorize PR merge or App Store submission.
