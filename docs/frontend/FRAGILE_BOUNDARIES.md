# Customer Fragile Boundaries

Updated: 2026-09-15

These are the customer-app trust and release boundaries most likely to regress if convenience logic moves authority into Flutter.

## 1. Authentication vs authorization

Supabase Auth identifies the caller. Trusted application role/member state comes from server-owned records. Customer-editable Auth metadata must not become authorization authority.

## 2. Public browsing vs personalized state

Public catalogue/legal/support surfaces should not create unnecessary anonymous Auth users. Personalized membership, loyalty, orders, privacy and deletion require the authenticated customer context.

## 3. Commercial parsing

The app must fail closed on malformed/unknown order status, invalid integer/boolean/date values or inconsistent commercial arithmetic.

Through Phase 7:

```text
sum(lineTotalSen) = subtotalSen
voucherDiscountSen + promotionDiscountSen = discountSen
totalSen = subtotalSen - discountSen
sum(promotion snapshot discounts) = promotionDiscountSen
```

Voucher/promotion snapshots cannot be invented client-side to make arithmetic pass.

## 4. Promotions are server decisions

Home marketing cards or cached promotion presentation are not discount authority. Flutter must not send accepted promotion IDs/amounts, calculate final eligibility, assume a quote reserves usage or preserve a promotion after the placement response removes it.

An exclusive accepted promotion must be the sole accepted promotion. Voucher coexistence is trusted only when the server snapshot marks it allowed.

## 5. Scheduling and inventory

Local clocks, branch presentation data and cached stock cannot decide order acceptance. Pickup capacity/prepare time and inventory outcome are server-owned; placement performs final transactional validation.

## 6. Loyalty and vouchers

Production loyalty uses `SupabaseLoyaltyRepository`, not mock member values. Points/stamps/rewards/vouchers are caller-bound backend state. Voucher use is intent only until placement accepts/consumes it.

## 7. Whole-account deletion

Settings exposes a live Delete Account action. The client calls the caller-bound deletion path; it must never accept a target account ID or perform partial local-only deletion. On success personalized providers are invalidated and the local signed-in state is cleared.

Retained commercial history must remain anonymised according to the backend deletion contract; UI caches must not reconstruct deleted customer identity.

## 8. Realtime

Realtime signals are invalidation/refetch triggers where used. Raw change payloads must not bypass RLS-filtered repository fetches to become trusted catalogue/order/commercial state.

## 9. Payments

Until Phase 9, the app must not claim external authorization/capture/settlement/refund. Current internal tender/payment semantics remain backend-owned.

## 10. Permissions and App Store

Do not add camera/location/notifications/tracking or other protected capability merely for convenience without reopening the permission/privacy audit and updating App Store documentation. Membership QR rendering alone does not justify camera permission.

Referral remains draft-gated and off by default. Final hosted URLs, App Privacy/manifests, review credentials, screenshots/metadata and submission state remain Phase 10.
