# Customer Backend Integration Plan

Updated: 2026-09-15

This document records the **current production integration through Phase 7** and the remaining later-phase customer work. Older August planning notes are superseded where they conflict with this state.

## Production repository wiring

Flutter production providers use:

- `SupabaseMemberRepository` for authenticated member/profile/privacy/account capabilities;
- `SupabaseCatalogueRepository` for shared catalogue;
- `SupabaseLoyaltyRepository` for points, stamps, rewards and vouchers;
- `SupabaseOrderRepository` for quote/place/order history and updates.

Production does not fall back to legacy mock repositories when Supabase authority is unavailable.

## Integrated backend capabilities

### Identity / membership

Supabase Auth plus server-owned member/profile state. Session changes invalidate personalized providers.

### Privacy / account requirements

Caller-bound privacy preferences, password-reset support and live whole-account deletion are integrated. The Settings screen exposes Delete Account directly; deletion is not hidden behind a feature flag.

### Catalogue

Live public shared catalogue, categories, featured/popular items, variants/options/add-ons and Realtime invalidation/refetch behavior.

### Scheduling

Order quote/place integrates branch pickup policy, windows/exceptions, lead/horizon/slot capacity and server-derived preparation time.

### Inventory / recipes

Quote is inventory-aware and placement performs authoritative transactional recipe depletion. The customer has no stock mutation authority.

### Loyalty / rewards / vouchers

Live points/stamps, reward catalogue and vouchers are caller-bound through `SupabaseLoyaltyRepository`. Voucher use is optional order intent; server quote/place validates and consumes it.

### Phase 7 promotions

Generalized promotions are automatic server authority. The client does not select accepted promotions. Strict order contracts consume `voucherDiscountSen`, `promotionDiscountSen`, total `discountSen` and promotion snapshots and reject inconsistent payloads.

Placement re-evaluates promotions, so the app must treat the placement response—not a prior quote—as the final commercial fact.

## Client integration invariants

- money is integer sen;
- accepted prices/discounts/totals are server snapshots;
- branch scheduling/capacity and inventory result are server-owned;
- vouchers/promotions are not locally consumed;
- `clientRequestId` supports idempotent placement but cannot alter an already accepted payload;
- Realtime causes trusted refetch rather than trusting arbitrary change payloads;
- account deletion is caller-bound and cannot name another user;
- public browsing does not require unnecessary anonymous Auth identity creation.

## Validation through Phase 7

```text
Aida_System implementation   c6abf24b498edb401af878f86d26e1c63a633121
Customer release audit #311  COMPLETE
```

Release audit covers static analysis, non-golden tests, golden regressions, release APK build and artifact upload. Phase 7 contract tests cover promotion-only, voucher+promotion and malformed/reconciliation cases.

The shared backend database audit #231 and Dashboard CI #147 also passed the same Phase 7 implementation boundary. Live AIDA Supabase has the Phase 7 migrations deployed and no new blocking advisor finding.

## Remaining integration work

### Phase 8

Reporting/accounting/audit is primarily backend/Dashboard work. Do not introduce customer-visible financial authority merely because reports exist.

### Phase 9

External payment/refund integration may add customer payment UX only after provider, merchant, credential and cost requirements are approved. Distinguish payment intent, authorization, capture, settlement and refund states; never optimistically label an order paid from client state alone.

### Phase 10

Final iOS/App Store work includes production legal/support URLs, privacy manifest/label reconciliation, permission/SDK inventory, physical whole-account-deletion verification, review credentials/demo path, screenshots/metadata and release build/submission readiness.

## Separately deferred

Referral remains draft-gated/off by default until a dedicated abuse/privacy/backend design is approved.
