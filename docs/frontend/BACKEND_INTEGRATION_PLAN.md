# Backend Integration Plan

This is a frontend-needs map, not a schema design. Names in the “likely boundary” column are candidates to validate during Phase 2; they do not assert existing tables or endpoints.

Priority values: **MVP**, **Important after MVP**, **Future**, **Needs confirmation**.

## 1. Auth

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| `features/auth/login_screen.dart`; `main.dart` | Sign-up/sign-in, restore/refresh/revoke session, verified current user | Supabase Auth + session bootstrap service | Rate limit; generic errors; never authorize from client boolean | MVP |
| `features/auth/widgets/forgot_password_sheet.dart` | Send reset email and complete secure redirect flow | Supabase Auth recovery + approved redirect/deep link | Do not disclose account existence; validate redirects | MVP |
| Social icons in `login_screen.dart` | Provider sign-in and account linking | Supabase Auth providers | Explicit provider config, nonce/redirect/platform review | Future |

## 2. Profile and membership

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| `domain/model/member.dart`; profile/edit screens | Create/read/update member profile; distinguish self-editable and controlled fields | Candidate `profiles` + `members`, or an equivalent normalized model | Owner RLS; email/role/verification/member code not freely editable | MVP |
| Student checkbox/status/campus ID | Pending/verified/rejected workflow with audit evidence | Candidate verification records + staff/admin operation | User declaration cannot grant benefits; trusted reviewer role | MVP |
| Profile coming-soon rows | Change password, delete/anonymize account, preferences | Auth account actions + retention workflow | Re-auth for sensitive actions; legal retention and audit policy | Important after MVP |

## 3. QR/member code

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| `membership_card_screen.dart`; client code generation in `login_screen.dart` | Server-issue stable unique member code; owner read; durable offline cache | Member record plus POS lookup operation | QR is an identifier, not authorization; rate-limit lookup; minimize exposed data | MVP |
| “Show to barista” copy | POS scan/key entry and human/member verification | Staff/POS member lookup | Staff role required; record sensitive use; prevent customer enumeration | MVP with POS dependency |

## 4. Menu and modifiers

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| `mock_member_repository.dart:263–493`; menu screens | Ordered categories/items, descriptions, integer-sen prices, availability, flags | Candidate `menu_categories`, `menu_items` | Public/customer read of published fields only; admin writes by role | MVP |
| `item_size.dart`; `compatibleAddOnIds` | Product variants/sizes and compatible modifier groups/options | Candidate variant/modifier tables | Validate allowed combinations on quote; do not trust client IDs/prices | MVP |
| Test-only rating/volume | Decide real serving metadata/review scope | Catalogue fields or separate reviews | No fabricated ratings; review ownership/moderation if implemented | Needs confirmation |

## 5. Cart and server-side quote

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| `domain/model/cart.dart`; `item_detail_screen.dart`; `cart_screen.dart` | Accept item/variant/modifier IDs and quantities; return authoritative line totals, discounts, fees/tax, availability, expiry | Controlled quote operation/RPC/API; optional quote record | Ignore client prices/totals; validate every configuration and campaign | MVP |
| Special-instruction note | Validate length/content and carry safe kitchen text | Quote/order line input | Size limits, escaping, staff-safe rendering, abuse filtering | MVP |
| Scheduled order product direction; no current screen | Validate pickup slot/cutoff/capacity and payment timing | Candidate slots/service-hours + quote rule | Server time and capacity authority | Needs confirmation |

## 6. Orders and status

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| `cart_screen.dart:74–113`; confirmation screen | Idempotently create order from valid quote; issue number/time; persist payment method/pickup mode | Candidate orders/order_lines + controlled create operation | Owner identity from session; prevent duplicate/replayed create; atomic totals | MVP |
| Timer-based tracking; `OrderStatus { ready }` | Real lifecycle and valid staff-driven transitions; customer updates via subscription/polling | Order status/events; Realtime or authorized polling | Customers read own orders; staff transition only allowed orders/states | MVP |
| Session history/receipt screens | Paged owner history and immutable receipt snapshot | Owner-scoped order/detail read | RLS prevents cross-user reads; historical prices remain immutable | MVP |
| Payment enum | Record approved payment outcome/reference without handling raw card data | Order payment record/provider reference | Only trusted POS/provider confirms paid state | Needs confirmation |

## 7. Loyalty, rewards, and vouchers

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| Points/stamps/rewards/vouchers providers | Ledger-derived balances, stamp progress, catalogue, owned entitlements | Candidate loyalty ledger/balance view, rewards, vouchers | Customer read own data; all mutations trusted and audited | MVP |
| Redeem placeholder in `rewards_screen.dart` | Atomic idempotent points-to-voucher redemption | Controlled redemption operation | Lock/check current balance server-side; prevent double-spend/replay | MVP |
| Voucher Apply/counter copy | Staff-authorized atomic voucher consumption linked to order | Controlled consume operation + audit event | QR/voucher possession insufficient; staff role and current validity required | MVP with POS dependency |
| `home_screen.dart` local check-in | Decide whether check-in earns anything; if retained, one eligible claim per period | Candidate engagement event operation | Server clock, uniqueness, anti-automation; no client-awarded points | Needs confirmation |

## 8. Promotions/marketing

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| `Promo`, `Offer`, carousel mock | Published campaigns, date windows, audience/terms, CTA destination | Candidate promotions/offers and eligibility read | Server filters sensitive eligibility; quote revalidates discount | Important after MVP |
| Notification bell | Consent/preferences and message delivery | Notification records/provider integration | Opt-in, minimal data, secure deep links, unsubscribe | Future |
| Invite a friend placeholder | Referral issuance/attribution if approved | Referral program operation | Abuse/fraud limits; no client-issued rewards | Future |

## 9. POS/staff/admin

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| Order tracking comments reference missing staff/kitchen app | Queue, accept/prep/ready/complete/cancel transitions | Separate POS/staff app over order operations | Trusted staff role, location scope, transition validation/audit | MVP for real ordering |
| QR/voucher copy | Member lookup, verification, reward use at checkout | Staff member/voucher operations | Least privilege, rate limits, audit, no broad member export | MVP for membership/loyalty |
| Mock catalogue/verification | Catalogue availability, pricing, campaign, student verification administration | Separate admin app/services | Admin role stored on trusted boundary; high-risk action confirmation/audit | Important after MVP |

No POS/staff/admin frontend exists in this repository. Its application and repository ownership need confirmation.

## 10. Storage/images

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| Temporary Unsplash URLs; local category art | Managed product/promo images and public transformations/cache | Supabase Storage public/published bucket or signed delivery | Admin-only upload/update; content type/size validation; safe filenames | Important after MVP |
| Profile camera placeholder | Optional member avatar upload and deletion | Private/owner-scoped avatar bucket | Owner object path + RLS/storage policies; validate and strip metadata | Future |
| Placeholder AIDA logo | Approved bundled brand asset | App assets, not necessarily backend | Review provenance/licensing | MVP release prep |

## 11. Reporting/admin

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| PRD reporting/admin scope; no current code | Sales/order/member/loyalty operational aggregates and export | Private reporting schema/views/functions/admin service | Admin-only; security-invoker or protected private objects; audit exports | Important after MVP |
| Profile “My stats” placeholder | Define customer-visible personal metrics or remove entry | Owner-scoped aggregate | Prevent inference of other users/business-sensitive data | Needs confirmation |

## 12. Error handling

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| `core/error/failures.dart`; provider `_unwrap` | Stable error mapping for validation, auth, network, conflict, insufficient points, expired voucher, unavailable item | Adapter error translator + controlled operation error codes | Do not leak SQL/internal/auth existence details | MVP |
| Generic/empty screen error states | Correlation IDs, retryability, refreshed authoritative values | API metadata/logging | Logs exclude secrets/PII; client gets safe messages | MVP |
| Duplicate button risks | Idempotency contract for sign-up provisioning, redeem, voucher use, and order create | Idempotency key/store per operation | Bind key to user/operation/payload and retain long enough | MVP |

## 13. Caching/offline behavior

| Frontend evidence | Required backend behavior | Likely boundary | Security rule | Priority |
|---|---|---|---|---|
| QR offline comments but no storage | Persist minimum immutable member-code/card data and render without network | Local secure/durable store plus member bootstrap | Per-user isolation; explicit logout policy; no service secrets | MVP |
| Menu client filtering and image fallback | Cache published catalogue/images with version/staleness | Local cache + server `updated_at`/version | Revalidate quote/order; cached data never authorizes price | Important after MVP |
| `Points.asOf` and design spec cache intent | Cache points/vouchers/history with timestamp and stale indication | Local per-user cache | Never allow stale balance to authorize redemption; wipe/isolate on user change | Important after MVP |
| Realtime order status | Resume after disconnect and fall back to authorized refresh | Realtime channel + polling/read endpoint | Subscribe only to owner/staff-authorized rows | MVP |

## Integration sequencing

Follow `docs/context/ROADMAP.md`: verify foundation/RLS first, then auth/profile/member code, catalogue, server quote/orders, loyalty, operational apps, and hardening. Avoid a single “replace mock repository” change that introduces all trust boundaries at once.
