# Codebase Map

Updated: 2026-08-11

## Repository root

| Path | Purpose |
|---|---|
| `apps/customer/` | Active Flutter customer application |
| `supabase/` | Supabase CLI config, migrations, and database check scripts added by `TASK-DB-001` |
| `docs/database/` | Database foundation reference documentation |
| `docs/screenshots/` | Customer UI reference captures |
| `docs/superpowers/specs/` | Customer design and cart/ordering specifications |
| `Aida_System_Unified_PRD_v2.0.md` | Mixed historical/current product requirements; not runtime proof |
| `docs/context/`, `docs/decisions/`, `docs/frontend/`, `docs/security/` | Governance, ADR, frontend audit and security documentation |

No POS/staff/admin source folder is present.

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

`apps/customer/lib/domain/model/` contains customer-facing prototype entities:

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

No HTTP/API service, Supabase Flutter service, secure storage, cache, analytics, notifications, realtime, image upload, or payment service exists.

## Supabase folder

| Path | Purpose |
|---|---|
| `supabase/config.toml` | Local Supabase CLI stack configuration; no secrets |
| `supabase/README.md` | Project reference, migration ledger and local commands |
| `supabase/migrations/20260811101100_create_identity_membership_foundation.sql` | Initial identity/profile/member/student-verification schema, grants, triggers and RLS |
| `supabase/migrations/20260811102200_harden_foundation_role_helpers.sql` | Moves RLS helper functions to the non-exposed `private` schema |
| `supabase/migrations/20260811102700_optimize_foundation_rls_policies.sql` | Optimizes RLS policies and adds reviewed-by index |
| `supabase/tests/rls_foundation.sql` | Lightweight SQL checks for schema/RLS posture on local/reset database |

The migrations were also applied to remote project `eswovqxqzfevcdwwcmuh` during `TASK-DB-001`.

## Database documentation

| Path | Purpose |
|---|---|
| `docs/database/SCHEMA_FOUNDATION.md` | Current schema reference, RLS posture, advisor results and next database task |

## Tests

| Path | Coverage |
|---|---|
| `apps/customer/test/domain/money_test.dart` | integer-sen formatting/comparison |
| `apps/customer/test/domain/cart_test.dart` | size, merge, add-on, line/subtotal calculations |
| `apps/customer/test/widget_test.dart` | boot smoke check and membership QR/member rendering |
| `apps/customer/test/widgets/category_strip_test.dart` | responsive strip behavior |
| `apps/customer/test/widgets/popular_item_grid_test.dart` | popular grid behavior |
| `apps/customer/test/widgets/item_detail_navigation_test.dart` | item route/back and sold-out state |
| `apps/customer/test/widgets/cart_flow_test.dart` | configured item through checkout/cart clear |
| `apps/customer/test/golden/screens_golden_test.dart` | Home, scrolled Home, selected Menu, membership card baselines |
| `supabase/tests/rls_foundation.sql` | SQL posture checks for tables, RLS and grants |

There are still no Flutter integration-test target, real data-adapter tests, auth security tests, POS/admin tests, or deployment smoke tests.

## Build and configuration files

- `apps/customer/pubspec.yaml` / `pubspec.lock`: Flutter/Riverpod/QR/clock/go_router dependencies. No Supabase Flutter dependency yet.
- `apps/customer/analysis_options.yaml`: `flutter_lints` defaults.
- `supabase/config.toml`: local Supabase CLI configuration.
- No committed CI workflow was found in the audit baseline.

Repository-discovered customer app commands:

```powershell
cd apps/customer
flutter analyze
flutter test
flutter test --update-goldens  # only after visual review and explicit approval
```

Supabase commands:

```bash
supabase start
supabase db reset
supabase migration list
supabase db lint
```

## Fragile and important files

Do not change casually:

- `apps/customer/lib/application/providers.dart`: navigation, data binding, and session state in one file.
- `apps/customer/lib/domain/repository/member_repository.dart`: current backend seam, but incomplete for writes.
- `apps/customer/lib/data/repository/mock_member_repository.dart`: mock data shapes many UI assumptions.
- `apps/customer/lib/main.dart` and `features/shell/app_shell.dart`: auth and navigation lifecycle.
- `apps/customer/lib/domain/model/money.dart`, `cart.dart`, `item_size.dart`: monetary/configuration behavior.
- `apps/customer/features/cart/cart_screen.dart`: client totals, order generation, payment simulation, and history coupling.
- `apps/customer/features/card/membership_card_screen.dart`: QR payload and offline claim.
- `supabase/migrations/`: append-only migration history; do not edit applied migrations after merge except through a superseding migration.
- `supabase/config.toml`: local stack settings; do not add secrets.
- `test/golden/goldens/`: approval artifacts, not disposable outputs.

## Do not touch without explicit scope

- Do not wire Flutter to Supabase in database-foundation tasks.
- Do not create menu/order/loyalty/POS schema in identity-foundation tasks.
- Do not add storage buckets without a storage and image-ownership decision.
- Do not add secrets or local `.env` content to the repository.