# UI Screen Map

Statuses describe current runtime behavior, not design intent.

| Surface | File path | Purpose / role | Navigation entry | Current data source | Backend/Supabase requirement | Status |
|---|---|---|---|---|---|---|
| Auth gate | `apps/customer/lib/main.dart` | Customer startup selection | App root | `authStateProvider` boolean | Session bootstrap, refresh/revocation, verified current user | Mock |
| Sign in / sign up | `apps/customer/lib/features/auth/login_screen.dart` | Customer credentials and registration UI | Auth gate; internal tabs | Mock repository; text controllers; client-generated sign-up member | Supabase Auth, profile/member creation, validation, rate limits, enumeration protection | Implemented UI / mock |
| Sign-up wrapper | `apps/customer/lib/features/auth/signup_screen.dart` | Opens unified auth on Sign Up tab | Only if directly pushed by future caller | Delegates to `LoginScreen(initialSignUp: true)` | Same as unified auth | Implemented wrapper / not used by current root |
| Forgot password sheet | `apps/customer/lib/features/auth/widgets/forgot_password_sheet.dart` | Request reset email | “Forgot password?” in Sign In | Mock delay and success state | Auth reset email, approved redirect/deep link, generic response | Implemented UI / mock |
| App shell | `apps/customer/lib/features/shell/app_shell.dart` | Five-tab customer frame and floating cart access | After local auth boolean | `selectedTabProvider`, `cartProvider` | No direct persistence; eventual auth guard and deep-link policy | Implemented UI / local |
| Home | `apps/customer/lib/features/home/home_screen.dart` | Greeting, points/stamps, check-in, quick actions, promos, categories, popular menu | Home tab | Mock async providers; widget-local check-in | Member/loyalty/menu/promo reads, check-in decision if retained, notifications, order history | Implemented UI / mock and local |
| Rewards | `apps/customer/lib/features/rewards/rewards_screen.dart` | Balance, voucher wallet, reward catalogue | Rewards tab; Home Redeem | Mock points/rewards/vouchers | Server ledger/balance, catalogue, atomic idempotent redemption, voucher lifecycle | Implemented UI / mock; redemption placeholder |
| Reward details sheet | `apps/customer/lib/features/rewards/rewards_screen.dart` | Explain voucher/reward | Details button | Current mock model strings | Authoritative terms/expiry/eligibility; voucher status | Implemented modal / mock |
| Membership QR | `apps/customer/lib/features/card/membership_card_screen.dart` | Show member identity code/points | Center QR tab; Home Scan | Mock/session `Member`; mock points | Server-issued immutable code, durable offline cache, POS lookup/verification | Implemented UI / mock; offline persistence missing |
| Menu | `apps/customer/lib/features/menu/menu_screen.dart` | Browse/filter categories, availability, favorites | Menu tab; Home categories/View All/Favorites | Mock categories/menu; local favorite set/filter | Catalogue/availability/images; cache and invalidation; optional persisted favorites | Implemented UI / mock and local |
| Item detail | `apps/customer/lib/features/menu/item_detail_screen.dart` | Product detail, size/add-ons/note/quantity, favorite, add to cart | Home popular card or Menu item | Mock `MenuItem`; widget state; local cart/favorites | Valid variants/modifiers/prices/availability; server quote later | Implemented UI / mock and local |
| Cart | `apps/customer/lib/features/cart/cart_screen.dart` | Edit lines, calculate subtotal, begin checkout | Floating cart bar | `cartProvider`; mock menu; client arithmetic | Server quote, availability, fees/taxes/discounts, scheduling/pickup rules | Implemented UI / local |
| Payment method sheet | `apps/customer/lib/features/cart/cart_screen.dart` | Select Cash/Card/E-wallet/Student Wallet and “Pay” | Cart checkout | Widget-local enum; no processor | Approved payment/POS model, server order creation, provider integration if any | Implemented UI / mock |
| Order confirmation/tracking | `apps/customer/lib/features/cart/order_confirmation_screen.dart` | Show order number and timed stages | Local place-order action | Client random number; two-second timer | Persisted order, server number/status, staff updates/realtime/polling | Implemented UI / simulated |
| Order history | `apps/customer/lib/features/history/order_history_screen.dart` | List orders placed in this session | Profile “My Orders”; Home Orders | `orderHistoryProvider` in memory | Owner-scoped paged order history | Implemented UI / session-local |
| Order receipt | `apps/customer/lib/features/history/order_detail_screen.dart` | Display session order status/lines/subtotal/payment label | Tap a history card | `PastOrder` and mock menu | Immutable server receipt snapshot and authorized detail read | Implemented UI / session-local |
| Profile | `apps/customer/lib/features/profile/profile_screen.dart` | Show member and account action menu | Profile tab | Mock/session member; local logout | Profile/session reads, orders, settings/help policies, secure logout | Implemented UI / partly placeholder |
| Edit profile | `apps/customer/lib/features/profile/edit_profile_screen.dart` | Edit name/phone/birthday/campus ID | Profile header/row | `memberEditsProvider` overlay | Validated owner-scoped update; verification workflow for campus ID | Implemented UI / session-local |

## Visible placeholders without screens

| Entry | Evidence | Current result | Needed decision/integration |
|---|---|---|---|
| Social sign-in: Google/Facebook/X | `login_screen.dart` | “coming soon” snack | Providers, redirects, linking, platform config |
| Promo CTA / offer detail | `home_screen.dart`, `promo_carousel.dart` | Carousel is given no `onTap`; tap produces no navigation | Offer detail surface and eligibility/terms |
| Notifications | `home_screen.dart` | “No notifications yet” snack | Notification model/service/provider consent |
| Reward “Redeem” | `rewards_screen.dart` | Message; balance unchanged | Atomic redemption and confirmation |
| Voucher “Apply” | `rewards_screen.dart` | Instructs customer to show staff | POS verification and consume operation |
| Change photo | `profile_screen.dart` | Coming-soon snack | Storage/image moderation/update |
| My stats | `profile_screen.dart` | Coming-soon snack; no fake statistics | Define customer-facing metrics or remove |
| Settings | `profile_screen.dart` | Coming-soon snack | Settings scope; includes planned password/delete needs |
| Invite a friend | `profile_screen.dart` | Coming-soon snack | Referral decision |
| Help | `profile_screen.dart` | Coming-soon snack | Support/content channel |

## Planned or referenced but absent

No screen file currently implements splash/session bootstrap, student-verification pending, scheduled ordering/slot selection, dedicated offer detail, redeem confirmation, separate stamp detail, points ledger, change password, delete account, or a real settings page. POS/staff/admin screens are absent from the repository.
