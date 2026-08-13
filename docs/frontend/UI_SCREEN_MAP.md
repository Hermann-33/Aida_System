> Scope note: this map describes the current customer Flutter runtime, even when read from the mirrored Dashboard repository.

# Customer UI Screen Map

Updated: 2026-08-14

Statuses distinguish trusted backend integration from local/deferred presentation state.

| Surface | File path | Purpose / role | Current data source | Status |
|---|---|---|---|---|
| Auth gate | `apps/customer/lib/main.dart` | restore customer session / choose auth vs app | Supabase restored session + Auth state stream | Integrated; Android runtime physically validated |
| Sign in / sign up | `features/auth/login_screen.dart` | credentials / registration | Supabase Auth + trusted provisioning trigger | Integrated; physical signup validated |
| Forgot password | `features/auth/widgets/forgot_password_sheet.dart` | recovery request | Supabase Auth reset request | Integrated request boundary; mailbox/callback E2E not separately closed |
| App shell | `features/shell/app_shell.dart` | five-tab frame/cart navigation | Riverpod presentation state | UI/local navigation |
| Home | `features/home/home_screen.dart` | entry/promos/categories/featured content | shared catalogue plus deferred/mock loyalty/promo state | Mixed integrated/preview |
| Rewards | `features/rewards/rewards_screen.dart` | balance/vouchers/reward catalogue | mock/deferred loyalty | Preview |
| Membership QR | `features/card/membership_card_screen.dart` | trusted member identity code | owner-scoped Supabase member read + user-scoped minimum offline cache | Integrated source/cache |
| Menu | `features/menu/menu_screen.dart` | browse/filter/favorites | Supabase catalogue + Realtime invalidation; local favorites | Integrated catalogue; physical admin-mutation refresh validated |
| Item detail | `features/menu/item_detail_screen.dart` | variant/add-ons/note/quantity/cart | Supabase catalogue item + local selection state | Integrated catalogue/local intent |
| Cart | `features/cart/cart_screen.dart` | edit selections / enter checkout | local selection state and presentation estimate | Local intent only; not commercial authority |
| Order checkout | `features/cart/order_checkout_sheet.dart` | authoritative quote, ASAP/scheduled pickup, Pay at counter, placement | ordering policy + `quote_order` + `place_customer_order` | Integrated authoritative order path |
| Order confirmation | `features/cart/order_confirmation_screen.dart` | persisted order number/schedule/status | backend order snapshot/provider | Integrated; no fake timer progression |
| Order history | `features/history/order_history_screen.dart` | customer orders | `get_my_orders` backend snapshots | Integrated |
| Order detail/receipt | `features/history/order_detail_screen.dart` | immutable placed-order detail | `get_order` backend snapshot | Integrated |
| Profile | `features/profile/profile_screen.dart` | account/member menu | trusted member data plus deferred/profile placeholders | Partial |
| Edit profile | `features/profile/edit_profile_screen.dart` | profile edit UI | local/session overlay; trusted persistence not complete | Deferred persistence |

## Current cross-system evidence

- Physical Android signup succeeded and provisioned a trusted customer/member visible in Dashboard Members.
- A real Owner catalogue price change in Dashboard Admin Menu propagated to the installed customer Menu.
- Android release networking no longer fails with the pre-fix host-resolution error.

## Explicit local/deferred boundaries

Local cart arithmetic may be an estimate but cannot become persisted order authority. Final quote/total/order number/schedule/status come from the backend.

There is no trusted payment processor in this tranche. The authoritative order path uses explicit `Pay at counter`/unpaid semantics.

Visible/deferred areas still include loyalty/rewards/offers/promotions, social sign-in, notifications, voucher consumption, profile-write persistence, profile photo/stats/settings/help and other domains named in the roadmap.

The final cross-client order fulfilment E2E remains a TASK-CLOSEOUT-001 gate because the Dashboard React order board is still being integrated with the existing order BFF.
