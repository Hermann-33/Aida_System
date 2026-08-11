# Fragile Boundaries

## Highest-risk files

| File | Coupling / assumption | Integration risk | Change rule |
|---|---|---|---|
| `lib/application/providers.dart` | Repository binding, navigation, derived reads, auth, profile overlay, cart, favorites, history | One integration edit can change unrelated sessions/tabs/data; logout isolation incomplete | Split only under explicit architecture scope with broad tests |
| `lib/domain/repository/member_repository.dart` | Single broad port, reads/auth only | “Swap one class” claim hides missing write/quote/order contracts | Evolve contracts deliberately; do not leak Supabase types into domain |
| `lib/data/repository/mock_member_repository.dart` | All demo truth and UI-shaping values | Real adapter may accidentally preserve fake prices/rules/IDs | Keep as dev/test fixture; mark every promoted value with verified source |
| `lib/main.dart` | Root auth lifecycle | Boolean-to-real-session change affects boot, logout, deep links, errors | Add session states/tests before altering gate behavior |
| `features/shell/app_shell.dart` | Indexed tab lifetime, floating cart, tab navigation | State retention and overlays can break with router/auth changes | Preserve tab/overlay behavior or document replacement |
| `domain/model/cart.dart` | Client price arithmetic and line identity | Cannot be authoritative after server quoting; configuration IDs may change | Retain display estimate only if clearly separated from server quote |
| `features/cart/cart_screen.dart` | Prices, random order, payment, history, navigation in one file | Highest tampering/false-completion surface | Replace in slices: quote, create order, then status/history |
| `domain/model/order.dart` | Single `ready` status and local receipt | Inadequate for real lifecycle, cancellations, failures, schedule | Introduce server contract without mapping mock enum directly to schema |
| `features/card/membership_card_screen.dart` | QR payload plus unsupported local-storage/offline claim | Blank QR offline; shared screenshot may be treated as authorization | Define cache and POS verification before changing payload |
| `features/home/home_screen.dart` | 995-line composition plus widget-local check-in | Many providers/actions/animations; easy regressions | Do not mix loyalty integration with unrelated UI refactors |
| `features/menu/item_detail_screen.dart` | 984-line route, local configuration, price preview, favorites/cart | Catalogue model changes ripple through UI/calculation | Establish variant/modifier DTO mapping and tests first |
| `features/profile/profile_screen.dart` | Real rows mixed with placeholder rows | UI can imply unavailable account/security functions | Preserve explicit placeholder labels until real flows exist |

## Mock data influencing UI assumptions

- Four fixed category names also control size applicability and image/category styling.
- Add-ons are modelled as menu items and referenced by ID lists.
- Price previews assume uniform size deltas.
- Reward track design assumes a narrow three-tier ladder.
- QR assumes one permanent, directly displayable member code.
- `StudentStatus` is three states; operational verification may need richer audit state.
- `OrderStatus` has only `ready`.
- Payment selection assumes four methods and labels “Pay” even though processing is absent.
- Remote Unsplash image dimensions/availability influence current layouts and goldens.

Do not translate these assumptions into tables/enums without product and operational review.

## Navigation/state fragility

- Tab navigation is provider state, while detail flows use a separate imperative Navigator stack.
- Home can mutate Menu filters before switching tabs.
- `IndexedStack` preserves tab scroll/provider/widget state.
- Auth logout does not reconstruct `ProviderScope`; session state may remain.
- Promo cards accept an optional callback but Home omits it, creating a visually active dead end.
- No deep-link/back-stack contract exists.

A routing/auth migration must test tab preservation, back behavior, cart overlay, sign-out clearing, and direct-entry handling.

## Visual/test fragility

- Golden files are sensitive to fonts, Flutter renderer/version, clock, network image fallback, and platform pixel behavior.
- Four current golden comparisons fail. Do not update baselines until diff images are visually reviewed and intended UI/runtime changes are identified.
- Screenshot references under `docs/screenshots/` are documentation, not automated acceptance baselines.

## Boundaries not to change without explicit scope

- Currency representation in integer sen.
- Server authority over totals, loyalty, eligibility, roles, IDs, and status.
- Static QR risk/verification direction.
- Riverpod-to-domain repository separation.
- Auth/session storage and logout isolation.
- Customer/POS/admin application ownership.
- Supabase migration and RLS workflow.
- Golden baselines, production assets, app identifiers, signing, and dependencies.
