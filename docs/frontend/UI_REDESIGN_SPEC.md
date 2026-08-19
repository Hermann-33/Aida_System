# Customer UI Redesign Specification

Updated: 2026-08-20

This document describes the customer/mobile UI redesign integrated from the historical `customer-app-redesign` work onto the current `master` baseline. Runtime and integration status remain governed by `UI_SCREEN_MAP.md`, `STATE_AND_DATA_FLOW.md`, the shared backend contracts, and accepted ADRs.

## Scope

Redesigned customer surfaces:

- Menu
- Item detail
- Cart
- Checkout sheet
- Rewards
- floating cart affordance
- shared logo/control presentation used by those surfaces

The redesign does not change routes, authentication, member identity, catalogue authority, cart/order authority, payment semantics, loyalty authority, or Supabase contracts.

The source branch was not merged directly because it was 140 commits behind `master`, contained unrelated historical admin-sidebar commits, and contained a checkout scheduling implementation that diverged from the authoritative ordering policy. Integration therefore used a clean branch from current `master` and carried only the reviewed redesign delta.

## Design system

### Colors

Canonical values remain in `apps/customer/lib/core/theme/aida_colors.dart`:

| Token | Value / derivation | Role |
|---|---|---|
| `cityRed` | `#AF2626` | CityU/student identity |
| `cream` | `#FDF6F7` | page background |
| `latte` | `#F2CFD6` | secondary surfaces/dividers |
| `coffee` | `#C13A52` | primary actions/accent |
| `espresso` | `#27121A` | dark surfaces/high-contrast text |
| `rewardGold` | `#C9A24E` | loyalty emphasis |
| `cardWhite` | `#FFFFFF` | elevated/light surfaces |
| `caramelTint` | `#F7DEE3` | soft placeholder tint |
| `textMuted` | `#976B77` | secondary text |
| `error` | `#8C3A2E` | error/destructive state |
| `success` | `#4F6B4A` | confirmation |
| `successLight` | derived from `success` | light stop for confirmation gradients |

No redesigned surface owns trusted business meaning through color alone.

### Typography

Typography remains centralized in `AidaType`:

- Playfair Display for display/serif hierarchy.
- Plus Jakarta Sans for interface/body text.
- `AidaTheme.sectionLabel` for uppercase section labels.

No network-fetched font dependency is introduced.

### Shape and elevation

The redesign emphasizes:

- flatter Menu and Cart rows separated by whitespace/hairline dividers;
- 18–28 px rounded controls/cards/sheets;
- soft two-shadow tactile controls for selected/add/category affordances;
- the existing dark coffee-to-espresso card language for Rewards;
- local animated feedback instead of adding new global navigation chrome.

### Logo and imagery

`apps/customer/assets/images/aida_logo.jpg` is bundled and rendered through `AidaLogo` where the shared logo widget is used. Rewards also uses the asset as a low-opacity card watermark.

Product/menu imagery continues to use existing catalogue image URLs and category assets/fallbacks. No image becomes catalogue authority.

## Shared components

### New

- `features/menu/widgets/menu_category_rail.dart` — vertical Menu-only category/favorites rail.
- `features/menu/widgets/menu_list_item.dart` — photo-forward Menu list row.

### Changed

- `core/widgets/neumorphic_control.dart` — optional accent-gradient override used for transient success feedback.
- `features/cart/widgets/floating_cart_bar.dart` — animated presence and cart-line thumbnails while retaining the same cart provider/route.
- `core/theme/aida_logo.dart` — renders the bundled AIDA logo asset.

### Retired

`features/menu/widgets/menu_grid_item.dart` is superseded by `MenuListItem` and should not be used for new Menu work.

## Navigation and information architecture

Cross-screen navigation is unchanged:

- five-tab `AppShell` remains an `IndexedStack`;
- Menu items still open `ItemDetailScreen` before cart insertion, preserving variant/add-on selection;
- Cart still opens `OrderCheckoutSheet` in a modal bottom sheet;
- successful placement still clears cart state only after persisted placement and opens order confirmation;
- Rewards card actions scroll to existing sections rather than inventing new routes.

## Screen specifications

### Menu

Implementation:

- `features/menu/menu_screen.dart`
- `features/menu/widgets/menu_category_rail.dart`
- `features/menu/widgets/menu_list_item.dart`

Changes:

- replaces the previous grid presentation with a photo-forward single-column list;
- introduces a fixed vertical category/favorites rail;
- groups unfiltered catalogue content by category with section labels;
- keeps pull-to-refresh through `catalogueProvider` invalidation;
- keeps favorites local/session state;
- keeps unavailable items non-interactive.

Data boundary: unchanged. Menu content remains Supabase catalogue data with Realtime invalidation/refetch; client filtering is presentation state only.

### Item detail

Implementation: `features/menu/item_detail_screen.dart`.

Changes:

- keeps the existing hero/detail/configuration layout;
- consolidates the old Customize shortcut plus icon-only cart action into a quantity control and one `Add to cart · total` CTA;
- uses a brief `Added` confirmation state on the CTA instead of a SnackBar.

Data boundary: unchanged. Variant/add-on compatibility and prices come from the catalogue; the cart remains local intent and is re-priced by the server at checkout.

### Cart

Implementation: `features/cart/cart_screen.dart`.

Changes:

- flattens line items into photo-forward rows;
- adds swipe-to-remove;
- keeps quantity editing and configuration/note summaries;
- keeps the bottom amount explicitly labelled `Estimated subtotal`;
- keeps the `Review order` transition into the server quote flow.

Data boundary: unchanged. Cart values are estimates/intents, never placement authority.

### Floating cart bar

Implementation: `features/cart/widgets/floating_cart_bar.dart`.

Changes:

- animates entrance/exit;
- shows overlapping thumbnails for up to three cart lines plus overflow;
- retains item count, estimated subtotal, and Cart navigation.

### Checkout sheet

Implementation: `features/cart/order_checkout_sheet.dart`.

The visual redesign keeps a tactile wheel-style scheduled-time selector, but the integrated version deliberately differs from the original stale branch implementation.

**Authoritative scheduling rule:** the wheel is populated only from `derivePickupSlots(OrderingPolicy)`. Therefore selectable values continue to respect:

- `scheduleEnabled`;
- `minimumLeadMinutes`;
- `slotIntervalMinutes`;
- `maximumAdvanceDays`;
- backend-provided timezone/server time.

The integration does **not** hardcode café opening hours and does **not** offer arbitrary one-minute values. This preserves the accepted ordering contract while retaining the redesigned wheel interaction.

The sheet still:

- requests an authoritative server quote;
- renders `Server total`;
- places only through `OrderCheckoutSession`/`OrderRepository`;
- keeps Pay-at-counter semantics;
- uses retry-stable placement idempotency from the existing session abstraction.

### Rewards

Implementation: `features/rewards/rewards_screen.dart`.

Changes:

- redesigns the balance surface into the same dark card family as Membership QR;
- adds the AIDA logo watermark;
- adds in-card `Vouchers` and `Redeem` navigation controls;
- keeps earned voucher and points-catalogue ticket behavior unchanged.

Data boundary: unchanged. Reward redemption remains deferred; UI actions must not pretend points or vouchers have changed when no authoritative backend mutation occurred.

## Motion

Local motion includes:

- checkout wheel fade/size entrance;
- fixed-extent wheel magnification/selection feedback;
- floating cart bar fade/slide;
- cart thumbnail pop-in;
- item-detail Added confirmation swap;
- existing neumorphic press feedback.

No route transition architecture or global motion framework is added.

## Accessibility

Implemented evidence includes semantic labels/selected state on major tactile controls and visible text labels for primary actions. The redesign does not claim WCAG conformance. Small 36–38 px icon controls and full dynamic-text/large-font coverage require explicit accessibility validation before such compliance can be claimed.

## Responsive behavior

The redesign remains phone-first. Existing Flutter layout primitives provide some width flexibility, but no tablet-specific or landscape-specific redesign is claimed. The fixed 76 px Menu rail is an intentional phone layout decision and should be revisited if tablet/web becomes a supported production target.

## Screenshots

Repository-local redesign evidence retained from the source branch:

- `docs/screenshots/2026-08-19-menu-redesign.png`
- `docs/screenshots/2026-08-19-item-detail-redesign.png`
- `docs/screenshots/2026-08-19-cart-redesign.png`
- `docs/screenshots/2026-08-19-rewards-redesign.png`

The original `2026-08-19-checkout-sheet-redesign.png` is intentionally not integrated because it depicts the rejected arbitrary-minute/hardcoded-hours picker rather than the contract-safe integrated checkout wheel.

## Maintenance rules

- Do not reintroduce `MenuGridItem` for the customer Menu without an explicit redesign decision.
- New Menu work should reuse `MenuCategoryRail`/`MenuListItem` rather than cloning them.
- Keep client cart totals labelled as estimates until the server quote returns.
- Never construct scheduled pickup times outside `OrderingPolicy`/`derivePickupSlots` unless the backend contract changes first.
- Do not add local café-hours constants as scheduling authority.
- Do not turn Rewards presentation into points/voucher authority.
- Keep logo/image assets presentation-only.
- Golden baselines require deliberate visual review; do not update them merely to make tests green.

## Verification state

The source redesign branch recorded `flutter analyze` with 0 issues and `flutter test` with 40/44 passing; its four failures were documented as pre-existing golden-image mismatches. Those results apply to the source branch before this integration correction.

The integration review independently verified source/data-flow boundaries and corrected the scheduling contract violation. No CI workflow exists in this repository, and the integration environment used for this repository operation did not expose a Flutter toolchain, so the corrected integration commit has not been independently re-run through `flutter analyze`/`flutter test` here. That limitation must not be rewritten as a passing local test result.

Cross-repository documentation sync remains pending by task scope; the Dashboard repository is handled separately.
