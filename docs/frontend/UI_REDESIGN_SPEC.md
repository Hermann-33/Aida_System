# Customer UI Redesign Specification

Updated: 2026-08-24

Scope note: this document describes a presentation-layer redesign of five
existing customer surfaces (Menu, Item detail, Cart, Checkout sheet,
Rewards). It supplements — and does not replace — `UI_SCREEN_MAP.md`
(runtime/integration status), `STATE_AND_DATA_FLOW.md` (data flow, unchanged
by this redesign) and `MOCKS_AND_PLACEHOLDERS.md` (mock/real boundary,
unchanged by this redesign). Where this document and those disagree on
runtime/integration facts, they win per `AGENTS.md`'s authority order; this
document is the source for visual/interaction detail they intentionally omit.

## A. Scope

- **Branch inspected:** `customer-app-redesign` (pushed to
  `Hermann-33/Aida_System`, not yet merged).
- **Comparison base:** `hermann/master` at commit `fcfb179` (2026-08-17,
  `TASK-CLOSEOUT-001`) — the state the existing `docs/screenshots/`
  baseline and all `docs/context/*` facts describe.
- **Commit inspected:** working tree at `HEAD` on `customer-app-redesign`
  against `hermann/master`, via
  `git diff --name-status hermann/master HEAD -- apps/customer`.
- **A note on diff noise:** a repo-wide `dart format` pass ran during this
  work and touched several files with no semantic change —
  `lib/core/widgets/product_image.dart`, `lib/main.dart`,
  `lib/features/shell/app_shell.dart`,
  `lib/data/repository/supabase_catalogue_repository.dart`,
  `lib/features/auth/login_screen.dart`,
  `lib/features/auth/widgets/auth_field.dart`, and the non-`accentColors`
  portions of `lib/core/widgets/neumorphic_control.dart`, plus
  `test/domain/money_test.dart`, `test/domain/cart_test.dart`,
  `test/widget_test.dart`, `test/widgets/category_strip_test.dart`, and
  `test/golden/screens_golden_test.dart`. These are whitespace/line-wrap
  only; every line was diffed by hand to confirm no logic changed. They are
  excluded from "redesigned surfaces" below.
- **Redesigned surfaces:** Menu (`menu_screen.dart` + two new widgets),
  Item detail (`item_detail_screen.dart`, bottom bar only), Cart
  (`cart_screen.dart`), Checkout sheet (`order_checkout_sheet.dart`,
  scheduling UI), Rewards (`rewards_screen.dart`, balance card only). The
  floating cart bar (`floating_cart_bar.dart`) and a shared control
  (`neumorphic_control.dart`) were also changed in support of the above.
- **Untouched surfaces:** Auth gate, Sign in/up, Forgot password, App
  shell/bottom nav (structure — see `app_shell.dart` note above),
  Home, Membership QR, Order confirmation, Order history, Order
  receipt/detail, Profile, Edit profile. None of their source files appear
  in the diff.
- **Functional behavior changed:** Yes, in exactly one place — see
  "Behavioral delta" under Checkout sheet (§F) and `FRAGILE_BOUNDARIES.md`.
  Every other surface is presentation/layout only.
- **Backend contracts changed:** No. No RPC, table, migration, or BFF
  endpoint was touched — this branch contains no `supabase/` changes. One
  surface (Checkout sheet) now *sends* a payload shape the backend does not
  yet fully accept; see below. That is a frontend behavior change with a
  backend consequence, not a contract change.

## B. Design goals

Extracted from the actual UI decisions made, not stated separately by any
design brief in this repository:

- Replace flat/boxed list items with photo-forward cards across Menu and
  Cart, matching reference imagery supplied during the work (not committed
  to this repository).
- Reduce chrome: drop card borders/shadows on list rows in favor of
  hairline dividers ("flat" list style).
- Give destructive actions (remove cart line) a gesture (swipe) instead of
  a persistent icon button.
- Replace the fixed-interval pickup-time pill row with a scrollable
  hour/minute wheel for more precise, more tactile time selection.
- Consolidate two competing bottom-bar actions (a "Customize" scroll
  shortcut and a separate icon-only add-to-cart button) into one clear
  primary CTA that also shows the running total.
- Reuse the existing membership-card dark gradient language for the
  Rewards balance card instead of maintaining two unrelated card styles.
- Add lightweight motion (entrance transitions, a checkmark confirmation,
  pop-in thumbnails) in place of a static `SnackBar` for add-to-cart
  feedback.

## C. Design system

### Colors

All colors are defined once in `apps/customer/lib/core/theme/aida_colors.dart`
(`AidaColors`, `abstract final class`) and used by reference everywhere;
no redesigned surface introduces a new hardcoded color.

| Token | Value | Role |
|---|---|---|
| `cityRed` | `#AF2626` | Student/CityU identity only — never reused as a general accent |
| `cream` | `#FDF6F7` | Primary page background |
| `latte` | `#F2CFD6` | Secondary surfaces, dividers, muted fills |
| `coffee` | `#C13A52` | Primary actions, brand accent, price text |
| `espresso` | `#27121A` | Dark-card gradient end, high-contrast text |
| `rewardGold` | `#C9A24E` | Loyalty/points emphasis only |
| `rewardGoldDeep` | derived (`rewardGold` lightness −0.14) | Gold-on-gold gradients |
| `cardWhite` | `#FFFFFF` | Cards/elevated surfaces |
| `caramelTint` | `#F7DEE3` | Placeholder/empty-state tint |
| `coffeeLight` | derived (`coffee` lightness +0.16) | Accent gradient's light stop |
| `textPrimary` | = `espresso` | Body text on light surfaces |
| `textMuted` | `#976B77` | Secondary text/captions |
| `error` | `#8C3A2E` | Errors/destructive actions |
| `success` | `#4F6B4A` | Confirmation states |
| `successLight` | derived (`success` lightness +0.16) — **added this pass** | Success gradient's light stop |

`successLight` is the one new token this redesign added, for the
"Added ✓" button state on Item detail (§F). It follows the exact pattern
`coffeeLight`/`rewardGoldDeep` already established (an HSL-lightness
derivation of an existing token, not a new hue).

### Typography

`apps/customer/lib/core/theme/aida_type.dart` (`AidaType`), unchanged by
this redesign:

- `AidaType.serif({size, weight = w700, color, height})` — Playfair
  Display, bundled as an asset (not `google_fonts`, deliberately, so the
  offline membership card never shows broken text). Used for headings,
  the rewards balance figure, and item names on the new Menu list cards.
- `AidaType.sans({size, weight = w400, color, height, letterSpacing})` —
  Plus Jakarta Sans, also bundled. Used for all body/UI text.
- `AidaTheme.sectionLabel({color})` — 11px, w700, 1.4 letter-spacing,
  `AidaType.sans`-based. Used for the "MEMBER · code" line and the Menu
  category-section headers; reused as-is by the redesign, not modified.

No new type role or scale was introduced. The Menu list item's name uses
`AidaType.serif(size: 15)`; the Rewards balance figure uses
`AidaType.serif(size: 52, weight: w700)` (up from the previous 42px, to
fill space freed by removing a redundant caption — see §F).

### Spacing and sizing

No formal spacing scale exists in this codebase (confirmed: no
`AidaSpacing`-style token file). Each redesigned surface hand-tunes
`SizedBox`/`EdgeInsets` values locally. Reusable conventions observed
across the redesign:

- Page horizontal padding: 20px (Menu, Cart, Rewards headers — unchanged
  convention).
- Card/sheet corner radius family: 22–28px (see Shape below).
- List-row vertical rhythm: 6–14px between stacked text lines within one
  card; 12–16px between distinct sections.
- Touch targets: the Menu "+" button and Cart quantity buttons are
  36–38px square/circle; the pickup-wheel's hour/minute columns are 44px
  tall per item.

### Shape

| Element | Radius | Source |
|---|---|---|
| Menu list card (no longer has a fill, see below) | n/a — flattened | `menu_list_item.dart` |
| Menu "+" button (squircle) | `topLeft/topRight/bottomRight: 18, bottomLeft: 4` (`BorderRadius.only`) | `menu_list_item.dart` `_addButtonRadius` |
| Menu category rail tile ("puck") | 18 | `menu_category_rail.dart` |
| Rewards/membership dark card | 28 | `rewards_screen.dart`, matches `membership_card_screen.dart`'s existing `_Card` |
| Checkout sheet | 28 (top corners) | `order_checkout_sheet.dart`, pre-existing |
| Pickup-wheel "+" squircle equivalent (n/a — wheel has no button) | — | — |
| Cart line (flattened, no card) | n/a | `cart_screen.dart` |
| Rewards pill buttons (Vouchers/Redeem) | 20 | `rewards_screen.dart` `_CardPillButton` |

### Elevation

Material `elevation` is not used anywhere in the redesign; all "lift" is
hand-painted `BoxShadow`:

- Menu list card: **removed** — this redesign explicitly deleted the
  card's `boxShadow`/`color`/`border` so rows sit flat on the page
  background, per direct user feedback mid-session ("too much space" /
  "not smooth" complaints against the earlier boxed-card version).
  Separation between rows now comes from a single hairline `Divider`
  (`AidaColors.latte` at 0.5 alpha) instead.
- Cart line: same treatment — flattened, hairline divider, no shadow.
- Rewards/dark card: `BoxShadow(color: espresso@0.25, blurRadius: 32,
  offset: (0, 12))` — matches the membership card's existing shadow
  exactly.
- Menu "+" button and rail tiles keep a two-layer shadow ("3D puck")
  trick: a dark cast shadow below-right plus a light rim above-left,
  reusing the pattern `CategoryChip`'s pre-existing "All" tile already
  used, per the user's ask for a "premium"/tactile feel.

### Iconography and imagery

- Icons are exclusively `Icons.*` (Material Symbols), no icon package
  dependency added.
- `ProductImage` (`core/widgets/product_image.dart`, untouched
  semantically this pass) remains the single product-photo widget with
  graceful category-tinted fallback; the Menu and Cart redesigns reuse it
  at new sizes (88px on Cart/Menu-list rows) rather than replacing it.
- **New asset:** `assets/images/aida_logo.jpg` (513×521 JPEG, a photo of
  the printed café logo — not a clean isolated/transparent mark).
  Registered in `pubspec.yaml`. `AidaLogo`
  (`core/theme/aida_logo.dart`) previously rendered a deliberate "LOGO"
  placeholder box (its own doc comment: "a wrong logo shown to the client
  is worse than an obviously empty slot"); it now renders this real asset,
  circularly clipped (`ClipOval`) because the source photo has a
  visible pale border/table-corner artifact outside the emblem itself
  that a plain rectangular crop would show. `AidaLogo` is used by both
  `MembershipCardScreen` (`_Card`, pre-existing usage, now shows the real
  image instead of the placeholder as a side effect) and — not used;
  removed — from the Rewards card's top-left position at final request;
  the raw asset is instead used directly as a background watermark there
  (see Motion/§F, not through `AidaLogo`).

### Motion

All animation durations/curves observed in the redesign, with source:

| Effect | Duration | Curve | Where |
|---|---|---|---|
| Pickup-wheel entrance (fade + slide-up) | 260ms | `easeOutCubic` in / `easeInCubic` out | `order_checkout_sheet.dart`, `AnimatedSwitcher` |
| Pickup-wheel item pop (per new bubble/value) | 340ms | `elasticOut` | `TweenAnimationBuilder`, keyed by item identity so only new items animate |
| Pickup-wheel focused-digit size/color | 150ms | `easeOut` | `AnimatedDefaultTextStyle` |
| Floating cart bar entrance/exit (fade + slide) | 280ms | `easeOutCubic` / `easeInCubic` | `floating_cart_bar.dart`, `AnimatedSwitcher` |
| Cart-bar thumbnail pop-in | 340ms | `elasticOut` | `TweenAnimationBuilder`, keyed by line identity |
| Item-detail "Added ✓" button swap | 220ms | default (`AnimatedSwitcher` + `ScaleTransition`/`FadeTransition`) | `item_detail_screen.dart` |
| Item-detail "Added ✓" hold time | 900ms | n/a (`Timer`, then reverts) | `item_detail_screen.dart`, cancelled in `dispose()` |
| Existing `NeumorphicControl` press/scale | 160–200ms | `easeOutCubic` | pre-existing, unmodified except the new `accentColors` param |

No page-route transition, hero animation, or `AnimatedList` was added;
all motion is local to the five redesigned widgets above.

## D. Shared component inventory

### New

| Component | File | Purpose | Used by | State |
|---|---|---|---|---|
| `MenuCategoryRail` | `features/menu/widgets/menu_category_rail.dart` | Vertical category-select rail replacing the horizontal `CategoryStrip` on Menu only | `menu_screen.dart` | Presentational; receives `selectedId`/`favoritesOnly` + callbacks, no provider access |
| `MenuListItem` | `features/menu/widgets/menu_list_item.dart` | Flat photo-forward list row with the squircle "+" | `menu_screen.dart` | Presentational |

### Materially changed

| Component | File | What changed | Coupling |
|---|---|---|---|
| `NeumorphicControl` | `core/widgets/neumorphic_control.dart` | Added optional `(Color, Color)? accentColors` — overrides the accent gradient's dark/light stops (falls back to `coffee`/`coffeeLight` when null). Backward compatible; every pre-existing call site is unaffected. | Presentational |
| `FloatingCartBar` | `features/cart/widgets/floating_cart_bar.dart` | Always mounted now (was `SizedBox.shrink()`-and-gone); wrapped in `AnimatedSwitcher` for entrance/exit; renders up to 3 overlapping cart-line thumbnails + a "+N" overflow bubble instead of bare "N items" text. Reads `cart.lineItems`, `menu`, computed `subtotal` — same providers as before (`cartProvider`, `menuItemsProvider`), no new dependency. | `ConsumerWidget`, provider-coupled (unchanged binding) |
| `AidaLogo` | `core/theme/aida_logo.dart` | Renders the real `aida_logo.jpg` asset (circularly clipped, optional cream ring via existing `onDark` param) instead of the "LOGO" text placeholder. | Presentational |

### Removed

| Component | File | Reason |
|---|---|---|
| `MenuGridItem` | `features/menu/widgets/menu_grid_item.dart` (deleted) | Superseded by `MenuListItem`; confirmed zero remaining references before deletion. |

### Not created (avoid re-copying old patterns)

No new generic `XCard`/`XButton` primitive was introduced. `_CardPillButton`
(Rewards) and the squircle `_AddButton` (Menu) are private, single-use
widgets local to their screen files — they were deliberately not promoted
to shared components because each is a one-off shape tied to its specific
card, not a pattern used more than once yet. If a third surface needs the
same squircle/pill shape, promote it then rather than duplicating.

## E. Navigation and information architecture

No route, tab, or modal-flow change. Specifically unchanged:

- `AppShell`'s five-tab `IndexedStack` and floating nav (`app_shell.dart`
  diff is `dart format`-only, confirmed by hand).
- The Cart → `showModalBottomSheet` → `OrderCheckoutSheet` flow.
- The Menu → tap card → `Navigator.push` → `ItemDetailScreen` flow.
- Back-navigation on every screen.

New in-surface (not cross-screen) navigation:

- Rewards balance card's "Vouchers"/"Redeem" pill buttons call
  `Scrollable.ensureVisible` on new `GlobalKey`s (`_earnedKey`,
  `_catalogueKey`) attached to the existing "Earned Rewards"/"Redeem with
  Points" section headers on the same page — an in-page scroll, not a
  route change.
- The floating cart bar's tap target is unchanged (`Navigator.push` to
  `CartScreen`); only its visual content changed.

## F. Screen-by-screen specification

### Menu

**Implementation:** `apps/customer/lib/features/menu/menu_screen.dart`
(`MenuScreen`, `ConsumerWidget`). Children: `MenuCategoryRail` (new),
`MenuListItem` (new, replacing `MenuGridItem`), `_MenuSectionHeader`
(existing, gained an item-count parameter), `_FavoritesToggle` (existing,
unchanged), `_EmptyCategory`/`_MenuUnavailable` (existing, unchanged).

**Purpose:** Browse/filter published catalogue items by category or
favorites; each row opens `ItemDetailScreen`. Unchanged from before this
pass.

**Layout (top to bottom, left to right):**
1. Header row: "Menu" title (serif) + circular favorites-toggle button
   (top-right, unchanged).
2. Body is a `Row`: a fixed-width (`MenuCategoryRail.width`) vertical
   scrollable rail on the left (categories: "All", "Favorites", then each
   real category — icon-in-puck for "All"/"Favorites", the category's own
   product photo in a puck for real categories), and an `Expanded`
   scrollable list on the right.
3. Right list: for each visible category section, a header
   (`CATEGORY NAME ─────── count`) then a vertical stack of
   `MenuListItem` rows separated by a hairline divider — no card fill.
4. Each `MenuListItem`: 88px product photo (left), name + price (+
   optional gold best-seller star) in the middle, squircle "+" button
   pinned to the bottom-right of the text column (not vertically centered
   against the photo).

**Primary actions:** tap "All"/"Favorites"/a category in the rail to
filter; tap a row or its "+" to open `ItemDetailScreen` (the "+" does not
add directly — see Behavioral delta).

**States:** loading (rail width preserved, list shows a spinner);
error (`_MenuUnavailable`); empty category/favorites
(`_EmptyCategory`, wording depends on which); populated (above); an
item's sold-out state dims the row and disables its tap/"+" (existing
`item.isAvailable` gate, carried over unchanged).

**Data boundary:** unchanged — `menuItemsProvider`/`categoriesProvider`
→ `Supabase get_catalogue()`, `favoritesProvider` is local-only (per
`MOCKS_AND_PLACEHOLDERS.md`, favorites remain non-authoritative
presentation state).

**Redesign delta:** Replaced the horizontal `CategoryStrip` (circular
photo tiles, shared with Home) + 3-column `MenuGridItem` grid with a
dedicated vertical `MenuCategoryRail` and a single-column `MenuListItem`
list. Added a "Favorites" entry to the rail itself (previously favorites
were reachable only via the top-right heart toggle, which still exists and
now stays in sync with the rail's selection state). Removed the
`MenuGridItem` "stage" card (gradient background, shadow, border) in favor
of a flat divider-separated list. Home's own use of `CategoryStrip` is
untouched — a new rail-specific widget was built specifically so Home's
horizontal strip did not have to change.

**Behavioral delta:** None — presentation/layout only. Tapping the "+"
still opens `ItemDetailScreen` rather than adding directly, preserving the
existing rule that items with variants/add-ons cannot be safely
one-tap-added.

**Evidence:** `docs/screenshots/2026-08-19-menu-redesign.png`;
`apps/customer/test/widgets/category_strip_test.dart` (unaffected, tests
the untouched `CategoryStrip`); no new automated test targets the rail
specifically (see Known gaps).

---

### Item detail

**Implementation:** `apps/customer/lib/features/menu/item_detail_screen.dart`
(`ItemDetailScreen`/`_ItemDetailScreenState`). Only the bottom bar
(`_BottomBar`) changed; the hero image, name/price header, description,
variant tiles, add-on checkboxes and note field are unchanged.

**Purpose:** unchanged — configure variant/add-ons/note/quantity and add
the line to the cart.

**Layout:** unchanged above the fold. Bottom bar is now: a quantity
stepper (`−`, count, `+`, unchanged widget) beside one `Expanded` primary
button showing `Add to cart · RM {total}` (or `Sold out` when
unavailable), instead of the previous three-part row ("Customize" pill +
stepper + separate circular icon-only add button).

**Primary actions:** the single bottom-bar button is now the only way to
add to cart. There is no remaining "Customize" shortcut — it used to
`Scrollable.ensureVisible` down to the add-ons section, which is now
reachable only by manual scroll (the section itself is unchanged and still
visible on the page).

**States:** default; `justAdded` (bottom-bar button swaps to a green
`check_circle` + "Added" for 900ms via `Timer`, cancelled in `dispose()`
if the screen closes early — see Known gaps for the bug this pass fixed);
sold-out (`available == false`, button reads "Sold out", grey, disabled).

**Data boundary:** unchanged — catalogue item/variant/add-on data from the
Supabase-backed snapshot passed in; `cartProvider.notifier.add(...)` is
still local cart-selection state, not a server call (per
`MOCKS_AND_PLACEHOLDERS.md`, this is correct — quoting happens later at
checkout).

**Redesign delta:** Removed the `GlobalKey`-based
`Scrollable.ensureVisible` "Customize" shortcut and the separate
`shopping_bag_outlined` icon-only add button (`NeumorphicControl`,
`shape: circle`). Replaced both with one `Expanded` `NeumorphicControl`
showing live text (`accent: available`, new `accentColors` param drives
its green "Added" state). Removed the post-add-to-cart `SnackBar`
(`ScaffoldMessenger.showSnackBar`) entirely; the confirmation is now the
button's own transient state.

**Behavioral delta:** None to backend/data boundary. Purely a
presentation/interaction change: fewer taps to add to cart (no separate
"open the add-ons section" step required first), and confirmation moved
from a global `SnackBar` to a local button state.

**Evidence:** `docs/screenshots/2026-08-19-item-detail-redesign.png`;
`apps/customer/test/widgets/item_detail_navigation_test.dart` (updated —
see §16 below); `apps/customer/test/widgets/cart_flow_test.dart` (updated
to find the button by its new visible text instead of a removed
`semanticsLabel`).

---

### Cart

**Implementation:** `apps/customer/lib/features/cart/cart_screen.dart`
(`_CartLineCard`, `_QuantityPill`, `_QtyButton` — all existing classes,
restyled in place). `FloatingCartBar` (separate file, see §D) also
changed as part of this surface's redesign.

**Purpose:** unchanged — review/edit cart line quantities, enter
checkout.

**Layout:** each line: 72px product photo, name/price/config-summary/note
stacked, quantity stepper trailing, all on one row with no card
background — separated from the next line by a hairline `Divider`
instead of a card gap. Bottom checkout bar (promo row, subtotal, "Review
order" button) is unchanged.

**Primary actions:** `−`/`+` on the quantity pill (unchanged callback,
`cartProvider.notifier.setQuantity`); **new:** swipe a line left to remove
it (`Dismissible`, `DismissDirection.endToStart`), replacing a persistent
`delete_outline` icon button that previously sat in the row.

**States:** empty cart (`_EmptyCart`, unchanged); populated (above);
mid-swipe reveal (a soft circular error-tinted icon behind the line,
`_DeleteReveal`, new).

**Data boundary:** unchanged — `cartProvider` local selection state;
`addOnTotalFor`/`lineTotal` are local `Money` estimates, not the
authoritative quote (quoting still happens only at checkout, per
`STATE_AND_DATA_FLOW.md` — this redesign does not touch that boundary).

**Redesign delta:** Removed the per-line `Container` decoration
(`cardWhite` fill, 20px radius, `BoxShadow`) in favor of a flat row +
`Divider`. Removed the persistent delete icon button; removed swipe now
handles deletion via `Dismissible`, keyed by a composite identity string
(`item.id` + `size?.id` + sorted `addOnIds` + `note` — the same tuple
`CartLineItem.sameConfigurationAs` already uses for equality) rather than
list index, so a swipe mid-list still removes the correct line after
earlier lines have been removed. Bumped photo (56→72px), name
(14.5→16.5px), price (13→14.5px) and the quantity-pill's own text/icon
sizes, in response to explicit "too small/too much empty space" feedback.
`FloatingCartBar` (shown site-wide once the cart is non-empty, in
`AppShell`) changed from static "N items" text to overlapping cut-out
thumbnails of the actual cart lines plus entrance/exit animation (§C
Motion).

**Behavioral delta:** None to cart/order authority. The swipe-to-remove
gesture calls the same `cartProvider.notifier.removeAt(index)` the old
delete button called.

**Evidence:** `docs/screenshots/2026-08-19-cart-redesign.png`;
`apps/customer/test/widgets/cart_flow_test.dart` (updated assertions, see
§16). No dedicated automated test exercises the swipe gesture itself or
the floating-bar thumbnails (see Known gaps).

---

### Checkout sheet

**Implementation:**
`apps/customer/lib/features/cart/order_checkout_sheet.dart`
(`OrderCheckoutSheet`/`_OrderCheckoutSheetState`). The ASAP/Schedule
toggle, "Pay at the counter" row, server-total row and "Place order"
button are unchanged. The scheduled-pickup time picker was rebuilt
entirely (`_PickupTimeWheel`, new; the old fixed-interval pill row and its
`_ChoiceChip`-based rendering are gone from this file).

**Purpose:** unchanged — choose ASAP or a scheduled pickup time, confirm
the server-quoted total, place the order.

**Layout:** unchanged except the scheduled-time picker, which is now a
"PICK TIME" label over two side-by-side scrollable wheels (hour, minute)
inside a bracket formed by two vertical divider lines, with the centered
value in each wheel shown large/bold/coffee-colored and neighbors
fading/shrinking by distance — replacing four fixed pill buttons
(`12:15 PM`, `12:30 PM`, …) that only showed the next few
`slotIntervalMinutes`-aligned options at a time.

**Primary actions:** unchanged (ASAP/Schedule toggle, Place order); the
wheel itself is the new interactive control — drag or tap to change hour
or minute.

**States:** ASAP selected (no wheel shown); Schedule selected with a valid
same-day window (wheel shown); Schedule selected with **no** valid window
today (Schedule toggle itself does not render — see delta below);
quote loading/error (unchanged `_busy`/`_error` handling, including the
pre-existing "Try again" retry path).

**Data boundary:** `OrderingPolicy` (from `get_ordering_policy()`) still
supplies `serverNow`, `timezone`, `minimumLeadMinutes`,
`scheduleEnabled`, and is still the only source for whether scheduling is
offered at all and for the earliest bookable moment today. **Two new
client-only values are layered on top of it** — see Behavioral delta.

**Redesign delta:** Deleted the `_ChoiceChip`-row rendering of
`derivePickupSlots()` output. Added `_PickupTimeWheel`
(`ListWheelScrollView`-based, no custom painting), `_HourGroup`/
`_groupByHour` were an intermediate step later replaced by a
`_todayPickupWindow`/`_composePickup` pair that computes an hour/minute
range directly rather than pre-generating a flat slot list. Added a
`Dismissible`-style entrance/exit `AnimatedSwitcher` for the whole wheel
block. Added haptic feedback (`HapticFeedback.selectionClick()`) on wheel
value changes.

**Behavioral delta — real, not just visual:**

1. **Same-day café-hours window (8am–5pm), client-only.** New constants
   `_cafeOpenHour`/`_cafeCloseHour` in `order_checkout_sheet.dart` gate
   which hours the wheel offers and whether the "Schedule" toggle renders
   at all today. `OrderingPolicy` has no operating-hours field, and
   neither does any order RPC (confirmed against
   `SHARED_BACKEND_CONTRACT.md`/`ORDER_AND_SCHEDULING_CONTRACT.md` — no
   branch-hours concept exists server-side). This is a pure frontend
   guess, not a server-validated fact. It also means: once real device
   time passes 5pm local, the Schedule toggle silently stops appearing
   for the rest of the day, which is expected given this constant but is
   easy to mistake for a bug if not documented (it was reported as one
   mid-session before this explanation surfaced).
2. **Minute selection is no longer clamped to
   `OrderingPolicy.slotIntervalMinutes` (server default: 15).** The wheel
   now offers every minute within the valid hour range, per an explicit
   product decision made mid-session to prioritize a "modern, granular"
   feel over matching the server's coarser interval, on the stated
   expectation that the backend would relax that validation to match.
   **The backend has not been changed in this task and, per
   `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md`, `quote_order`
   still rejects any `requestedPickupAt` not aligned to a 15-minute
   local slot.** Concretely: selecting a minute value that isn't a
   multiple of 15 and proceeding to Schedule will cause `quote_order`
   (and therefore `place_customer_order`) to fail server-side. The
   screen does not crash when this happens — `_refreshQuote()`'s
   existing `Err` branch renders the returned failure message and a
   "Try again" control — but the user will see a real, frequent error
   for any non-15-minute selection until one of: (a) the backend relaxes
   `slot_interval_minutes`/its validation, or (b) the frontend clamps
   the wheel back to server-aligned values, or (c) the frontend rounds
   the selected value to the nearest valid slot before quoting. None of
   those three has been implemented in this task; this is flagged, not
   resolved, per the "documentation-first, do not reimplement" scope of
   this task.

Both items are also recorded in `FRAGILE_BOUNDARIES.md` and
`UI_SCREEN_MAP.md`, since they affect a contract-sensitive assumption
(`ORDER_AND_SCHEDULING_CONTRACT.md`'s scheduling section), not just this
screen's appearance.

**Evidence:** `docs/screenshots/2026-08-19-checkout-sheet-redesign.png`
(captured with `TestOrderRepository`'s 15-minute-interval fixture policy,
`ASAP` selected — the wheel itself is documented above from direct
implementation inspection, since a static screenshot cannot show scroll
interaction). No automated test asserts the off-interval-minute failure
path end-to-end against a real backend (only against the local
`TestOrderRepository` fixture, which does not replicate the server's
interval validation — see Known gaps).

---

### Rewards

**Implementation:** `apps/customer/lib/features/rewards/rewards_screen.dart`
(`_BalanceCard`/`_BalanceCardState`, `_CardPillButton`). The "Earned
Rewards" and "Redeem with Points" ticket lists below the card
(`RewardTicketCard`, `_earnedTickets`/`_catalogueTickets`) are unchanged.

**Purpose:** unchanged — show points balance, link to earned
vouchers/redeemable catalogue below on the same page.

**Layout:** dark `coffee`→`espresso` gradient card (28px radius, matching
`MembershipCardScreen`'s card exactly): member name, "130"-style balance
figure (52px serif), two pill buttons ("Vouchers", "Redeem"), "MEMBER ·
code" footer. A hide/show-balance eye toggle floats independently
top-right (`Positioned`, not in the column flow). A large (260px),
14%-opacity, circularly-cropped watermark of the real café-logo photo sits
in the card's bottom-right corner, clipped by the card's own rounded
corners.

**Primary actions:** eye toggle masks/unmasks the balance figure (local
`_hidden` bool, no persistence); "Vouchers"/"Redeem" pills
`Scrollable.ensureVisible` to the two sections below, on this same page
(§E).

**States:** balance visible (default); balance hidden (`••••`); member
data loading (`name`/`code` fall back to `'Aida Member'`/no footer
suffix while `AsyncValue` is not yet `.value`-populated — no separate
loading skeleton was added).

**Data boundary:** `pointsProvider` (mock, per
`MOCKS_AND_PLACEHOLDERS.md` — "loyalty/rewards/offers/promotions" remain
explicitly preview/deferred) and `displayedMemberProvider` (real, Supabase
member data — **newly read by this screen**; previously `RewardsScreen`
did not watch member data at all). This is a new *read* of already-real
data, not a new mock and not a new write — `UI_SCREEN_MAP.md`'s
"Rewards … mock … Preview/deferred" status is unchanged because the
*points balance and redemption* remain mock; only the member name/code
now shown on the card come from the same real member provider the QR
screen already used.

**Redesign delta:** Replaced the previous light pink/gold gradient card
(a distinct visual language from the rest of the app) with the dark
gradient already used by `MembershipCardScreen`. Removed a row of five
decorative circular icon bubbles that overlapped the card's bottom edge
(no `onTap`, purely decorative — confirmed before deletion) and the
"YOUR BALANCE"/"points ready to redeem" caption text. Added the member
name, an eye-toggle hide-balance control, two functional pill buttons,
and the logo watermark — none of which existed on the previous card.
Replaced a broken-looking bordered "LOGO" placeholder chip (briefly
present mid-session, from an early draft of this same redesign) with the
real logo asset used as a background watermark instead of foreground
content, after user feedback that a small foreground logo mark read as
low-effort.

**Behavioral delta:** None — the two pill buttons perform in-page
scrolling only; no new network call, no new mutation.

**Evidence:** `docs/screenshots/2026-08-19-rewards-redesign.png`. No
automated test targets the new pill buttons, eye toggle, or watermark
(see Known gaps) — the surface has no existing widget-test file to extend
this pass stayed inside its documentation-first scope rather than adding
one.

## 10. Responsive behavior

Only verified at the same fixed size every other golden/screenshot test in
this repository already assumes: **1170×2532 logical px @ 3.0 device pixel
ratio** (`tester.view.physicalSize`/`devicePixelRatio` in every test file
touched or added this pass, matching the pre-existing convention in
`screens_golden_test.dart`). This corresponds to a large modern phone in
portrait.

**Not verified by this task, for any redesigned surface:**

- Narrow/small phones (e.g. iPhone SE-class widths).
- Tablet layouts (no tablet-specific branch exists in any redesigned
  file — `MenuCategoryRail.width` and card paddings are fixed constants,
  not responsive to available width).
- Landscape orientation.
- Flutter web rendering (the project declares web as a build target per
  `FRONTEND_AUDIT.md`'s framework table, but no redesigned widget was run
  under `flutter run -d chrome` or an equivalent web test target during
  this task).

These are listed as gaps below, not silently assumed to work.

## 11. Accessibility

- `MenuListItem`'s "+" and `_CardPillButton` rely on their visible text
  for screen-reader labeling; no `Semantics`/`semanticsLabel` was added or
  removed on them.
- `item_detail_screen.dart`'s consolidated CTA **explicitly removed** a
  `semanticsLabel: 'Add to cart'` that had been added mid-session, after
  discovering (via a widget-test semantics dump) that it merged with the
  button's own visible `Text` into a redundant two-line screen-reader
  announcement ("Add to cart" + "Add to cart · RM 12.90"). The button now
  relies solely on its visible text for its accessible name — a
  deliberate accessibility fix, documented here because it reverses an
  intermediate state this same task introduced.
- The Cart's `Dismissible` swipe-to-delete has **no accessibility
  affordance beyond the gesture itself** — there is no equivalent
  button/action for a screen-reader or switch-control user to remove a
  line item now that the persistent delete icon is gone. This is a
  regression versus the pre-redesign screen for that user population and
  is listed as a known gap, not a verified-accessible pattern.
- Touch targets: the new squircle "+" (38×38px) and quantity buttons
  (36–38px) meet common ≥36px guidance; not independently measured against
  a formal WCAG target-size checkpoint.
- No color-contrast measurement was performed for any new text-on-gradient
  combination (e.g. `latte`-on-`coffee`/`espresso` gradient text on the
  Rewards card). This repeats an existing, not newly introduced, pattern
  from `MembershipCardScreen`.
- No scalable-text (`MediaQuery.textScaler`) behavior was verified for any
  redesigned surface.

None of the above is claimed as WCAG-compliant; all are recorded as
unverified or, for the `Dismissible` case, a known regression.

## 12. Known gaps

- **Checkout-sheet minute/backend mismatch** (§F, Checkout sheet) — the
  single most important gap. Selecting a non-15-minute pickup time will
  fail server-side today.
- **Café-hours window is a frontend guess**, not backed by
  `OrderingPolicy` or any RPC.
- **Cart swipe-to-delete has no accessible equivalent control.**
- **No automated test covers:** `MenuCategoryRail` selection/Favorites
  interaction directly; `MenuListItem` rendering in isolation;
  `_PickupTimeWheel` scroll-to-select behavior; the Cart `Dismissible`
  gesture (a scratch reproduction test existed transiently during this
  task but was not committed — see Verification); `FloatingCartBar`'s
  thumbnail stack/animation; the Rewards card's eye toggle, pill-button
  scroll, or watermark.
- **Responsive/tablet/web/landscape are unverified** for every redesigned
  surface (§10).
- **Accessibility beyond basic text-label review is unverified** (§11).
- **`FRONTEND_AUDIT.md` is a materially outdated historical baseline**
  (predates even the Supabase integration, let alone this redesign) —
  left untouched per this task's historical-preservation instruction, with
  a pointer added to its existing scope note (§16).
- **The existing four pre-existing golden-image test failures are
  unrelated to this redesign** but were not fixed by this task (see
  Verification) — `golden: home`, `golden: home scrolled`,
  `golden: menu with a category selected`, `golden: membership card` all
  fail against stale committed baseline PNGs that predate this session's
  work (confirmed earlier by stashing this session's changes and
  re-running the same four tests, which still failed identically).
  Updating golden baselines requires deliberate visual review per
  `AGENTS.md` and was out of scope for a documentation task.
- **Home, Auth, Membership QR, Order history/confirmation/receipt,
  Profile, Edit profile still use the pre-redesign visual language** —
  they were not touched, so the app now has two coexisting list/card
  idioms (old boxed-card style there, new flat/divider style on the five
  redesigned surfaces) until a later task extends the redesign or an
  explicit decision is made not to.

## 13. Maintenance rules

- **Canonical theme files — extend, do not fork:** `aida_colors.dart`,
  `aida_type.dart`, `aida_theme.dart`. Every redesigned surface sourced
  every color/type value from these three files; the one new token
  (`successLight`) was added there, not inlined. New screens should do
  the same rather than hardcoding a `Color(0x...)`.
  - Pattern for a new derived tone: `HSLColor.fromColor(base)
    .withLightness((hsl.lightness ± delta).clamp(0.0, 1.0)).toColor()`,
    as a `static Color get` — see `coffeeLight`, `rewardGoldDeep`,
    `successLight`.
- **Preferred list-row idiom going forward:** flat row (no card
  fill/shadow) + hairline `Divider(color: AidaColors.latte.withValues(
  alpha: 0.5))` between rows, as built for Menu and Cart this pass. Do
  not add a new boxed/shadowed card-per-row screen without a deliberate
  reason — it now reads as the *old* pattern in this codebase.
- **Deprecated: `MenuGridItem`.** Deleted this pass. Do not resurrect a
  3-column grid card for Menu; if a future task needs a grid layout for a
  different surface, design a new widget rather than restoring the
  deleted one from history.
- **Squircle shape:** `BorderRadius.only(topLeft: 18, topRight: 18,
  bottomRight: 18, bottomLeft: 4)` (see `_addButtonRadius` in
  `menu_list_item.dart`) is now this app's "distinctive CTA button"
  shape, introduced per explicit visual reference. Reuse this exact
  radius set for a similarly-prominent single-tap CTA rather than
  inventing a new asymmetric radius per screen.
- **"3D puck" shadow trick** (two `BoxShadow`s: dark cast below-right,
  light rim above-left, plus a gradient fill) is the established
  "tactile/premium" treatment for small icon/photo tiles — see
  `CategoryChip`'s pre-existing "All" tile, `MenuCategoryRail`'s tiles,
  and the Menu "+" button. Reuse this rather than a flat
  `Material`/`InkWell` circle when a control specifically wants that
  premium feel; use plain flat controls elsewhere.
- **Dark gradient card family:** `LinearGradient(colors: [coffee,
  espresso], begin: topLeft, end: bottomRight)`, 28px radius,
  `BoxShadow(espresso@0.25, blur 32, offset (0,12))`. Now shared by
  `MembershipCardScreen._Card` and `RewardsScreen._BalanceCard`. Any
  future "identity card"-style surface should match this exactly rather
  than introduce a third gradient.
- **Logo usage:** always through `AidaLogo` (`core/theme/aida_logo.dart`),
  never `Image.asset('assets/images/aida_logo.jpg')` directly in a screen
  file, so a future asset swap (e.g. a transparent PNG replacing this
  JPEG photo) stays a one-file change. The Rewards card's watermark is
  the one deliberate exception (§C, Iconography) because it needs a
  zoomed/cropped `Transform.scale` treatment `AidaLogo` does not expose;
  if a second surface needs a watermark, consider adding that as an
  `AidaLogo` variant instead of a second direct `Image.asset` call.
- **Motion durations:** this pass used 150–340ms for micro-interactions
  and 220–280ms for enter/exit transitions (§C). Stay in that band for
  consistency rather than introducing a much slower/faster feel on a new
  surface.
- **Before adding a new screen's list/card style, check this document's
  §D (component inventory) and §13 first** — the goal of this redesign
  was partly to stop each screen inventing its own card treatment.

## 14. Screenshots

Captured this pass (`docs/screenshots/`, new files, originals below
preserved untouched):

- `2026-08-19-menu-redesign.png`
- `2026-08-19-item-detail-redesign.png`
- `2026-08-19-cart-redesign.png`
- `2026-08-19-checkout-sheet-redesign.png`
- `2026-08-19-rewards-redesign.png`

All five were captured via a temporary Flutter widget test
(`flutter test --update-goldens` against a throwaway test file, deleted
after use — not committed) using `TestCatalogueRepository`/
`TestOrderRepository`/`MockMemberRepository` fixtures, at 1170×2532
logical px, matching this repository's existing golden-test convention.
They are real rendered output, not mockups. The pre-existing baseline
screenshots (`01-login.png` … `16-edit-profile.png`) were left exactly as
they were — none were overwritten — so they remain valid before/after
evidence for the five redesigned surfaces (`04-home.png` is unaffected
since Home was not redesigned; `05-rewards.png`, `07-menu.png`,
`08-item-detail.png`/`09-item-detail-addons.png`, `10-cart.png` are the
relevant "before" counterparts for this redesign's "after" set above).

Not captured: any sheet/dialog state beyond the checkout sheet's ASAP
view (e.g. mid-scroll wheel position, the swipe-to-delete reveal state,
the Rewards masked-balance state) — these are described in prose in §F
instead, since a static image of a scroll-in-progress or gesture-in-
progress state is of limited evidentiary value without the interaction
itself.

## 15. Existing documents updated by this task

- `docs/frontend/UI_SCREEN_MAP.md` — added a dated section flagging the
  two checkout-sheet behavioral deltas (§F). Table rows/statuses left
  unchanged (all five surfaces' data sources and integration status are
  factually the same as before this redesign).
- `docs/frontend/FRAGILE_BOUNDARIES.md` — added the same two checkout-
  sheet deltas under "Contract-sensitive assumptions", since they touch
  the schedule-policy interpretation this file already calls out as a
  highest-risk area.
- `docs/frontend/FRONTEND_AUDIT.md` — appended one line to its existing
  scope note pointing to this document, without altering any historical
  finding.
- `docs/context/ACTIVE_CONTEXT.md`, `docs/context/HANDOFF.md`,
  `docs/context/AUDIT_LOG.md` — updated per §15/§17 of the task
  instructions; see each file's own diff for exact wording.

Not updated, with reason:

- `docs/context/CODEBASE_MAP.md` — does not reference
  `menu_grid_item.dart`/`menu_list_item.dart`/`menu_category_rail.dart`
  by name, so nothing in it is now false; left as-is.
- `docs/frontend/STATE_AND_DATA_FLOW.md` — no state/data-flow change
  (§A); a styling-only redesign does not warrant an update per this
  file's own scope note and the task instructions.
- `docs/frontend/MOCKS_AND_PLACEHOLDERS.md` — no mock became real and no
  real thing became mocked; Rewards' points/redemption are still mock,
  member name/code were already real elsewhere in the app.
- `docs/decisions/ADR-*.md`, `docs/context/ARCHITECTURE.md`,
  `docs/context/SYSTEM_MAP.md`, `docs/context/SUPABASE_STATUS.md`,
  `docs/contracts/SHARED_BACKEND_CONTRACT.md`,
  `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md` — no backend
  contract, architecture, or trust-boundary change occurred; the
  checkout-sheet behavioral delta is a frontend deviation *from* the
  existing contract, not a change *to* it, and is documented as a gap
  (§12) rather than retroactively written into the contract it does not
  yet honor.

## 16. Verification

Performed:

1. `git diff --name-status hermann/master HEAD -- apps/customer` —
   inspected in full (§A); every file classified as real change or
   `dart format` noise.
2. Every source path named in this document confirmed to exist at the
   stated location as of `HEAD` on `customer-app-redesign`.
3. Screen names cross-checked against `UI_SCREEN_MAP.md`'s table and the
   actual class names in each source file.
4. Color/typography values cross-checked directly against
   `aida_colors.dart`/`aida_type.dart`/`aida_theme.dart` source (quoted
   inline in §C), not estimated from screenshots.
5. Shared-component names (`MenuCategoryRail`, `MenuListItem`,
   `FloatingCartBar`, `AidaLogo`, `NeumorphicControl`) confirmed against
   their actual class declarations.
6. Navigation claims (§E) confirmed by reading `app_shell.dart`,
   `cart_screen.dart`, `menu_screen.dart` — no route/tab change found.
7. State/data claims (§F "Data boundary" rows) confirmed against
   `providers.dart` provider names and each screen's actual `ref.watch`
   calls.
8. Mock/deferred claims cross-checked against
   `MOCKS_AND_PLACEHOLDERS.md`'s existing categorization before writing
   each "Data boundary" section.
9. The checkout-sheet interval mismatch (§F) was verified against
   `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md`'s explicit "backend
   rejects timestamps … not aligned to a local 15-minute slot" line, not
   inferred.
10. Markdown links/paths in this document point only to files confirmed
    to exist in this repository at the stated paths.
11. Screenshot filenames (§14) confirmed to exist at
    `docs/screenshots/` after capture, before this document was finalized.
12. `docs/frontend/FRONTEND_AUDIT.md` confirmed unmodified in content
    (only its scope note gained one pointer line); its historical
    findings are unchanged.
13. Flutter checks, run from `apps/customer`:
    - `flutter analyze` → **0 issues.**
    - `flutter test` → **40 passed, 4 failed.** The 4 failures are
      `golden: home`, `golden: home scrolled (categories + popular
      picks)`, `golden: menu with a category selected`, and
      `golden: membership card` — all in
      `test/golden/screens_golden_test.dart`, all pre-existing (verified
      earlier in this same work session by stashing the redesign changes
      and re-running the identical four tests, which still failed against
      the same stale committed baseline PNGs). No golden baseline was
      updated by this task.
    - A transient reproduction test for the Cart `Dismissible` gesture
      (confirming a swipe removes the correct line by identity, not
      index) was written and run successfully during implementation, then
      deleted rather than committed, per this task's documentation-first
      scope — it is not part of the current automated suite (§12 lists
      this as a gap).

## 17. Protected customer boundaries — inspection result

Per `AGENTS.md`/`FRAGILE_BOUNDARIES.md`, the following were checked for
changes:

- `lib/application/providers.dart` — **not in the redesign diff** against
  `hermann/master` (confirmed via `git diff --name-status`). Untouched.
- Member repository abstractions
  (`domain/repository/member_repository.dart`,
  `data/repository/*member*`) — **not in the redesign diff.** Untouched.
- Auth/session lifecycle (`login_screen.dart`, `auth_field.dart`) —
  **present in the diff but confirmed `dart format`-only** (§A);
  no auth logic changed.
- Navigation lifecycle (`app_shell.dart`) — **present in the diff but
  confirmed `dart format`-only** (§A).
- Money/cart models (`domain/model/cart.dart`,
  `domain/model/order.dart`) — **not in the redesign diff.** Untouched;
  `cart_screen.dart`'s changes are rendering/gesture only and call the
  same `CartNotifier` methods (`setQuantity`, `removeAt`) the pre-redesign
  screen called.
- Membership QR semantics (`membership_card_screen.dart`) — **not
  directly edited**, but its `AidaLogo` dependency now renders a real
  image instead of a placeholder as a side effect of the shared-widget
  change (§D). No QR/member-code logic in that file was touched.
- Checkout/order authority
  (`application/order_checkout.dart`,
  `data/repository/supabase_order_repository.dart`,
  `domain/repository/order_repository.dart`) — **not in the redesign
  diff.** `order_checkout_sheet.dart` (the UI file) changed; the
  session/quote/place logic it calls did not.
- Golden baselines — **not updated by this task** (§16); the 4 pre-
  existing failures were left as-is rather than "fixed" by regenerating
  them without review, per the explicit instruction not to update goldens
  merely to make the suite green.

Classification for each touched protected-adjacent file: **presentational
only**, except `order_checkout_sheet.dart`'s pickup-time logic, which is
**application behavior** (it changes what payload the app sends) without
being a **backend-facing contract change** (nothing server-side was
modified) — see §F Checkout sheet for the full explanation.

## 18. Cross-repository synchronization

`Cross-repository documentation sync: PENDING — Dashboard repository not
available in this task.`

This document, and the updates listed in §15, exist only in
`Hermann-33/Aida_System` as of this task. `Hermann-33/Aida_System-Dashboard`
has not been inspected, cloned, or modified, per this task's explicit
scope.

## 19. 2026-08-23/24 update — TASK-MENU-CUSTOMIZATION-001 merge

The rest of this document (§A–§18) reflects the presentation-layer redesign
as it stood on 2026-08-19, before `hermann/master` independently landed
`TASK-MENU-CUSTOMIZATION-001` (drink Temperature/Sweetness customization)
and, separately, reworked the checkout sheet's scheduled-pickup picker.
Both branches were merged into `customer-app-redesign` on 2026-08-24. This
section records what that merge actually changed; §A–§18 are left as
originally written rather than rewritten in place, per this document's own
maintenance rule of dating additions instead of silently editing history.

### Drink customization (new)

`features/menu/item_detail_screen.dart` now renders catalogue-driven
required single-choice groups above `Customize`, standardised as:

```text
Temperature: Hot | Iced
Sweetness: Regular | Less sweet | Least sweet
```

Same visual language as `Size`: coffee/burgundy selected state plus an
explicit check indicator, `Unavailable` copy/semantics for disabled
options, non-zero price deltas as secondary text. The client stages
`optionValueIds` only; the backend quote remains authoritative for
option validity, default and pricing. `CartLineItem`, `OrderSelectionLine`
and the order snapshot models (`OrderOptionSnapshot`) all carry these IDs
through to placement and history. Cart line identity/equivalence now
includes option IDs, not just product/variant/add-ons.

### Checkout sheet: the two flagged items from §F are now resolved

§F "Checkout sheet" and `FRAGILE_BOUNDARIES.md` previously flagged two open
items in the redesigned scheduled-pickup picker: an unclamped minute wheel
that could construct a `requestedPickupAt` the backend would reject, and a
client-only 8am–5pm café-hours window with no server counterpart. The
merged checkout sheet replaces the old twin Hour/Minute wheel
(`_PickupTimeWheel`, `_todayPickupWindow`, `_composePickup`, the
`_cafeOpenHour`/`_cafeCloseHour` constants) with a single wheel
(`_PickupSlotWheel`) over the exact slots `derivePickupSlots(OrderingPolicy)`
returns — no locally invented times or opening hours. Both flagged items
are closed as of this merge; do not reintroduce a free-minute or
client-only-hours picker without a matching backend contract change. The
"ASAP" label is now "Now" (presentation only; the wire enum stays `asap`).

### Add-to-cart behavior: reconciled, not a straight pick of either side

Before this merge, the two branches disagreed on what happens after a
successful Add to cart: this document's §F specified staying on Item
detail with a brief in-place "Added ✓" confirmation (replacing an older
SnackBar); `hermann/master`'s own parallel note for
TASK-MENU-CUSTOMIZATION-001 specified popping back to Menu immediately,
reasoning that required configuration removes the "maybe add another
variant" case for lingering. The merge keeps both: the button shows the
"Added" checkmark transition briefly (~450ms, long enough to actually be
seen), then `ItemDetailScreen` pops back to Menu on its own — see
`_ItemDetailScreenState._addToCart` in `item_detail_screen.dart`.

### Verification

`flutter analyze` and `flutter test` both pass post-merge (see the
customer app's own toolchain output from the merge commit). One real
compile bug was found and fixed while merging `order_checkout_sheet.dart`:
`hermann/master`'s `SizeTransition` was called with an `alignment` named
parameter, which does not exist on that widget (it takes `axisAlignment:
double`); fixed to `axisAlignment: -1` to match the original redesign's
value. Four golden baselines (`home.png`, `home_scrolled.png`,
`membership_card.png`, `menu_selected.png`) and the two
`item_detail_customization_*.png` goldens were regenerated post-merge
because the merged code combines styling from both branches pixel-for-
pixel differently from either branch alone — reviewed by hand, not blindly
accepted, per the golden/visual QA policy `hermann/master` documented
alongside TASK-MENU-CUSTOMIZATION-001.

Cross-repository documentation sync for this merge remains **PENDING** —
same Dashboard-repository-out-of-scope boundary as §18.

## 20. 2026-08-29 update — TASK-REDESIGN-001

**Verdict: COMPLETE** for presentation-layer scope. `flutter analyze` → 1
pre-existing issue only (`axisAlignment` deprecation in
`order_checkout_sheet.dart`, unrelated — see §12/§16). `flutter test` →
55/55 passed, run 2026-08-29 from `apps/customer`, including the four
previously-failing golden baselines (`home`, `home_scrolled`,
`membership_card`, `menu_selected`) which are now green because this pass
regenerated them for real visual changes (reviewed, not blindly accepted —
see Verification below), not to force the suite green.

This section, like §19, records an addition rather than rewriting §A–§19 in
place. It covers a much larger, uncommitted body of work than §19's merge:
a full second presentation pass across most of the app, plus three new
customer-only screens and one demo-only subsystem. None of the code
described here has been committed as of this writing — it is the working
tree on `customer-app-redesign` on top of commit `def63f3`.

**Backend contracts changed:** No, with one narrow exception already
tracked separately. This section is presentation-only. Two real backend
migrations were also drafted in this same working tree
(`TASK-REFERRAL-001`, `TASK-ACCT-001`) but they are unrelated in kind to
this redesign pass and are documented on their own in
`docs/context/BACKEND_MIGRATIONS_2026-08-29.md`, not here. The one place
this section's UI reads a field those migrations add
(`members.points_balance`, via the pre-existing `pointsProvider`) is
call-through only — no screen in this section constructs or validates that
value itself.

### New shared components

| Component | File | Purpose |
|---|---|---|
| `AidaPopup` | `core/widgets/aida_popup.dart` | App-wide replacement for every screen's local `SnackBar`/`ScaffoldMessenger` helper. `Overlay`-based (survives `Navigator.pop()`), glassmorphism card (`BackdropFilter` + low-alpha fill — see Maintenance rule below), slides/fades in from the top, auto-dismisses on a `LinearProgressIndicator` countdown (default 4s, overridable), swipeable via an explicit close button. Only one popup shows at a time — a new call replaces whatever is showing. |
| `ErrorPage` | `features/error/error_page.dart` | Full-page "something went wrong" state. One baked-in illustration image (`assets/images/aida_error.png`, `BoxFit.contain` — deliberate, see the file's own doc comment on why `.cover` would risk cropping the artwork's baked-in "Oops!" text) plus a compact pill "Go home" button that switches to the Home tab and pops to root. Reachable in this task only via Profile → "Test error page" — no real error boundary wires to it yet (see Known gaps). |
| `TicketTear` + `EarnedRewardsList` | `features/rewards/widgets/ticket_tear.dart`, `.../earned_rewards_list.dart` | Tear-to-apply animation for the Rewards screen's earned-voucher list — see the dedicated Rewards subsection below. |
| `SplashScreen` | `features/splash/splash_screen.dart` | New `main.dart` entry point — see its own subsection below. |
| `OrderProgressCapsule` + `DemoOrderProgress`/`StaffDemoScreen`/`LiquidStageTracker` | `features/order_progress/*.dart` | Demo-only order-progress system — see its own subsection below. |
| `SettingsScreen` | `features/profile/settings_screen.dart` | New pastel masonry-grid settings screen — see its own subsection below. |

### Screen-by-screen specification

#### Membership card

**Implementation:** `apps/customer/lib/features/card/membership_card_screen.dart`.
`_Hero` is new; `_Card` is materially rewritten; `_QrPanel` and
`_ShareCornerButton` are new; `_TierPill`/`_VerifiedStudentPill`/
`_CardUnavailable` are unchanged.

**Layout:** `Scaffold.backgroundColor` changed `cream` → `latte`. Body is a
`Stack`: a full-bleed `_Hero` photo band (`assets/images/qr_hero.webp`,
`height: 260`, top-to-bottom `espresso`-alpha→`latte` scrim, with "My QR" +
`AidaLogo(height: 34, onDark: true)` overlaid via `SafeArea`), and the card
`Positioned` to overlap the hero by 56px (`top: 260 - 56`, `left/right: 20`,
`bottom: 112` — explicit clearance for `AppShell`'s floating nav, same
convention `FloatingCartBar` already used).

The card itself changed shape from a plain 28px-rounded rectangle to a real
**ticket shape**: `ClipPath` with `TicketClipper` (the same clipper already
used by Rewards' voucher cards — its first reuse here), semicircular
bite-outs cut into the left/right edges at a seam whose position is computed
from the fixed 156px details-block height (`notchFraction = (1 -
156/totalHeight).clamp(0.35, 0.85)`). Inside: `_TierPill` top-right over a
centered `_QrPanel`, then a horizontal dashed seam
(`TicketDashPainter`, `cream@0.35`), then the fixed-height details block
("MEMBER · code", the points figure + "Aida Points" label, and
`_VerifiedStudentPill` when applicable).

**Removed:** the member's name row (24px serif, previously under the
in-card logo) and the in-card `AidaLogo` itself — both superseded by the
hero band's own top-of-screen title/logo. The caption sentence below the
old card ("Show this to the barista…") is gone with no replacement text.

**`_QrPanel`:** extracted from inline code. Quiet-zone color changed from
plain white to `AidaColors.latte`; sizing is now
`constraints.biggest.shortestSide.clamp(120.0, 260.0)` via `LayoutBuilder`
instead of a fixed size; corner radius 20px, padding 16.

**`_ShareCornerButton`:** `Positioned(right: 16, bottom: 16)` inside the
card's `Stack`. Exact shape per the literal reference code supplied during
this work: `BorderRadius.only(topLeft: 30, bottomLeft: 30, topRight: 6,
bottomRight: 20)`, blue glass gradient
(`[0xFF56A7FF, 0xFFBBDFFF, 0xFFE8F5FF]`), `Material`+`InkWell`+`Ink`. Label
text is `'Share'`.

**Primary actions (new):** tapping `_ShareCornerButton` calls
`_inviteFriend(Member member)`, which invokes
`SharePlus.instance.share(ShareParams(text: "Join me on Aida Cafe! Use my
code ${member.memberCode} when you sign up and we'll both earn bonus points
☕️", subject: 'Join me on Aida Cafe'))` — the OS share sheet. **This is a
new outbound data flow:** the member's real `memberCode` now leaves the app
via whatever share target the user picks (Messages, WhatsApp, copy, etc.).
The QR code's own `data: memberCode` payload logic is untouched — this is a
new *use* of the value, not a change to how it's generated, validated, or
rendered on the QR.

**New dependency:** `package:share_plus: ^13.3.0` (new pub dependency, added
via `flutter pub add share_plus`; modern non-deprecated
`SharePlus.instance.share(ShareParams(...))` API).

**Data boundary:** unchanged — still `ref.watch(displayedMemberProvider)`
and `ref.watch(pointsProvider)`, the same two reads as before.

**Protected-boundary check:** does not touch `application/providers.dart`,
member-repository files, auth/navigation lifecycle, or money/cart models.
QR/member-code *generation/validation* logic is untouched; the only
member-code-adjacent change is the new share text interpolating the
existing value.

**Behavioral delta:** the new outbound share flow above. Nothing else.

**Evidence:** `flutter test` golden `membership_card` regenerated and
reviewed this pass (part of the 55/55 total — see Verification).

---

#### Profile

**Implementation:** `apps/customer/lib/features/profile/profile_screen.dart`.

**Header (`_CollapsingProfileHeader`, structurally unchanged, materially
re-themed):** background changed from a flat `LinearGradient`
(`coffeeLight → latte → latte`) to a `Stack` of a full-bleed photo
(`assets/images/profile_background.jpg`, `BoxFit.cover`,
`Alignment.topCenter`) behind a dark scrim
(`espresso@0.62 → espresso@0.42 → latte`, stops `[0, 0.62, 1.0]`). Every
text/icon color inside the header (both expanded and collapsed states, both
top-bar variants) changed from `textPrimary`/`textMuted` to
`cream`/`cream@0.8` for legibility against the photo. The "Employee/Student
ID" text color changed `coffee` → `rewardGold`. The header's settings icon
now pushes `SettingsScreen` directly instead of calling
`onComingSoon('Settings')`.

**Primary actions — new "bento" grid (`_PrimaryActionsGrid`/`_BentoTile`):**
replaces the old single-column list of "My Orders"/"Edit profile"/"My
stats"/"Settings" rows with a 2-up-plus-full-width tile grid: "My Orders"
(coffee-tinted, live subtitle from `ref.watch(orderHistoryProvider)` — a
**new read on this screen**, though the provider itself is pre-existing and
shared with `order_history_screen.dart`/`cart_screen.dart`/the new
`settings_screen.dart`), "Invite a friend" (city-red-tinted, subtitle
"Share the love", `onTap: onInviteFriend` — switches to `AppTab.qr` via
`selectedTabProvider`, landing on the membership card where the actual
share action lives), and full-width "Settings" (espresso-tinted, subtitle
"Stats, account, and preferences"). Each `_BentoTile` is a 112px rounded
(22px) card: circular icon badge top-left, label + muted subtitle bottom,
gradient fill/border derived from a per-tile `baseColor` at low alpha.

**Secondary row list — recomposed:**
- **Removed** (moved into the grid or elsewhere): "My Orders", "Edit
  profile" (now reachable only from the header's own pill), "Settings",
  "Invite a friend".
- **Removed entirely, no replacement:** "My stats" — its content "now lives
  inside Settings instead" per the code's own comment (see Settings
  subsection).
- **Kept, restyled:** "Help" (gradient stop order flipped to
  `cream, caramelTint, latte`; still `onComingSoon('Help')`).
- **New:** "Staff demo" (gold-tinted, pushes `StaffDemoScreen`), "Test error
  page" (error-tinted, pushes `ErrorPage`), "Test popup" (gold-tinted,
  `AidaPopup.show(context, title: 'Reward claimed!', message: 'Your reward
  has been added to your account.')`).
- "Logout" unchanged in position/behavior.

**`_comingSoon`** no longer uses `ScaffoldMessenger`/`SnackBar` — calls
`AidaPopup.show(context, title: '$feature is coming soon')`, same migration
every other screen in this pass got (see the AidaPopup subsection below).

**Data boundary:** `orderHistoryProvider` is a new read on this specific
screen (read-only, no mutation); everything else is unchanged provider
usage.

**Protected-boundary check:** does not touch `application/providers.dart`
itself (that file's real change — `AuthState.deleteAccount()` — is driven
by `settings_screen.dart`, not by this file, even though this file is what
navigates there). Does not touch member-repository files, auth/navigation
lifecycle beyond the pre-existing `authStateProvider.notifier.logOut()`
call, money/cart models, or QR/member-code semantics.

**Behavioral delta:** none beyond the new `orderHistoryProvider` read and
the `AidaPopup` messaging-mechanism swap; no cart/checkout/money mutation.

---

#### Order confirmation

**Implementation:** `apps/customer/lib/features/cart/order_confirmation_screen.dart`.

**Real behavioral delta — read this first, not just a restyle:** this
screen now has a demo-status override. Its class doc comment was rewritten
to explain: while staff/POS status updates aren't wired to the real
backend yet, a genuinely-placed order's real Supabase status "resolves
successfully… it just never advances past 'confirmed'." So `build()` now
also reads `ref.watch(demoOrderProgressProvider)`, looks for a `DemoOrder`
whose `id` matches this order, and — **when found — shows that in-memory
demo status instead of the real backend-fetched one**:
`current = demoMatch != null ? demoOrderSnapshot(demoMatch) :
ref.watch(orderProvider(order.id)).value ?? order`. `demoOrderSnapshot()`
maps `DemoStage.placed/preparing/ready/completed` to
`OrderStatus.confirmed/preparing/ready/completed` and constructs a
synthetic `OrderSnapshot` with `lines: const []` (always empty) and
`createdAt`/`updatedAt: DateTime.now()` (not the real order's timestamps).
This screen does not currently render `current.lines`, so the empty-lines
fact has no visible effect here specifically, but it is a fact about what's
being displayed whenever the demo path is active. The doc comment is
explicit that this is a temporary stand-in: "Once real status wiring lands,
delete this screen's demo branch and the whole `order_progress` demo
feature along with it."

**New auto-navigation:** a `ref.listen<List<DemoOrder>>(demoOrderProgressProvider,
...)` callback pops the screen back to root
(`Navigator.of(context).popUntil((r) => r.isFirst)`) if the matched demo
order transitions from live to no-longer-live (dismissed or removed) while
this screen is open — e.g. after `DemoOrderProgress.complete()`'s 6-second
"thank you" grace period elapses. This is a real behavior change: the
screen can now navigate itself away without user action.

**Visual redesign:** whole-screen background changed from flat
`AidaColors.cream` to a full-bleed photo (`assets/images/order_confirmed.png`)
under a light `cardWhite@0.35` wash. The status icon circle (previously
shown for every state, swapping icon by state) is now rendered **only** for
the cancelled state — for every other state there's no icon, the
background photo takes its place. Content moved from a fixed
`Column`+`Spacer()` layout (which could overflow on short screens) into a
`SingleChildScrollView`/`ConstrainedBox`, so it scrolls instead of
overflowing.

Copy: the `completed` state's title changed `'Order completed'` →
`'Thank you!'`, with new body copy `'Enjoy your drink. See you again
soon.'`. The `ready` state's em dash was replaced with a period (`'Head to
the counter. Order X is waiting for you.'`) — the same em-dash sweep
applied app-wide (see below).

The old vertical numbered/dotted timeline (`_TimelineStep`, `_StepState` —
both **deleted**) is replaced by `LiquidStageTracker(stageIndex:
activeStage, labels: ['Confirmed', 'Preparing', 'Ready for pickup',
'Completed'])`, shown only when not cancelled — see the Order-progress
subsection below for what `LiquidStageTracker` is. The full-width
`FilledButton` "Back to Menu" is replaced by a new `_PopInButton`: a
smaller, centered, pill-shaped button with a one-shot elastic pop-in
entrance (`TweenAnimationBuilder`, 420ms, `Curves.elasticOut` — explicitly
not a looping animation, so `pumpAndSettle()` still terminates in tests
that pass through this screen).

**Data boundary:** `demoOrderProgressProvider` is a new read/listen on this
screen (provider itself defined in the new
`order_progress/demo_order_progress_provider.dart`). `orderProvider(order.id)`
remains the pre-existing real read, now used only as the fallback when no
demo match exists. No cart/money model is mutated by this file —
`Money`/`OrderSnapshot` are read/constructed (via the imported provider
file's types), never written back.

**Protected-boundary check:** does not touch `application/providers.dart`,
member-repository files, or QR/member-code semantics. The new `popUntil`
call reuses the exact `Navigator` pattern the old button already used, now
also triggered by a listener rather than only a tap — a real navigation
behavior change, but not a change to navigation *lifecycle infrastructure*
(`app_shell.dart`'s own tab/route structure is untouched by this file).
Does not touch money/cart *model* files, though it imports and reads their
types.

**Evidence:** `flutter test` golden coverage for this screen is unchanged
from what already existed; no new golden was added specifically for the
demo-status-override path (see Known gaps).

---

#### Menu — search

**Implementation:** `apps/customer/lib/features/menu/menu_screen.dart`.
`MenuScreen` converted `ConsumerWidget` → `ConsumerStatefulWidget`
(`_MenuScreenState`) to hold a `TextEditingController _searchController`
and `String _query`.

**Layout:** the old header row ("Menu" title + a top-right heart
`_FavoritesToggle`) is replaced by the title alone, with a new rounded-pill
`_SearchField` (search icon, "Search the menu" hint, a clear button that
only renders once text is present) directly below it. **`_FavoritesToggle`
is deleted entirely** — Favorites is now reachable via Menu's own left rail
(pre-existing) and, new this pass, via Home's category strip (see Home
subsection).

**Behavior:** search matches `item.name`/`item.description`
case-insensitively across every product, **ignoring the selected category**
(search and category browsing are treated as two separate ways to find
something, not combinable filters — per the file's own new doc comment). A
non-empty query renders a flat "Results" section (count omitted — see
below) instead of the normal category sections, or `_NoSearchResults`
(new widget: search-off icon, `'No matches for "$query"'`, a hint to try
category browsing) when nothing matches. Tapping a category, Favorites, or
the rail clears any active search (`_clearSearch()`) so a stale result set
never masks a category tap.

**Removed in the same diff, not directly search-related:** `_MenuSectionHeader`'s
item-count badge (`if (count != null) ...`) — the count `Text` next to a
section title is gone; the header now shows only the title/divider.

**Data boundary:** unchanged providers (`categoriesProvider`,
`menuItemsProvider`, `favoritesProvider`, `favoritesOnlyProvider`); search
matching is pure local `String.contains` filtering over already-fetched
data, no new network call.

**Protected-boundary check:** presentational/filtering only; no cart/order
model touched.

---

#### Home — Favorites chip and browsable-category fix

**Implementation:** `apps/customer/lib/features/home/home_screen.dart`.

**New:** `CategoryStrip` (shared with Menu's rail-less strip usage) gains
`showFavorites`/`onSelectFavorites` params; Home passes `showFavorites:
true`, rendering a `CategoryChip` (icon `Icons.favorite_rounded`, label
"Favorites") as the strip's first tile. Tapping it calls a new
`_openFavorites()`: clears the selected category, sets
`favoritesOnlyProvider` true, switches to the Menu tab. `CategoryChip`
itself gained a `'favorites'` case to its image-lookup switch
(`assets/images/favorite_mascot.png`, a new asset, cut-out mascot photo —
same "real image, no card fill" treatment the other category chips already
use).

**Real (non-cosmetic) fix bundled in the same diff:** Home's category strip
now filters to only categories that actually have `kind == 'product'` items
(`browsableCategoryIds`), rather than showing every category the backend
returns regardless of whether it has any browsable products — this closes
a latent gap where an empty or add-on-only category could appear on Home's
strip and lead nowhere useful.

**Also in this diff:** every remaining `ScaffoldMessenger`/`SnackBar` call
on this screen (`_showNoNotificationsYet`, `_onDayTap`'s three call sites)
is now `AidaPopup.show(...)` — completing the migration this screen had
already started earlier in the branch's history (see §17's protected-
boundary note, which predates this). The daily-check-in success message
changed from a single string (`'Checked in — see you tomorrow'`) to
`AidaPopup.show(context, title: 'Checked in', message: 'See you
tomorrow.')` — title/message split, em dash removed. The free-drinks banner
was restyled: icon moved into a solid coffee-colored circle badge, fill
changed from a flat `latte@0.45` to a `latte→rewardGold` gradient with a
gold border, and its copy lost its em dash (`'Free drink ready — show your
QR'` → `'Free drink ready, show your QR'`). The "My Balance" caption above
the points figure was removed; "Aida Points" label size bumped 13→16.

**Protected-boundary check:** presentational + a category-visibility fix;
no provider added beyond consuming pre-existing `menuItemsProvider` (now
also read here to compute `browsableCategoryIds`); no cart/order/money
model touched.

---

#### Rewards — tear-to-apply animation and "Coming soon" catalogue

**Implementation:**
`apps/customer/lib/features/rewards/rewards_screen.dart`,
`apps/customer/lib/features/rewards/widgets/reward_ticket_card.dart`
(materially changed), `.../widgets/ticket_tear.dart` (new),
`.../widgets/earned_rewards_list.dart` (new).

**Earned Rewards — real tear animation:** the earned-voucher list, previously
a plain `for` loop of `RewardTicketCard`s, is now owned by the new
`EarnedRewardsList` (a `StatefulWidget` wrapping its own `AnimatedList`).
Tapping "Apply" on a card no longer just shows a message — it plays
`TicketTear`: a `CustomClipper`-based jagged vertical tear (9-tooth zigzag,
computed so the left/content piece and right/coffee-cup piece interlock
seamlessly at rest), driven by a 900ms `AnimationController` through two
named `Interval`s — `_separate` (0.0–0.4, `Curves.easeOutBack`: a quick snap
with overshoot, both halves translating/rotating apart) and `_fade`
(0.66–1.0, `Curves.easeIn`: both halves fade out together once the tear has
had time to read). When the controller completes, `_EarnedTicketItemState`
reports `onTornAway` to the parent list, which removes the card from its
old position and re-inserts it at the bottom via real `AnimatedList`
insert/remove calls (200ms remove / 320–340ms insert), not a blind rebuild.

**Permanent torn state:** a card that is already `applied` when constructed
(i.e., the fresh instance that lands at the bottom after its own tear
finished, not one mid-animation) renders `TicketTear` at a fixed
`progress = 0.5` — the tear's "held" plateau (fully separated, fully
opaque, past the fade) — so an applied voucher stays visibly torn at the
bottom of the list rather than reverting to a whole card. This is the
resting-state fix requested mid-session after the first tear-only version
was reviewed.

**`RewardTicketCard`** gained an `applied` bool (default `false`): when
true, the whole card (whichever piece `TicketTear` is currently rendering,
or the intact card before any tear starts) is wrapped in `AnimatedOpacity`
to 0.6 over 300ms — a quiet "acknowledged" dimming cue independent of the
tear itself.

**Purely local/cosmetic, by design:** there is no "used" status on the
`Voucher` domain model — staff still consume the entitlement at the
counter. "Applied" exists only for this screen's session lifetime and
resyncs to the server list (real insert/remove diffing against
`widget.vouchers` in `didUpdateWidget`) whenever the underlying list
actually changes.

**Redeem with Points — "Coming soon" disclosure, popup removed:**
`_SectionTitle` gained a `comingSoon` bool; when true it renders a
`_ComingSoonBadge` pill (`'COMING SOON'`, 9px, `latte@0.65` fill) next to
the section title. The "Redeem with Points" section now sets this. Every
catalogue tile's primary button is now unconditionally
`primaryEnabled: false, onPrimary: null` (previously affordable tiers were
tappable and triggered a `_snack` explaining redemption "is next"); the
button's label logic (`'Redeem'`/`'Need more'`) is unchanged as
informational-only text. The old snackbar string for this
("Points-to-voucher redemption is next — your balance stays put until
then.") is deleted, not reworded — superseded by the section-level
disclosure instead of a per-tap explanation.

**Em dashes removed** (part of the app-wide sweep, see below):
`'Show at the counter — staff apply them'` → `'Show at the counter, staff
apply them'`; `'No earned rewards yet — complete...'` → `'No earned
rewards yet. Complete...'`; `'Show this reward at the counter — staff will
apply it.'` → `'... counter. Staff will apply it.'`.

**Data boundary:** unchanged — points/stamps/rewards/vouchers/offers remain
`MockMemberRepository`-backed (per `MOCKS_AND_PLACEHOLDERS.md`), except
`pointsProvider`'s underlying balance, which as of `TASK-REFERRAL-001`
(separately documented, see
`docs/context/BACKEND_MIGRATIONS_2026-08-29.md`) reads real data when that
migration is applied and falls back to mock otherwise — this screen itself
made no change to how it reads `pointsProvider`.

**Protected-boundary check:** presentational/interaction only; no
cart/order/money model touched; no new provider.

---

#### Item detail — size/option tile restyle

**Implementation:** `apps/customer/lib/features/menu/item_detail_screen.dart`.

Beverage-size (`_VariantTile`) and drink-option (`_ChoiceTile`) tiles now
share one consistent card language via new shared constants
(`_optionTileWidth = 108`, `_optionTileHeight = 100`,
`_optionTileRadius = 20`) instead of two differently-sized/shaped tile
styles. Both `Wrap`s are now centered (`WrapAlignment.center`) inside a
full-width `SizedBox`. `_VariantTile`'s cup icon grew (28→32px max) and its
per-price delta caption below the label was **removed** (variant price
deltas are no longer shown on the size tile itself). `_ChoiceTile` gained
an optional leading `icon` — a new `_iconForOption(groupCode, optionCode)`
helper returns a flame icon for `temperature`/`hot` and a snowflake for
`temperature`/`iced`|`cold` (null, i.e. no icon, for every other group
including Sweetness); the old small inline checkmark shown only when
selected is removed in favor of the icon slot (present or absent
regardless of selection) plus the existing selected-state color/weight
change on the label text, which also grew 12.5px→15px.

**Behavioral delta:** none — this is a pure restyle of already-existing
Size/Temperature/Sweetness selection UI; the underlying
`_selectOption`/`setState` selection logic is untouched.

**Protected-boundary check:** presentational only.

---

#### Cart — wired into the demo order-progress system

**Implementation:** `apps/customer/lib/features/cart/cart_screen.dart`.

`_orderPlaced(OrderSnapshot order)` gained one new line after the existing
`cartProvider.notifier.clear()`/`orderHistoryProvider` invalidation:
`ref.read(demoOrderProgressProvider.notifier).addFromCheckout(order)` — per
the new provider file's own doc comment, "this is what actually makes
`OrderProgressCapsule` appear." This is the real integration point between
a genuine checkout and the demo order-progress subsystem described below;
every other real checkout/order-placement call in this file is unchanged.

Also in this diff: the promo-code-unavailable message
(`_PromoRow`) migrated from `ScaffoldMessenger`/`SnackBar` to
`AidaPopup.show(context, title: "Promo codes aren't available in this demo
yet")` — part of the app-wide sweep below.

**Protected-boundary check:** does not touch `application/providers.dart`,
member-repository files, or money/cart *model* files — `demo_order_progress_provider.dart`
imports and reads `Money`/`OrderSnapshot` types to build its own local
`DemoOrder` records but does not modify the cart/order model files
themselves. `cartProvider.notifier.clear()` and the checkout call path are
unchanged.

---

#### New: Settings screen

**Implementation:** `apps/customer/lib/features/profile/settings_screen.dart`
(new file, replacing whatever settings surface existed before — no prior
committed `settings_screen.dart` exists in this repository's history to
diff against).

A pastel "masonry" grid matching a supplied reference's literal palette
(named constants `_lavender`, `_tan`, `_mauve`, `_sageLight`, `_sageDark`,
`_mustard` — flat hex values, deliberately not derived from `AidaColors`,
per the file's own doc comment: "the user asked for these exact colors, not
an Aida-tinted translation"). Layout: a full-width headline stat card
("Aida Points" balance, 44px serif), a row of three equal squares (Stamps,
Orders, Profile), a masonry pair (one tall "Password" tile beside two
stacked "Logout"/"Privacy" tiles), then a final row (Terms, Delete
Account), followed by a version footer.

**Functional tiles:**
- **Stamps** — display-only (`onTap: null`), subtitle from
  `ref.watch(stampCardProvider)`.
- **Orders** — subtitle from `ref.watch(orderHistoryProvider)`'s length;
  pushes `OrderHistoryScreen`.
- **Profile** — pushes `EditProfileScreen(member: member)` once loaded (else
  shows a "Loading your profile…" popup).
- **Password** — `_changePassword`: reads the member's email, calls
  `memberRepositoryProvider.requestPasswordReset(email: ...)` (pre-existing
  repository method), reports success/failure via `AidaPopup`.
- **Logout** — unchanged `authStateProvider.notifier.logOut()`.
- **Privacy** / **Terms** — both `_toast`-only "coming soon" placeholders.
- **Delete Account** — see below.

**Delete Account flow (`_confirmDeleteAccount`):** a destructive-styled
`AlertDialog` ("Delete your account? This permanently erases your profile,
membership, points, and stamps. This cannot be undone.") with Cancel/Delete
actions; on confirm, a non-dismissible progress dialog shows while
`ref.read(authStateProvider.notifier).deleteAccount()` runs (the new
method backing `TASK-ACCT-001` — see
`docs/context/BACKEND_MIGRATIONS_2026-08-29.md` for the backend/migration
side). On success, the progress dialog is popped and nothing else
navigates explicitly — `AuthGate` reacts to `authStateProvider` on its own
and swaps to `LoginScreen`. On failure, the returned failure message is
shown via `AidaPopup`.

**Data boundary:** reads `memberProvider`, `pointsProvider`,
`stampCardProvider`, `orderHistoryProvider` — all pre-existing providers,
no new reads beyond what a settings surface would be expected to show.
`deleteAccount()` is a real, if unverified, backend mutation — see the
backend evidence doc for why it's PARTIAL, not COMPLETE.

**Protected-boundary check:** this screen is the one place in this entire
redesign pass that touches account-deletion authority, which is why
`TASK-ACCT-001` is tracked separately from this presentation-only section
rather than folded into it — see
`docs/context/BACKEND_MIGRATIONS_2026-08-29.md`.

---

#### New: Splash screen

**Implementation:** `apps/customer/lib/features/splash/splash_screen.dart`;
`lib/main.dart`'s `AidaApp.home` changed from `const AuthGate()` to `const
SplashScreen()`.

Plays a bundled 1.5s brand video (`assets/images/splash_screen.mp4`, muted,
trimmed with a built-in fade to `AidaColors.cream` at its tail — matching
every real destination's own background, so the handoff reads as invisible
rather than a dark-splash-to-light-app flash) on an `espresso`-background
`Scaffold`, then `pushReplacement`s into `AuthGate` via a 260ms
cross-fade `PageRouteBuilder`. Never gets stuck: a failed/missing video
(asset error, unsupported codec, plugin unavailable in a test harness)
falls through to `AuthGate` immediately; a 3-second safety timer covers a
video that initializes but never reports finishing; tapping anywhere skips
straight through. Per its own doc comment, the screen's `espresso`
background is only ever visible for the brief gap before the video
initializes — it is not a designed "brand color" moment, it is the video's
own opening tone.

**New dependency:** `package:video_player: ^2.10.1`.

**Protected-boundary check:** changes `main.dart`'s app entry point (flagged
here explicitly since `main.dart`/navigation lifecycle is a protected-
adjacent area per `AGENTS.md`) — the change is additive (one new screen
inserted before the existing `AuthGate`), does not alter `AuthGate` itself,
and every fallback path still lands on the exact same `AuthGate` the app
opened on before this change.

---

#### New: demo order-progress system

**Implementation:**
`apps/customer/lib/features/order_progress/demo_order_progress_provider.dart`,
`order_progress_capsule.dart`, `staff_demo_screen.dart`,
`liquid_stage_tracker.dart`.

**Explicitly, repeatedly self-documented as DEMO ONLY** — every file in
this directory carries a doc comment to this effect. It stands in for real
staff/POS-driven order status until the Dashboard/POS repository is wired
up; nothing in this subsystem touches Supabase. It is local, in-memory
`Notifier` state.

- `DemoOrderProgress` (`Notifier<List<DemoOrder>>`, starts `build() => const
  []`): `addFromCheckout(OrderSnapshot)` (called from `cart_screen.dart`
  right after a real checkout — see Cart subsection above — this is the
  only way a demo order is created from real customer action);
  `addTestOrder()` (staff-only, alternates ASAP/scheduled fixtures);
  `accept`/`markReady`/`complete` (explicit staff taps — no timer advances
  a stage automatically, since real prep time depends on queue depth, which
  only a barista knows); `complete()` schedules a 6-second
  `thankYouDuration` after which the order auto-dismisses (hidden from the
  capsule, not deleted from state, so staff can still find/reset it);
  `reset`/`clearAll`.
- `activeDemoOrderProvider`: the single non-dismissed order the
  customer-facing capsule shows (mirrors `FloatingCartBar`'s one-aggregate-view
  pattern rather than a per-order list).
- `OrderProgressCapsule`: same fixed-slot pill language as
  `FloatingCartBar`, `AnimatedSwitcher`-driven fade/slide entrance/exit,
  visible on any tab whenever a demo order is in flight. Its body is a
  horizontal liquid-fill pill (`_LiquidFillPainter`, a wavy leading edge
  driven by an `AnimationController` that animates *to* each stage's fill
  fraction on an explicit staff transition, not on a running clock — a
  fixed per-order wave phase, not a repeating animation, so
  `pumpAndSettle()` still terminates in tests, since this capsule lives in
  `AppShell` and is therefore present during nearly every widget test in
  the app). Tapping it pushes `OrderConfirmationScreen(order:
  demoOrderSnapshot(order))`.
- `StaffDemoScreen`: reachable from Profile → "Staff demo" (see Profile
  subsection). Lists every demo order with Accept/Mark ready/Done/Reset
  controls and an "Add test order" button, so the customer-facing capsule
  can be driven live without a second device or a real backend.
- `LiquidStageTracker`: a vertical variant of the same liquid-fill
  metaphor (`stageIndex`/`labels`-driven, not order-object-driven), used by
  `OrderConfirmationScreen` (see that subsection) for a taller, more
  spacious version of the same visual language, animated once via
  `TweenAnimationBuilder` (900ms, `easeOutCubic`) rather than an
  `AnimationController` that responds to further transitions in place — a
  screen visited once per order status view, not one that needs to react
  to live changes while mounted, unlike the capsule.

**`AppShell` integration:** `app_shell.dart` gained `_StackedOrderProgress`,
a `ConsumerWidget` that positions `OrderProgressCapsule` above
`FloatingCartBar` when the cart is non-empty (stacked, with a gap so the
two never touch), or drops into the cart bar's own slot when the cart is
empty (no dead gap). The bottom nav's own layout changed too: height
72→80px, each `_NeumorphicNavButton` gained a text label below its icon
(previously icon-only), and the floating-nav clearance calculation changed
from a hardcoded `bottom: 96` to `_navClearance (112) +
MediaQuery.paddingOf(context).bottom` — fixing a real cross-device bug
where the original constant (tuned on a device with zero bottom safe-area
inset) shrank the gap above the nav bar on devices with a taller
home-indicator area (iPhones) than the constant assumed.

**Data boundary:** entirely local/in-memory; no Supabase call anywhere in
this subsystem.

**Protected-boundary check:** `app_shell.dart` is navigation-lifecycle-
adjacent (flagged per `AGENTS.md`), but the change is additive layout
(a new `Positioned` capsule stacked alongside the existing cart bar) plus a
real cross-device clearance bugfix — the five-tab `IndexedStack` structure
and tab-switching logic are untouched.

**Known limitation, stated plainly:** this entire subsystem is a
placeholder. `OrderConfirmationScreen`'s own class doc comment says outright
that once real staff/POS status wiring lands, "delete this screen's demo
branch and the whole `order_progress` demo feature along with it." Nothing
here should be treated as a real fulfilment-status feature — see
`docs/context/ARCHITECTURE.md`'s "explicitly separate authority" list,
which already excludes staff/POS status wiring in this task's scope from
this app.

---

#### App icon and asset housekeeping

`pubspec.yaml` added `flutter_launcher_icons: ^0.14.4` (dev dependency) and
a `flutter_launcher_icons:` config block (`image_path:
"assets/images/app_icon.jpg"`, `android: true`, `ios: true`,
`remove_alpha_ios: true`), regenerating every iOS/Android launcher icon
size from that one source image (`dart run flutter_launcher_icons`,
regenerating the `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` and
`android/app/src/main/res/mipmap-*/ic_launcher.png` files present in the
working tree). New assets registered this pass:
`qr_hero.webp`, `profile_background.jpg`, `splash_screen.mp4`,
`order_confirmed.png`, `capsule_character.png`, `favorite_mascot.png`,
`aida_error.png` (all listed in `pubspec.yaml`'s `flutter.assets`).

### App-wide: `AidaPopup` replaces every `SnackBar`

Every remaining `ScaffoldMessenger`/`SnackBar` call site in the app —
across Home, Menu (none had any), Rewards, Cart, Login/sign-up, Profile,
Settings (new, born using `AidaPopup` from the start) — now calls
`AidaPopup.show(context, title: ..., message: ...)` instead. Verified via
`grep -rln "ScaffoldMessenger\|SnackBar(" apps/customer/lib` returning
empty as of this pass.

### App-wide: em dash sweep

Every user-facing message string containing an em dash (`—`) was reworded
to plain punctuation (usually a period or comma), per explicit instruction.
Affected strings are listed under each screen's own subsection above
(Home, Rewards, Order confirmation, and — from earlier in this branch's
history, already recorded — Staff demo's info paragraph). This was a
wording-only change in every case; no string's meaning changed.

### Known gaps

- **No widget test exercises:** the Settings delete-account confirmation
  dialog/progress/success/failure flow; the Rewards tear animation itself
  (tap Apply → tear plays → card resettles at the bottom torn); the
  Splash screen's video-failure/timeout fallback paths; the
  `OrderProgressCapsule`/`StaffDemoScreen` demo flow end-to-end; Menu
  search; Home's new Favorites chip/`browsableCategoryIds` filtering;
  `_ShareCornerButton`'s share-sheet invocation (not testable without
  mocking the OS share intent).
- **`order_confirmation_screen.dart`'s demo-status-override path has no
  dedicated golden** — only the pre-existing non-demo golden coverage
  carries forward.
- **The entire `order_progress/` demo subsystem is explicitly temporary**
  by its own authors' doc comments (see above) — it should not be extended
  with more demo-only features; the next real step is wiring actual
  Dashboard/POS status, at which point this whole directory is meant to be
  deleted, not grown.
- **`ErrorPage` has no real error boundary wired to it** — it is reachable
  only via Profile → "Test error page" in this task. Deciding where/how it
  should actually trigger (a global Flutter error handler? specific
  provider-error fallbacks?) is unscoped here.
- **Two backend migrations this same working tree also drafted
  (`TASK-REFERRAL-001`, `TASK-ACCT-001`) are unverified against live
  Supabase** — tracked separately in
  `docs/context/BACKEND_MIGRATIONS_2026-08-29.md`, not a gap in this
  section's own presentation-layer scope, but relevant context since both
  landed in the same uncommitted working tree.
- **Nothing in this section has been committed to git** as of this
  writing — see each affected top-level hub document's own note on this.

### Verification

1. `git diff --stat` / targeted `git diff -- <path>` against baseline
   commit `def63f3` for every file named in this section, run from the repo
   root, 2026-08-29.
2. Full `Read` of every new file named in this section.
3. `grep -rln "ScaffoldMessenger\|SnackBar("  apps/customer/lib` → empty,
   confirming the app-wide `AidaPopup` migration claim above.
4. `flutter analyze` (from `apps/customer`) → 1 issue, the pre-existing
   `axisAlignment` deprecation in `order_checkout_sheet.dart`, unrelated to
   this work (see §12/§16's own note on the same warning).
5. `flutter test` (from `apps/customer`) → **55 passed, 0 failed**,
   including all four previously-failing golden baselines (`home`,
   `home_scrolled`, `menu_selected`, `membership_card`) and the two
   `item_detail_customization_*` goldens, all regenerated for this pass's
   real visual changes and reviewed, not blindly accepted.
6. Provider/navigation claims cross-checked against
   `apps/customer/lib/application/providers.dart` and each screen's actual
   `ref.watch`/`ref.read`/`ref.listen` calls.
7. Protected-boundary claims (per `AGENTS.md`/§17's own checklist) verified
   per-file above rather than asserted once for the whole section, since
   this pass is much larger in surface area than §A–§18's original scope.

### Existing documents updated by this task

- `docs/context/AUDIT_LOG.md`, `docs/context/ACTIVE_CONTEXT.md`,
  `docs/context/HANDOFF.md` — see each file's own diff.
- `docs/context/CODEBASE_MAP.md` — new "2026-08-29 additions" section.
- `docs/context/BACKEND_MIGRATIONS_2026-08-29.md` — new file, the backend
  half of this same working tree (`TASK-REFERRAL-001`, `TASK-ACCT-001`),
  intentionally kept separate from this presentation-only section.
- `docs/context/SUPABASE_STATUS.md`, `docs/contracts/SHARED_BACKEND_CONTRACT.md`,
  `docs/context/ROADMAP.md`, `docs/context/PROJECT_BRIEF.md`,
  `docs/security/SECURITY_REVIEW.md` — updated for the backend migrations
  above, not for anything in this presentation-only section.

### Cross-repository synchronization

`Cross-repository documentation sync: PENDING — Dashboard repository not
available in this task`, same boundary as §18/§19. Nothing in this section
touches `Hermann-33/Aida_System-Dashboard`.
