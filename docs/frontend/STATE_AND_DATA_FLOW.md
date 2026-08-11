# State and Data Flow

## Provider inventory

All application-wide providers live in `apps/customer/lib/application/providers.dart`.

| Provider/state | Type | Source/lifetime | Consumers |
|---|---|---|---|
| `memberRepositoryProvider` | `Provider<MemberRepository>` | Binds const mock adapter | All repository-backed operations |
| `authStateProvider` | `Notifier<bool>` | Memory; starts false | `AuthGate`, logout/login |
| `selectedTabProvider` | `Notifier<AppTab>` | Memory; starts Home | Shell, Home/Profile cross-tab actions |
| `selectedCategoryProvider` | `Notifier<String?>` | Memory | Home-to-Menu and Menu filter |
| `favoritesOnlyProvider` | `Notifier<bool>` | Memory | Home Favorites action, Menu |
| `memberProvider` | `FutureProvider<Member>` | Mock repository | Displayed member overlay |
| `memberEditsProvider` | `Notifier<Member?>` | Session overlay | Edit profile/sign-up/displayed member |
| `displayedMemberProvider` | derived provider | Base member plus local edits | Home, QR, Profile |
| points/stamps/offers/featured/promos/categories/popular/rewards/vouchers/menu | `FutureProvider` | Mock repository with synthetic latency | Corresponding screens |
| `cartProvider` | `Notifier<Cart>` | Memory | Item detail, floating bar, cart, checkout |
| `favoritesProvider` | `Notifier<Set<String>>` | Memory | Item detail/Menu |
| `orderHistoryProvider` | `Notifier<List<PastOrder>>` | Memory | Checkout/history |

`offersProvider` and `featuredItemProvider` are defined but no inspected screen watches them. Home uses `promosProvider` and `popularItemsProvider` instead.

## Repository and service flow

`MemberRepository` is the only port. It supports:

- sign-in/sign-up/reset request;
- member, points, stamps, rewards, vouchers, offers;
- featured item, promos, categories, popular items, full menu.

`MockMemberRepository` is the only implementation. It sleeps for 400 ms and returns Dart constants or values relative to `DateTime.now()`.

No service/client exists for profile writes, favorites, quote, checkout, order history/status, check-in, redemption, voucher use, image upload, notification, analytics, or payment.

## Model flow

```text
Mock Dart constants
  -> domain models (`Member`, `MenuItem`, `Points`, ...)
  -> `Result<T>`
  -> `_unwrap` throws typed Failure into Riverpod `AsyncValue`
  -> widgets render loading/data/error
```

No DTO-to-domain mapping or serialization boundary exists. Domain models are therefore both UI/domain shapes and mock transport shapes today.

## Auth/session flow

### Current

1. `AuthGate` watches a false boolean.
2. Sign-in calls the mock, which always returns `Ok`.
3. Provider boolean flips true; shell renders.
4. Sign-up calls the mock, then generates `m_<milliseconds>` and `AIDA-####-####` client-side and stores a session member overlay.
5. Logout resets the boolean and clears only profile/member edits. Cart, favorites, tab/category, and order history are not explicitly cleared by logout.
6. Restart loses all state.

### Real connection point

Introduce an auth/session adapter and a multi-state auth controller. Bootstrap the verified current user/profile/member, isolate/clear per-user state, and make route access respond to refresh/revocation. Member ID/code must come from the trusted system.

## Menu flow

### Current

Mock repository returns all menu items and derived categories/popular items. Menu filters locally by category/favorite. Item detail receives a `MenuItem` object by route and resolves compatible add-on IDs against the same list.

### Real connection point

Load an authoritative catalogue snapshot with stable IDs, availability, variants/modifiers, and image references. Preserve client filtering/cache if suitable, but refresh/invalidate changes and revalidate at quote/order time.

## Cart/quote/order flow

### Current

1. Item detail builds `CartLineItem` from widget state.
2. `cartProvider` merges equal configurations.
3. `Cart` and `addOnTotalFor` calculate prices from mock `MenuItem` values.
4. Cart selects a local payment enum.
5. `_placeOrder` generates a random order number, snapshots subtotal/lines, appends `PastOrder`, clears cart, and opens confirmation.
6. Confirmation advances stages on a two-second timer.
7. History displays this in-memory snapshot; status is always `ready`.

### Real connection point

Send item/variant/modifier IDs and quantities to a trusted quote operation; display its authoritative totals/expiry. Create an idempotent order from the accepted quote and server-selected payment/pickup rules. Read owner-scoped history/status and update from staff operations.

## Loyalty/reward/voucher flow

### Current

- Points/stamps/reward catalogue/vouchers are mock reads.
- Reward affordability is a local comparison for button enablement.
- Redeem only displays a message.
- Voucher Apply only displays counter instructions.
- Home check-in mutates widget-local weekday state; it does not affect points/stamps.

### Real connection point

Use server-owned ledgers/balances and atomic idempotent operations for reward issue/use. The client may show cached balances with timestamps but must submit intent, not a claimed balance. Staff/POS must authorize consumption. Decide whether check-in is a real program before modelling it.

## Profile/membership flow

### Current

Mock member loads through a `FutureProvider`; profile edits overlay a copied member in memory. QR encodes `member.memberCode`; no durable storage exists despite the offline-intent comment.

### Real connection point

Use owner-scoped profile update operations, separate self-editable fields from verified/admin fields, server-issue the member code, and define encrypted/durable local caching appropriate to each platform. QR lookup/use belongs to a staff/POS flow and must not authorize by code possession alone.

## Error flow

Typed failures exist, and repository results are unwrapped into `AsyncValue`. The mock does not generate realistic error cases. Several screens collapse errors to generic/empty UI. Adapter tests must exercise network/auth/validation/insufficient-points/expired-voucher/server failures and verify cache/retry/logout behavior.
