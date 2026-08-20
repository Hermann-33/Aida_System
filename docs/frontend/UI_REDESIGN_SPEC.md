# Customer UI Redesign Specification

Updated: 2026-08-20

This document describes the customer/mobile UI redesign integrated onto the current customer `master` baseline. Runtime/integration truth remains governed by `UI_SCREEN_MAP.md`, `STATE_AND_DATA_FLOW.md`, the shared backend contracts and accepted ADRs. Post-merge backend-impact/test evidence is in `UI_REDESIGN_AUDIT_2026-08-20.md`.

## Scope

Directly redesigned customer surfaces:

- Menu
- Item detail
- Cart
- Checkout sheet
- Rewards
- floating cart affordance

Shared presentation changes:

- `NeumorphicControl`
- `AidaLogo` / bundled logo asset
- success-color derivative used by the add-to-cart confirmation state

Indirectly affected surface:

- Membership QR, because it already uses the shared `AidaLogo` widget. This is a visual change only; member-code/QR/offline semantics do not change.

The redesign does not change routes, authentication, member identity authority, catalogue authority, cart/order authority, payment semantics, loyalty authority or Supabase contracts.

The historical source branch was not merged directly because it was stale and contained unrelated history plus an invalid scheduling experiment. Integration carried only the reviewed redesign delta onto current `master` and restored contract-safe scheduling/live catalogue imagery.

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

No redesigned surface gains trusted business meaning through color alone.

### Typography

Typography remains centralized in `AidaType`:

- Playfair Display for display/serif hierarchy.
- Plus Jakarta Sans for interface/body text.
- `AidaTheme.sectionLabel` for uppercase section labels.

Fonts remain bundled; no runtime font network dependency is introduced.

### Shape/elevation

The redesign emphasizes:

- flatter Menu and Cart rows separated by whitespace/hairline dividers;
- 18–28 px rounded controls/cards/sheets;
- soft two-shadow tactile controls for category/add/selected affordances;
- the existing dark coffee-to-espresso card family for Rewards;
- local animated feedback rather than new global navigation chrome.

### Logo and imagery

`apps/customer/assets/images/aida_logo.jpg` is bundled and rendered through `AidaLogo` where the shared widget is used. Rewards also uses the asset as a low-opacity card watermark.

`MenuListItem` must render the server `MenuItem.imageUrl` first. Bundled category art is only an `assetFallback`; it is not catalogue content or commercial authority.

## Shared components

### New

- `features/menu/widgets/menu_category_rail.dart` — vertical Menu-only category/favorites rail. Stable automation keys: `menu_cat_all`, `menu_cat_favorites`, `menu_cat_<category-id>`.
- `features/menu/widgets/menu_list_item.dart` — photo-forward Menu list row.

### Changed

- `core/widgets/neumorphic_control.dart` — optional accent-gradient override for transient success feedback.
- `features/cart/widgets/floating_cart_bar.dart` — animated presence and cart-line thumbnails while retaining the same local cart provider/route.
- `core/theme/aida_logo.dart` — bundled real AIDA logo instead of the placeholder.

### Retired

`features/menu/widgets/menu_grid_item.dart` is superseded by `MenuListItem` and should not be reintroduced accidentally.

## Navigation and information architecture

Cross-screen navigation is unchanged:

- five-tab `AppShell` remains an `IndexedStack`;
- Menu items still open `ItemDetailScreen` before cart insertion, preserving variant/add-on selection;
- Cart still opens `OrderCheckoutSheet` in a modal bottom sheet;
- successful placement still clears cart only after persisted placement and opens order confirmation;
- Rewards card actions scroll to existing sections rather than inventing new routes.

## Screen specifications

### Menu

Implementation:

- `features/menu/menu_screen.dart`
- `features/menu/widgets/menu_category_rail.dart`
- `features/menu/widgets/menu_list_item.dart`

Changes:

- previous grid becomes a photo-forward single-column list;
- fixed vertical category/favorites rail;
- unfiltered catalogue content can be grouped by category;
- unavailable items remain non-interactive;
- pull-to-refresh and local favorites behavior remain.

Data boundary: Supabase catalogue + Realtime invalidation/refetch; category/favorite selection is local presentation state. Live `imageUrl` remains primary imagery.

### Item detail

Implementation: `features/menu/item_detail_screen.dart`.

Changes:

- existing catalogue-driven hero/configuration layout remains;
- old Customize shortcut plus icon-only add action becomes quantity controls + one `Add to cart · <local total>` CTA;
- brief `Added` confirmation replaces the old SnackBar feedback.

Data boundary: variants, prices and compatible add-ons still come from the catalogue. The displayed running total is a local estimate; server quote remains commercial authority.

### Cart

Implementation: `features/cart/cart_screen.dart`.

Changes:

- flat photo rows;
- swipe-to-remove;
- retained quantity/configuration/note presentation;
- bottom amount explicitly labelled `Estimated subtotal`;
- `Review order` remains the transition to server quote.

Data boundary: local intent/estimate only. Swipe removal mutates local cart state and does not cancel/delete a persisted order.

### Floating cart bar

Implementation: `features/cart/widgets/floating_cart_bar.dart`.

Changes:

- animated entrance/exit;
- overlapping cart-line thumbnails plus overflow count;
- retains item count, estimated subtotal and Cart navigation.

### Checkout sheet

Implementation: `features/cart/order_checkout_sheet.dart`.

The integrated redesign keeps a tactile wheel-style scheduled selector but **the wheel does not define valid times**. It renders only values returned by `derivePickupSlots(OrderingPolicy)`.

Therefore selectable values continue to respect:

- `scheduleEnabled`;
- `minimumLeadMinutes`;
- `slotIntervalMinutes`;
- `maximumAdvanceDays`;
- backend-provided timezone/server time.

The integrated implementation does not hardcode café opening hours and does not offer arbitrary one-minute values. `quote_order()` validates the selected timestamp again, and placement revalidates server-side.

The sheet still:

- obtains authoritative policy;
- requests an authoritative quote;
- renders `Server total`;
- places only through `OrderCheckoutSession`/`OrderRepository`;
- keeps Pay-at-counter semantics;
- keeps retry-stable idempotency behavior.

### Rewards

Implementation: `features/rewards/rewards_screen.dart`.

Changes:

- balance surface adopts the dark membership-card visual family;
- bundled AIDA logo watermark;
- `Vouchers` and `Redeem` in-card scroll controls;
- earned voucher/reward-ticket presentation retained.

**Mixed data boundary:**

- member name/code displayed on the card comes from `displayedMemberProvider`, based on the real owner-scoped Supabase member/profile read plus the existing local presentation edit overlay;
- points, reward catalogue and vouchers remain delegated to the mock pending-feature implementation.

Therefore Rewards is not wholly mock, but loyalty is still not integrated. `Redeem` remains non-authoritative and must not mutate/claim trusted points until the loyalty task exists.

### Membership QR — indirect shared-logo delta

Implementation: `features/card/membership_card_screen.dart` plus `core/theme/aida_logo.dart`.

The screen layout/QR code logic was not redesigned, but the shared logo changed from placeholder to bundled AIDA imagery. QR payload remains the server-owned member code; online owner-scoped member reads and the minimum per-user offline cache are unchanged. The bundled asset keeps the offline card free of a new network dependency.

## Motion

Local motion includes:

- checkout wheel fade/size entrance and fixed-extent selection feedback;
- floating cart fade/slide;
- cart thumbnail pop-in;
- item-detail `Added` confirmation swap;
- existing neumorphic press feedback.

No route-transition architecture or global motion framework is added.

## Accessibility/testability

Current evidence includes semantic labels/selected state on major tactile controls and visible text labels for primary actions. The redesign does not claim WCAG conformance.

Post-merge audit found stale test selectors rather than a backend defect. Stable category rail keys were restored and cart-flow tests were rewritten against the redesigned UI. Small 36–38 px controls, large-text behavior, screen-reader quality and tablet/landscape behavior remain explicit accessibility/responsive review gaps.

## Responsive behavior

Phone-first. No tablet-specific or landscape-specific redesign is claimed. The fixed 76 px Menu rail is a deliberate phone layout constraint and should be revisited before tablet/web is treated as a production target.

## Screenshots

Repository-local redesign evidence:

- `docs/screenshots/2026-08-19-menu-redesign.png`
- `docs/screenshots/2026-08-19-item-detail-redesign.png`
- `docs/screenshots/2026-08-19-cart-redesign.png`
- `docs/screenshots/2026-08-19-rewards-redesign.png`

The historical checkout screenshot is intentionally excluded because it depicts the rejected arbitrary-minute/client-hours implementation rather than the integrated policy-derived wheel.

## Maintenance rules

- Do not reintroduce `MenuGridItem` without an explicit design decision.
- Reuse `MenuCategoryRail`/`MenuListItem`; preserve their automation keys when refactoring.
- Keep live `MenuItem.imageUrl` primary and category art fallback-only.
- Keep cart/floating/item-detail totals labelled/treated as estimates until quote.
- Never construct scheduled pickup times outside `OrderingPolicy`/`derivePickupSlots` unless the backend contract changes first.
- Do not add local café-hours/capacity constants as scheduling authority.
- Do not promote Rewards visuals into loyalty authority.
- Keep Membership QR assets bundled/offline-safe and QR payload server-owned.
- Do not update golden files solely to make tests green; inspect candidate visual diffs deliberately.

## Verification

Post-merge verification belongs to `UI_REDESIGN_AUDIT_2026-08-20.md` and the current task handoff. The TASK-UI-REDESIGN-003 regression additions specifically cover:

- redesigned item configuration → cart → quote/place flow;
- placement failure retains cart;
- scheduled checkout submits a `derivePickupSlots(policy)` timestamp;
- Menu category rail stable selector coverage;
- existing Auth/member/catalogue/order unit/data regressions through the clean release gate.

The project does not treat source inspection alone as a fresh test PASS.

## Related documentation

- `UI_REDESIGN_AUDIT_2026-08-20.md` — post-merge backend-impact and verification audit.
- `UI_SCREEN_MAP.md` — runtime/data-source/integration status.
- `STATE_AND_DATA_FLOW.md` — provider/repository/authority flow.
- `FRAGILE_BOUNDARIES.md` — regression-sensitive trust/UI boundaries.
- `MOCKS_AND_PLACEHOLDERS.md` — real/mock/presentation separation.
