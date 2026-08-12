> Scope note: this map always describes the customer Flutter repository, even when read from the mirrored dashboard copy.

# UI Screen Map

Statuses describe current customer runtime behavior, not design intent.

| Surface | File path | Purpose / role | Current data source | Status |
|---|---|---|---|---|
| Auth gate | `apps/customer/lib/main.dart` | customer startup selection | local `authStateProvider` | Mock |
| Sign in / sign up | `features/auth/login_screen.dart` | credentials/registration UI | mock repo + client-generated member | UI/mock |
| Forgot password | `features/auth/widgets/forgot_password_sheet.dart` | recovery request | mock delay | UI/mock |
| App shell | `features/shell/app_shell.dart` | five-tab frame/cart access | Riverpod local state | UI/local |
| Home | `features/home/home_screen.dart` | points/stamps/promos/categories/menu actions | mock providers + local check-in | UI/mock/local |
| Rewards | `features/rewards/rewards_screen.dart` | balance/vouchers/reward catalogue | mock | UI/mock |
| Membership QR | `features/card/membership_card_screen.dart` | member identity code | mock/session member | UI/mock; offline persistence missing |
| Menu | `features/menu/menu_screen.dart` | browse/filter/favorites | mock catalogue + local favourites | UI/mock/local |
| Item detail | `features/menu/item_detail_screen.dart` | size/add-ons/note/quantity/cart | mock item + widget state | UI/mock/local |
| Cart | `features/cart/cart_screen.dart` | edit lines/subtotal/checkout | local cart + client arithmetic | UI/local |
| Payment sheet | `features/cart/cart_screen.dart` | method selection | local enum | UI/mock |
| Order confirmation | `features/cart/order_confirmation_screen.dart` | number/timed stages | client random number/timer | Simulated |
| Order history | `features/history/order_history_screen.dart` | current-process orders | memory | Session-only |
| Order receipt | `features/history/order_detail_screen.dart` | local receipt | `PastOrder` + mock menu | Session-only |
| Profile | `features/profile/profile_screen.dart` | member/account menu | mock/session member | UI/partial placeholders |
| Edit profile | `features/profile/edit_profile_screen.dart` | local edits | member overlay | Session-only |

Visible placeholders include social sign-in, promo detail, notifications, reward redemption, voucher consumption, profile photo, stats, settings, invite and help.

Planned/absent customer surfaces include real session bootstrap, verification-pending flow, scheduled-order slots, points ledger, password change/delete account and real settings. POS/Admin surfaces exist in the separate dashboard repository and are mapped under `docs/dashboard/UI_SCREEN_MAP.md`.