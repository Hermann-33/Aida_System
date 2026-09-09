# Customer UI Redesign Specification

Updated: 2026-08-23

This document describes the accepted AIDA customer/mobile presentation language and the current implemented behavior after TASK-MENU-CUSTOMIZATION-001. Runtime/trust truth remains governed by accepted ADRs, `ARCHITECTURE.md`, `SHARED_BACKEND_CONTRACT.md` and `ORDER_AND_SCHEDULING_CONTRACT.md`.

## Scope

Primary redesigned customer surfaces:

- Menu;
- Item detail / customization;
- Cart;
- Checkout sheet;
- Rewards;
- floating cart affordance.

The visual redesign does not grant business authority. Supabase remains authoritative for identity/member state, catalogue/options/add-ons/prices, order quote/persistence/status and scheduling policy.

## Design system

### Colors

Canonical values remain in `apps/customer/lib/core/theme/aida_colors.dart`:

| Token | Value / derivation | Role |
|---|---|---|
| `cityRed` | `#AF2626` | CityU/student identity |
| `cream` | `#FDF6F7` | page/background surface |
| `latte` | `#F2CFD6` | secondary surfaces/dividers |
| `coffee` | `#C13A52` | primary action/selected accent |
| `espresso` | `#27121A` | dark/high-contrast text |
| `rewardGold` | `#C9A24E` | loyalty emphasis only |
| `cardWhite` | `#FFFFFF` | elevated/light surfaces |
| `caramelTint` | `#F7DEE3` | soft tint/placeholder surface |
| `textMuted` | `#976B77` | secondary text |
| `error` | `#8C3A2E` | error/destructive state |
| `success` | `#4F6B4A` | confirmation |

No trusted state is communicated by color alone.

### Typography

Typography remains centralized in `AidaType`:

- Playfair Display for display/serif hierarchy;
- Plus Jakarta Sans for interface/body text;
- existing centralized section/label helpers where applicable.

Fonts remain bundled; no runtime font dependency is introduced.

### Shape / interaction

The accepted language uses:

- cream/white layered surfaces;
- rounded controls/cards/sheets, generally 18–28 px with larger item-detail sheet radii;
- coffee/burgundy selected borders/fills;
- existing tactile/neumorphic controls for primary actions/navigation where already established;
- soft shadows rather than strong elevation;
- explicit text/icons for selected/unavailable state;
- existing route/navigation architecture rather than new global chrome.

External café apps, including Luckin, may inspire information architecture but **must not** import their branding or blue palette into AIDA.

## Shared components

Important presentation components include:

- `features/menu/widgets/menu_category_rail.dart` — vertical category/favourites rail with stable automation keys;
- `features/menu/widgets/menu_list_item.dart` — photo-forward product list row;
- `core/widgets/neumorphic_control.dart` — existing tactile control language;
- `core/widgets/product_image.dart` — live catalogue image first, bundled/local fallback only;
- `features/cart/widgets/floating_cart_bar.dart` — animated local-cart affordance.

`MenuGridItem` remains retired and should not be reintroduced without a deliberate design decision.

## Navigation / information architecture

- five-tab `AppShell` remains an `IndexedStack`;
- customer Menu opens `ItemDetailScreen` before cart insertion;
- item configuration is line-scoped;
- **successful Add to cart now immediately closes Item detail and returns to Menu**;
- Cart opens `OrderCheckoutSheet` in a modal bottom sheet;
- placement clears cart only after persisted order success;
- successful placement opens order confirmation/history behavior already defined by the order flow.

The immediate return after Add-to-cart supersedes the older brief in-place `Added` confirmation behavior for Item detail.

## Menu

Implementation:

- `features/menu/menu_screen.dart`;
- `features/menu/widgets/menu_category_rail.dart`;
- `features/menu/widgets/menu_list_item.dart`.

Current behavior:

- photo-forward single-column product list;
- vertical category/favourites rail;
- pull-to-refresh and local favourites retained;
- unavailable products remain non-interactive/explicit;
- server `MenuItem.imageUrl` remains primary imagery;
- catalogue rows whose `kind=addon` are **not** presented as standalone customer products;
- an add-on-only category with no browseable products is not presented as a customer menu category.

Data boundary: Supabase catalogue + revision invalidation/refetch. Category/favourite selection is local presentation state.

## Item detail / drink customization

Implementation:

`features/menu/item_detail_screen.dart`.

### Existing product hierarchy preserved

The screen retains the accepted AIDA hierarchy:

- live product hero;
- tactile Back/Favourite controls;
- product name and local running-price pill;
- category / sold-out / student-offer tags where applicable;
- description;
- configuration groups;
- note;
- quantity + primary Add-to-cart CTA.

### Size

Available catalogue variants are shown as single-choice configuration controls. Variant labels and price deltas are catalogue data.

### Temperature / Sweetness

Drink products can expose catalogue-driven required single-choice groups, currently standardised as:

```text
Temperature: Hot | Iced
Sweetness: Regular | Less sweet | Least sweet
```

The item-specific catalogue controls customer label, price delta, availability, default and sort order.

Visual requirements:

- same rounded selection language as Size;
- selected state uses coffee/burgundy emphasis plus an explicit check indicator;
- unavailable options remain visible but disabled and display explicit `Unavailable` messaging/semantics;
- longer Admin-configured labels wrap rather than overflow;
- non-zero price deltas are shown as secondary text;
- selected/unavailable meaning is not color-only.

The client stages option IDs only. Backend quote remains authoritative for option validity/default/pricing.

### Customize / add-ons

Compatible add-ons are shown as optional per-line checkbox rows under `Customize`.

An add-on selection belongs only to the current configured line. Therefore one Latte can contain Boba/Oat Milk/etc. while another copy of the same drink can omit it.

Add-on rows use the existing AIDA text/icon/accent language and validated touch targets.

### Local price

The Item-detail running price is an estimate:

```text
base
+ selected variant delta
+ selected option deltas
+ selected add-ons
```

The backend quote recalculates and may reject stale/unavailable selections.

### Add to cart

The primary action continues to use the established AIDA tactile/neumorphic CTA language.

On success:

1. add the complete configured line to local cart state;
2. immediately pop `ItemDetailScreen`;
3. return the user to Menu.

This reduces accidental duplicate adds when configuring multiple drinks.

## Cart

Implementation: `features/cart/cart_screen.dart`.

Current behavior:

- flat photo rows;
- swipe-to-remove;
- quantity controls;
- configuration summary includes variant, selected Temperature/Sweetness and add-ons;
- differently configured copies remain distinct lines;
- optional note retained;
- `Estimated subtotal` explicitly remains local estimate;
- `Review order` transitions to authoritative quote.

Cart identity/equivalence must include option/add-on IDs, not only product/variant.

## Floating cart bar

Implementation: `features/cart/widgets/floating_cart_bar.dart`.

- animated entrance/exit;
- cart-line thumbnails/overflow count;
- item count + estimated subtotal;
- navigates to Cart.

It is local cart presentation only.

## Checkout sheet

Implementation: `features/cart/order_checkout_sheet.dart`.

### Now / Schedule terminology

Customer-facing choices are:

```text
Now
Schedule
```

`Now` is presentation only; the trusted backend/wire enum remains `asap`.

### Scheduled wheel

The accepted tactile wheel-style scheduled selector remains part of the AIDA redesign.

The wheel does **not** invent valid times. It renders only values returned by `derivePickupSlots(OrderingPolicy)` and therefore remains constrained by:

- `scheduleEnabled`;
- `minimumLeadMinutes`;
- `slotIntervalMinutes`;
- `maximumAdvanceDays`;
- backend timezone/server time.

Do not replace the wheel with arbitrary minutes/client-only opening hours or a generic dropdown unless a separate accepted accessibility/platform decision requires it.

### Commercial authority

Checkout:

- obtains authoritative policy;
- requests authoritative quote;
- renders `Server total`;
- places only through the accepted order repository/session;
- keeps Pay-at-counter semantics;
- reuses retry-stable idempotency state;
- clears cart only after persisted success.

## Rewards / Membership QR

Rewards continues to use the accepted dark membership-card presentation and bundled AIDA logo. Member identity display is real owner-scoped state; loyalty points/rewards/vouchers remain deferred/mock where documented.

Membership QR continues to use server-owned member code and the existing minimum offline cache boundary. The shared logo is presentation only.

## Accessibility / testability

TASK-MENU-CUSTOMIZATION-001 validation strengthened:

- selected option check icons so state is not color-only;
- explicit disabled/unavailable copy and semantics;
- larger add-on touch targets;
- long label wrapping;
- exact-size phone viewport tests at 390x844 and 430x932;
- text scale 1.2 exercised;
- fixed navigation no longer overlaps scrolled Item-detail content.

This is not a claim of full WCAG conformance. Tablet/landscape and deeper screen-reader audits remain future review areas.

Stable automation/test surfaces should be preserved when refactoring.

## Responsive behavior

Phone-first. Validated customization viewports include approximately 390x844 and 430x932.

The Menu rail remains a deliberate phone layout constraint; tablet/web-specific customer redesign is not currently claimed.

## Golden / visual QA policy

Do not update goldens merely to make a test pass. Review candidate changes deliberately.

The TASK-MENU-CUSTOMIZATION-001 menu golden change is intentional because non-product Add-ons content is no longer customer-browseable. New item-detail customization goldens cover representative phone widths and were reviewed against the AIDA palette/typography/control language.

## Maintenance rules

- Keep server `MenuItem.imageUrl` primary.
- Keep add-ons hidden from normal browse but available via product compatibility.
- Keep Temperature/Sweetness catalogue-driven; do not hardcode business availability in Flutter.
- Keep client totals explicitly estimate-only until quote.
- Keep cart line identity sensitive to option/add-on selections.
- Keep `Now` as copy only; do not rename the backend `asap` enum without a contract decision.
- Keep scheduled values inside `OrderingPolicy` / `derivePickupSlots`.
- Do not add local café-hours/capacity constants as authority.
- Preserve the existing AIDA colors/type/tactile controls rather than copying reference-app branding.
- Do not promote Rewards visuals into loyalty authority.

## Verification

TASK-MENU-CUSTOMIZATION-001 customer validation commit:

`404662aec382364c8e70fcee8d66b38d4b303f0a`

Environment/results:

- Flutter 3.44.7;
- Dart 3.12.2;
- JDK 21.0.12;
- format PASS, 86 files / 0 changes;
- analyze PASS, no issues;
- tests PASS, 55 passed / 0 failed / 0 skipped;
- `git diff --check` PASS;
- secret scan PASS;
- exact-size UI/golden review PASS at 390x844 and 430x932.

No Android device was connected for this final validation pass; mobile UI evidence is widget/golden based rather than physical-device smoke.

Full cross-repository evidence: `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`.

## 2026-09-09 audited UI refresh — TASK-UI-REDESIGN-004

The later `customer-app-redesign` branch was audited against current `master` before integration. It mixed production UI with unfinished privacy/referral/loyalty work and demo-only order/test tooling.

The accepted active presentation delta adds/refines:

- bundled Splash presentation before the unchanged `AuthGate`;
- refreshed launcher artwork;
- shared `AidaPopup` feedback;
- Home visual refinements;
- Menu local search over the shared catalogue;
- unified Size/Temperature/Sweetness card presentation;
- refreshed Cart and Order confirmation visuals;
- refreshed Membership QR ticket presentation;
- Profile collapsing header/bento layout;
- a new Settings presentation over existing providers/actions;
- refreshed Rewards ticket/voucher presentation;
- visible labels and safer bottom-inset handling in the five-tab shell.

Useful future work is preserved without being silently activated:

- account-deletion SQL/test prototypes live under `supabase/drafts/`;
- referral/points SQL prototype lives under `supabase/drafts/`;
- account-deletion client UI/RPC path requires `AIDA_ENABLE_ACCOUNT_DELETION_DRAFT=true`;
- referral signup/share/real-points path requires `AIDA_ENABLE_REFERRAL_DRAFT=true`;
- both feature flags default to false.

Demo-only order/status/test tooling is deliberately excluded.

The following invariants are mandatory after this refresh:

- Splash never owns or fabricates authentication state;
- Menu search is local filtering only;
- configured/cart amounts remain estimates until server quote;
- Add to cart returns immediately to Menu;
- Checkout Schedule remains the accepted policy-derived wheel;
- Order confirmation consumes persisted backend status only;
- no local/demo order-status provider exists;
- the production membership action remains member-code copy until referral activation;
- Privacy/Terms remain explicitly unavailable until real destinations exist;
- draft SQL is not canonical/deployed migration state.

Detailed audit evidence: `UI_REDESIGN_AUDIT_2026-09-09.md`.

