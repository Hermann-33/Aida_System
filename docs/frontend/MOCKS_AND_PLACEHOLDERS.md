# Mocks and Placeholders Register

Everything below must be treated as non-production unless a later integration task proves otherwise.

## Mock repository

`apps/customer/lib/data/repository/mock_member_repository.dart` is the only `MemberRepository` implementation and is bound in `lib/application/providers.dart`. It provides synthetic 400 ms latency and successful results only.

## Hardcoded user and auth behavior

| Item | Evidence | Risk / required move |
|---|---|---|
| Demo member `m_001`, Aida Rahman, email, phone, birthday, student ID, verified status, Gold tier | `mock_member_repository.dart:29–39` | Replace with authenticated owner-scoped profile/member reads; remove personal-looking demo data from production seeds |
| Any sign-in succeeds | `mock_member_repository.dart:41–51`, `login_screen.dart:83–103` | Supabase Auth; rate limiting, validation, session handling |
| Sign-in form deliberately skips validation | `login_screen.dart:83–86` | Reinstate client UX validation while treating server as authority |
| Sign-up always succeeds | `mock_member_repository.dart:53–62` | Auth sign-up plus atomic profile/member provisioning |
| Client-generated member ID and `AIDA-####-####` code | `login_screen.dart:134–149` | Server/database-generated stable identifiers; collision/abuse controls |
| Password reset always shows sent | `mock_member_repository.dart:64–70`, `forgot_password_sheet.dart` | Real reset email/redirect with generic anti-enumeration response |
| Social sign-in icons | `login_screen.dart:351–361` | Coming-soon snacks; providers not configured |

No reusable password is hardcoded in inspected source.

## Hardcoded menu/products

- Four categories: Coffee, Iced Drinks, Food, Add-ons.
- Thirteen catalogue records including three add-ons.
- Plausible but unapproved prices in integer sen.
- Placeholder size scheme: Small −RM1.00, Medium base, Large +RM1.50.
- Placeholder add-on compatibility for drinks.
- Product availability including a deliberately sold-out croissant.
- Test-only ratings and serving volumes.
- Best-seller, student eligibility, and bonus-point flags.
- Temporary hotlinked Unsplash images; `_stockChocolate` is unused.

Evidence: `mock_member_repository.dart:188–493`, `domain/model/item_size.dart`, `domain/model/menu_item.dart`.

All catalogue rules and images must move to verified business data/storage. Client cache/filtering may remain, but quote/order must revalidate them.

## Hardcoded loyalty, rewards, and vouchers

| Item | Current value/source | Required authority |
|---|---|---|
| Points | 130 with `DateTime.now()` | Server ledger/balance |
| Stamp card | 7/10, one free drink | Server qualifying-order rules/ledger |
| Reward costs | 100/150/180 | Admin-managed catalogue and server redemption |
| Vouchers | Free drink + RM5 with relative 30/45-day expiry | Issued entitlements with immutable issue/expiry/use records |
| Offers | Student 20% and double-points Tuesday | Eligibility/promotion engine |
| Tier | “Gold Member” cosmetic | Approved tier rules or remove |
| Home daily check-in | Earlier weekdays prefilled; current day locally tappable | Confirm product rule; otherwise remove rather than persist a visual invention |

Evidence: `mock_member_repository.dart:78–180`, `home_screen.dart:657–736`, and loyalty/reward/voucher models.

Reward Redeem and voucher Apply do not change any backend or local balance; they only show messages (`rewards_screen.dart:189–314`).

## Fake order and payment behavior

- Cart lines and favorites exist only in Riverpod memory.
- Subtotal is computed from mock client prices.
- Cash/Card/E-wallet/Student Wallet are local enum values; no funds or POS action occurs.
- Order number is a random six-digit client value.
- Order timestamp and receipt are local.
- Order status advances on a two-second timer and history stores `ready` only.
- History contains only orders placed in the current process; there is no seeded historical API data.

Evidence: `application/providers.dart:184–261`, `features/cart/cart_screen.dart:16–113`, `order_confirmation_screen.dart`, `domain/model/order.dart`, and history screens.

These must move to server quote/order/payment-record/status/history operations. No current UI value is trustworthy as an order record.

## Fake statistics

No statistics dataset or statistics screen was found. Profile exposes “My stats,” but tapping it only shows a coming-soon snack (`profile_screen.dart:179–189`). Do not describe customer statistics as implemented.

## Promotions and placeholder actions

| Surface | Current behavior |
|---|---|
| Promo carousel CTA | Home provides no `onTap`; visually tappable card has no navigation |
| Notifications bell | “No notifications yet” snack |
| Reward Redeem | “next” message; no points change |
| Voucher Apply | Counter instruction; no verification/consumption |
| Change profile photo | Coming-soon snack |
| Settings, Invite, Help, My stats | Coming-soon snacks |
| Signup social providers | Coming-soon snacks |
| Final logo | `AidaLogo` renders a `LOGO` placeholder |
| Web app metadata | Default `aida_customer`/Flutter colors and description |
| Android release signing | Uses debug signing with TODO |

## Local/session-only edits

- Auth boolean.
- Sign-up member overlay.
- Profile name, phone, birthday, campus ID edits.
- Selected tab/category and favorites-only filter.
- Favorite item IDs.
- Cart content.
- Order history.
- Item configuration and payment selection.
- Home daily check-in.

Logout clears auth and member edits only. Cart, favorites, order history, and navigation state are not explicitly cleared, creating a future shared-device isolation risk.

## Frontend-generated values that must move server-side

- member IDs and member codes;
- order numbers and accepted order timestamps;
- authoritative quote/line/subtotal/total;
- order status and receipt facts;
- points/stamp mutations and balances;
- reward/voucher issuance/use/expiry decisions;
- student verification and roles;
- offer eligibility and discount application;
- payment acceptance/recording status.

UI-only timestamps for rendering, correlation IDs for idempotent requests, and local cache metadata may remain client-generated when their contracts explicitly permit it.
