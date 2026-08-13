> Scope note: this map always describes the customer Flutter repository, even when read from the mirrored dashboard copy.

# UI Screen Map

Statuses describe current customer runtime behavior, not design intent.

| Surface | File path | Purpose / role | Current data source | Status |
|---|---|---|---|---|
| Auth gate | `apps/customer/lib/main.dart` | customer startup selection | restored Supabase session + Auth state stream | Integrated; physical signup/session bootstrap validated |
| Sign in / sign up | `features/auth/login_screen.dart` | credentials/registration UI | Supabase Auth + server-provisioned profile/member | Integrated; physical signup/provisioning validated |
| Forgot password | `features/auth/widgets/forgot_password_sheet.dart` | recovery request | Supabase Auth generic reset request | Integrated; mailbox callback completion not claimed |
| App shell | `features/shell/app_shell.dart` | five-tab frame/cart access | Riverpod local state | UI/local |
| Home | `features/home/home_screen.dart` | points/stamps/promos/categories/menu actions | mock providers + local check-in | UI/mock/local |
| Rewards | `features/rewards/rewards_screen.dart` | balance/vouchers/reward catalogue | mock | UI/mock |
| Membership QR | `features/card/membership_card_screen.dart` | member identity code | owner-scoped Supabase member read + user-scoped minimum offline cache | Integrated source/cache; physical provisioning validated |
| Menu | `features/menu/menu_screen.dart` | browse/filter/favorites | Supabase catalogue + Realtime invalidation; local favourites | Integrated; physical Admin-price mutation observed |
| Item detail | `features/menu/item_detail_screen.dart` | variant/add-ons/note/quantity/cart | Supabase catalogue item + widget state | Integrated catalogue/local cart intent |
| Cart | `features/cart/cart_screen.dart` | edit selections and enter checkout | local intent/estimate, then authoritative server quote | Integrated; local values are not placement authority |
| Checkout sheet | `features/cart/order_checkout_sheet.dart` | ASAP/scheduled selection and placement | ordering policy + quote/place RPCs | Integrated; Pay at counter only |
| Order confirmation | `features/cart/order_confirmation_screen.dart` | persisted order number/status | authoritative order snapshot + Realtime-refetch | Integrated; no fake timer |
| Order history | `features/history/order_history_screen.dart` | owner order history | `get_my_orders()` | Integrated owner-scoped read |
| Order receipt | `features/history/order_detail_screen.dart` | immutable order detail | `get_order()` server snapshot | Integrated owner-scoped read |
| Profile | `features/profile/profile_screen.dart` | member/account menu | mock/session member | UI/partial placeholders |
| Edit profile | `features/profile/edit_profile_screen.dart` | local edits | member overlay | Session-only |

Visible placeholders include social sign-in, promo detail, notifications, reward redemption, voucher consumption, profile photo, stats, settings, invite and help.

Planned/absent customer surfaces include verification-pending workflow, points ledger, password change/delete account and real settings. POS/Admin surfaces exist in the separate dashboard repository and are mapped under `docs/dashboard/UI_SCREEN_MAP.md`; deployed order-journey proof remains pending there.
