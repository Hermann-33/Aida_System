# Codebase Map

## Repository root

`C:\code\Aida_System` contains one Git repository on `master` at the audit baseline.

| Path | Purpose |
|---|---|
| `apps/customer/` | Active Flutter customer application |
| `docs/screenshots/` | Sixteen customer UI reference captures |
| `docs/superpowers/specs/` | Customer design and cart/ordering specifications |
| `Aida_System_Unified_PRD_v2.0.md` | Mixed historical/current product requirements; not runtime proof |
| `docs/context/`, `docs/decisions/`, `docs/frontend/`, `docs/security/` | Governance baseline created by TASK-WF-001 |

No backend, Supabase, POS/staff, or admin source folder was found.

## Active app: `apps/customer`

### Entry and navigation

| File | Role |
|---|---|
| `lib/main.dart` | `main`, `AidaApp`, scroll behavior, boolean `AuthGate` |
| `lib/features/shell/app_shell.dart` | Five-tab `IndexedStack` and floating navigation |
| `lib/application/providers.dart` | Tab/category navigation state and all Riverpod application state |
| `lib/features/menu/item_detail_screen.dart` | Shared imperative `openItemDetail` route helper |

There is no central router. `go_router` is declared in `pubspec.yaml` but unused.

### Screens and feature surfaces

| Feature | Files |
|---|---|
| Auth | `features/auth/login_screen.dart`, `signup_screen.dart`, `widgets/forgot_password_sheet.dart` |
| Home | `features/home/home_screen.dart` and `features/home/widgets/` |
| Rewards | `features/rewards/rewards_screen.dart` and ticket widgets |
| Membership | `features/card/membership_card_screen.dart` |
| Menu | `features/menu/menu_screen.dart`, `item_detail_screen.dart`, and menu widgets |
| Cart/order | `features/cart/cart_screen.dart`, `order_confirmation_screen.dart`, floating cart bar |
| History | `features/history/order_history_screen.dart`, `order_detail_screen.dart`, status pill |
| Profile | `features/profile/profile_screen.dart`, `edit_profile_screen.dart` |

See `docs/frontend/UI_SCREEN_MAP.md` for navigation/data/status details.

### Domain models and entities

`lib/domain/model/` contains:

- `Member`, `StudentStatus`;
- `Points`, `StampCard`;
- `MenuCategory`, `MenuItem`, `ItemSize`;
- `Money` in integer sen;
- `Cart`, `CartLineItem`;
- `PastOrder`, `OrderStatus`;
- `Offer`, `OfferAudience`, `Promo`;
- `Reward`, `RewardKind`, `Voucher`.

There are no DTOs, JSON serializers, generated database types, transaction ledger entities, staff/admin role entities, quote response, or persisted order-state model.

### Repositories, services, and providers

| Path | Current role |
|---|---|
| `lib/domain/repository/member_repository.dart` | Broad customer read/auth interface |
| `lib/data/repository/mock_member_repository.dart` | Only adapter; hardcoded demo content and synthetic latency |
| `lib/application/providers.dart` | Binding, async reads, session state, and client-side write simulations |
| `lib/core/error/result.dart` | `Result`, `Ok`, `Err` |
| `lib/core/error/failures.dart` | Typed failure taxonomy, mostly not exercised by current adapter |

No HTTP/API service, Supabase service, secure storage, cache, analytics, notifications, realtime, image upload, or payment service exists.

### Theme, assets, and reusable components

| Area | Paths |
|---|---|
| Palette/theme/type | `lib/core/theme/aida_colors.dart`, `aida_theme.dart`, `aida_type.dart` |
| Logo | `lib/core/theme/aida_logo.dart`—placeholder `LOGO` widget |
| Core widgets | `product_image.dart`, `neumorphic_control.dart`, `entrance.dart` |
| Feature widgets | category strip/chip/grid item, popular cards, promo carousel, stamp/reward visuals, floating cart bar, order status pill, auth fields |
| Fonts | bundled Playfair Display and Plus Jakarta Sans in `assets/fonts/` |
| Images | auth hero art, coffee cup, and category cut-outs in `assets/images/` |
| Network images | temporary Unsplash URLs in `mock_member_repository.dart` |

Color values and the final logo are provisional. The web manifest retains Flutter scaffold naming/colors.

### Tests

| Path | Coverage |
|---|---|
| `test/domain/money_test.dart` | integer-sen formatting/comparison |
| `test/domain/cart_test.dart` | size, merge, add-on, line/subtotal calculations |
| `test/widget_test.dart` | boot smoke check and membership QR/member rendering |
| `test/widgets/category_strip_test.dart` | responsive strip behavior |
| `test/widgets/popular_item_grid_test.dart` | popular grid behavior |
| `test/widgets/item_detail_navigation_test.dart` | item route/back and sold-out state |
| `test/widgets/cart_flow_test.dart` | configured item through checkout/cart clear |
| `test/golden/screens_golden_test.dart` | Home, scrolled Home, selected Menu, membership card baselines |

There are no integration-test target, real data-adapter tests, auth security tests, RLS tests, offline/cache tests, POS/admin tests, or deployment smoke tests.

### Build and configuration

- `pubspec.yaml` / `pubspec.lock`: Dart `^3.7.0`, Flutter, Riverpod, QR, clock, and unused `go_router` dependency.
- `analysis_options.yaml`: `flutter_lints` defaults; no strict analyzer language settings.
- `android/`: Gradle/Kotlin runner; release currently uses debug signing and contains a setup TODO.
- `ios/`: Xcode runner and CocoaPods config.
- `web/`: Flutter web bootstrap, manifest, scaffold icons.
- No committed native Windows/macOS/Linux runner and no CI workflow was found.

Repository-discovered commands:

```powershell
cd apps/customer
flutter analyze
flutter test
flutter test --update-goldens  # only after visual review and explicit approval
```

This audit used `--no-pub` to prevent lockfile changes.

## Existing docs and specifications

- `Aida_System_Unified_PRD_v2.0.md`: broad product requirements and legacy deployment narrative. It contains internal contradictions with the current checkout and must be interpreted through current governance.
- `docs/superpowers/specs/2026-07-10-aida-customer-app-design.md`: customer architecture and offline/security intent; several planned pieces such as secure storage/cache are not implemented.
- `docs/superpowers/specs/2026-07-13-cart-ordering-design.md`: explicitly authorizes an in-memory checkout prototype with placeholder pricing.
- `docs/screenshots/01-login.png` through `16-edit-profile.png`: visual snapshots of current customer surfaces.

## Fragile and important files

Do not change casually:

- `lib/application/providers.dart`: navigation, data binding, and session state in one file.
- `lib/domain/repository/member_repository.dart`: current backend seam, but incomplete for writes.
- `lib/data/repository/mock_member_repository.dart`: mock data shapes many UI assumptions.
- `lib/main.dart` and `features/shell/app_shell.dart`: auth and navigation lifecycle.
- `lib/domain/model/money.dart`, `cart.dart`, `item_size.dart`: monetary/configuration behavior.
- `features/cart/cart_screen.dart`: client totals, order generation, payment simulation, and history coupling.
- `features/card/membership_card_screen.dart`: QR payload and offline claim.
- `features/home/home_screen.dart`: large, stateful, tightly coupled composition.
- `features/menu/item_detail_screen.dart`: large UI/state/calculation/navigation surface.
- golden images under `test/golden/goldens/`: approval artifacts, not disposable outputs.
