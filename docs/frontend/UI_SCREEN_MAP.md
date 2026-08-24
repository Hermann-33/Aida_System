> Scope note: this map always describes the customer Flutter repository, even when read from the mirrored Dashboard copy.

# Customer UI Screen Map

Updated: 2026-08-24

Statuses describe current runtime behavior, not design intent.

| Surface | File path | Purpose / role | Current data source | Status |
|---|---|---|---|---|
| Auth gate | `apps/customer/lib/main.dart` | customer startup/session selection | restored Supabase session + Auth state stream | Integrated; physical signup/session path validated |
| Sign in / sign up | `features/auth/login_screen.dart` | credentials/registration UI | Supabase Auth + server-provisioned profile/member | Integrated; physical signup/provisioning and final E2E Auth validated |
| Forgot password | `features/auth/widgets/forgot_password_sheet.dart` | recovery request | Supabase Auth reset request | Integrated request boundary; mailbox callback completion not claimed |
| App shell | `features/shell/app_shell.dart` | five-tab frame/cart access | Riverpod local state | UI/local |
| Home | `features/home/home_screen.dart` | points/stamps/promos/categories/menu actions | mixed shared catalogue + mock/local rewards/check-in content | Partial; catalogue-backed menu content, deferred loyalty/promotions |
| Rewards | `features/rewards/rewards_screen.dart` | member balance-card presentation, vouchers/reward catalogue | mixed: real owner-scoped member/profile display + mock points/rewards/vouchers | Preview/deferred for loyalty; member identity display is real |
| Membership QR | `features/card/membership_card_screen.dart` | member identity code | owner-scoped Supabase member read + user-scoped minimum offline cache | Integrated; QR/member boundary unchanged; shared bundled logo now replaces placeholder |
| Menu | `features/menu/menu_screen.dart` | browse/filter/favorites | Supabase catalogue + Realtime invalidation; local favourites | Integrated; physical Owner price mutation observed |
| Item detail | `features/menu/item_detail_screen.dart` | variant/add-ons/note/quantity/cart | Supabase catalogue item + widget interaction state | Integrated catalogue/local intent |
| Cart | `features/cart/cart_screen.dart` | edit selections and enter checkout | local intent/estimate, then authoritative server quote | Integrated; local values not placement authority |
| Checkout sheet | `features/cart/order_checkout_sheet.dart` | Now/scheduled selection and placement | ordering policy + quote/place RPCs | Integrated; scheduled values derived from server policy; Pay at counter only |
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

## 2026-08-24 redesign + customization merge note

Menu, Item detail, Cart, Checkout sheet and Rewards received a
presentation-layer redesign on `customer-app-redesign` (2026-08-19), and
`hermann/master` independently landed `TASK-MENU-CUSTOMIZATION-001` (drink
Temperature/Sweetness customization on Item detail) plus a checkout-sheet
rework. Both were merged into `customer-app-redesign` on 2026-08-24. It
does not change any row above's file path, purpose, or data source. The
shared `AidaLogo` replacement also changes Membership QR presentation
because that screen already consumes the shared widget; QR/member identity
semantics are unchanged. Full design-system, component and screen-by-screen
detail, including the 2026-08-24 merge section, is in
`docs/frontend/UI_REDESIGN_SPEC.md`.

The original redesign branch's Checkout sheet experimented with
arbitrary-minute scheduling and a client-only 8am–5pm opening-hours window
— both previously flagged here and in `FRAGILE_BOUNDARIES.md` as
contract-incompatible. That implementation was rejected during the merge.
The integrated Checkout sheet retains the wheel-style interaction but
populates it only from `derivePickupSlots(OrderingPolicy)`, so the runtime
status above remains contract-compatible with `slotIntervalMinutes`,
minimum lead time, maximum advance horizon and backend-provided
timezone/server time.

Rewards now combines real member display identity with still-mock loyalty
values. It must not be described either as wholly mock or as trusted
loyalty integration.

Pre-merge backend-impact/test audit of the customization work:
`docs/frontend/UI_REDESIGN_AUDIT_2026-08-20.md`.
