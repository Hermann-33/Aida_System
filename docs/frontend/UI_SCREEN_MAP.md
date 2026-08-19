> Scope note: this map always describes the customer Flutter repository, even when read from the mirrored Dashboard copy.

# Customer UI Screen Map

Updated: 2026-08-19

Statuses describe current runtime behavior, not design intent.

| Surface | File path | Purpose / role | Current data source | Status |
|---|---|---|---|---|
| Auth gate | `apps/customer/lib/main.dart` | customer startup/session selection | restored Supabase session + Auth state stream | Integrated; physical signup/session path validated |
| Sign in / sign up | `features/auth/login_screen.dart` | credentials/registration UI | Supabase Auth + server-provisioned profile/member | Integrated; physical signup/provisioning and final E2E Auth validated |
| Forgot password | `features/auth/widgets/forgot_password_sheet.dart` | recovery request | Supabase Auth reset request | Integrated request boundary; mailbox callback completion not claimed |
| App shell | `features/shell/app_shell.dart` | five-tab frame/cart access | Riverpod local state | UI/local |
| Home | `features/home/home_screen.dart` | points/stamps/promos/categories/menu actions | mixed shared catalogue + mock/local rewards/check-in content | Partial; catalogue-backed menu content, deferred loyalty/promotions |
| Rewards | `features/rewards/rewards_screen.dart` | balance/vouchers/reward catalogue | mock | Preview/deferred |
| Membership QR | `features/card/membership_card_screen.dart` | member identity code | owner-scoped Supabase member read + user-scoped minimum offline cache | Integrated; physical provisioning validated |
| Menu | `features/menu/menu_screen.dart` | browse/filter/favorites | Supabase catalogue + Realtime invalidation; local favourites | Integrated; physical Owner price mutation observed |
| Item detail | `features/menu/item_detail_screen.dart` | variant/add-ons/note/quantity/cart | Supabase catalogue item + widget interaction state | Integrated catalogue/local intent |
| Cart | `features/cart/cart_screen.dart` | edit selections and enter checkout | local intent/estimate, then authoritative server quote | Integrated; local values not placement authority |
| Checkout sheet | `features/cart/order_checkout_sheet.dart` | ASAP/scheduled selection and placement | ordering policy + quote/place RPCs | Integrated; Pay at counter only |
| Order confirmation | `features/cart/order_confirmation_screen.dart` | server order number/status | authoritative order snapshot + Realtime/refetch | Integrated; no fake timer; live status E2E validated |
| Order history | `features/history/order_history_screen.dart` | owner order history | `get_my_orders()` | Integrated owner-scoped read |
| Order receipt/detail | `features/history/order_detail_screen.dart` | immutable order detail | `get_order()` server snapshot | Integrated owner-scoped read |
| Profile | `features/profile/profile_screen.dart` | member/account menu | mixed member/session and placeholders | Partial |
| Edit profile | `features/profile/edit_profile_screen.dart` | profile-edit presentation | local/member overlay | Session-only; trusted profile-write scope deferred |

## Validated customer journeys

- Physical release signup → trusted member provisioning → Dashboard Members: PASS.
- Owner catalogue mutation → installed customer refresh: PASS.
- Final order E2E: customer quote/place order `100006` → Dashboard preparing/ready/completed transitions → customer-authorized status reads: PASS.

## Remaining visible/deferred surfaces

Social sign-in, promo detail, notifications, reward redemption, voucher consumption, profile photo/stats/settings/invite/help, full verification-pending workflow, points ledger, password-change/delete-account UX, trusted profile writes and hosted production release operations remain outside the completed tranche.

POS/Admin surfaces are implemented in the separate Dashboard repository and mapped under `docs/dashboard/UI_SCREEN_MAP.md`.

## 2026-08-19 frontend changes needing backend follow-up

Menu, Item detail, Cart, Checkout sheet, and Rewards all got UI/UX
redesigns this pass (photo-forward menu list with a category rail, flat
swipe-to-delete cart, animated hour/minute pickup wheel, single
consolidated add-to-cart CTA, membership-card-style rewards balance
card). All of it is presentation-layer only — none of it changes what
data source or RPC a surface uses, so the table above is still accurate
as-is. Two things from the checkout-sheet rework do need backend
awareness, though:

- **Pickup minute selection is no longer clamped to
  `OrderingPolicy.slotIntervalMinutes`.** Product wants every minute
  selectable in the picker (not just the server's interval steps), on
  the understanding that the backend will relax that interval
  validation to match. Until then, `quoteOrder`/`placeCustomerOrder`
  calls carrying an off-interval `requestedPickupAt` will fail
  server-side exactly as designed today — the customer app already
  degrades to a plain error message when that happens (no crash), but
  every schedule attempt will hit it until the interval constraint is
  relaxed or reworked.
- **Same-day scheduling now also enforces an 8am–5pm café-hours
  window, client-side only.** There's no operating-hours concept
  anywhere in `OrderingPolicy` or the ordering RPCs yet, so this is a
  hardcoded stopgap in `order_checkout_sheet.dart`
  (`_cafeOpenHour`/`_cafeCloseHour`), not a real policy value. It
  should move into the ordering policy response once that's modelled
  server-side, both so hours can change without an app release and so
  the server enforces the same window it accepts requests for.
