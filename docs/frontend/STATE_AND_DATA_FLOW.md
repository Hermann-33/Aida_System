> Scope note: customer Flutter state/data flow. The separate POS/Admin flow is documented under `docs/dashboard/STATE_AND_DATA_FLOW.md`.

# State and Data Flow

All application-wide providers live in `apps/customer/lib/application/providers.dart`.

Key state includes `memberRepositoryProvider` -> `MockMemberRepository`, local boolean auth, selected tab/category, favourites filter/set, member edit overlay, mock async member/menu/loyalty providers, in-memory cart and in-memory order history.

## Repository flow

`MemberRepository` supports mock auth and customer reads for member/points/stamps/rewards/vouchers/offers/menu. It has no real service for profile writes, quote/order, check-in, redemption, voucher consumption, images, notifications or payments.

```text
Mock constants -> domain models -> Result<T> -> Riverpod AsyncValue -> widgets
```

No DTO/serialization/API boundary exists.

## Current auth/session

Mock login succeeds, signup generates member/code locally, logout resets only auth/member edits, process restart loses state. Real direction is Supabase Auth session lifecycle, trusted member bootstrap and per-user cache isolation.

## Menu/cart/order

Mock catalogue is filtered locally. Item detail constructs local cart lines. Client calculates price, chooses local payment method, generates order number, stores history and advances confirmation on timer. Real flow must use shared catalogue IDs, trusted quote/order creation and staff-driven status from the same backend used by POS.

## Loyalty/profile/QR

Balances and rewards are mock reads; redeem/apply are placeholders. Profile edits are overlays. QR encodes member code with no durable cache. Real paths use owner-scoped profile/member reads, server-issued code, ledger/redemption operations and authorized dashboard/POS lookup.

## Error flow

Typed failure classes exist but mock adapter rarely exercises them. Real adapters must cover auth/network/validation/conflict/insufficient-balance/expired-voucher/unavailable-item failures and retry/logout/cache behavior.