# Customer Mocks and Placeholders Register

Updated: 2026-08-17

## Removed from production runtime

- hardcoded menu categories/items/prices/availability/images;
- static Small/Medium/Large `ItemSize` enum and deltas;
- category-name logic for whether sizes/add-ons apply;
- fake catalogue ratings and bonus-point presentation;
- random local order-number generation;
- local-only `PastOrder` persistence/history as order truth;
- fixed/local order status authority;
- timer-driven fulfilment progression;
- cart-derived subtotal as final trusted order total;
- payment-method copy implying a processor payment succeeded;
- absence of server-policy-backed ASAP/Schedule-for-later selection.

Customer catalogue/order flows now fail visibly when the backend boundary fails; they do not fall back to sample commercial/order authority.

## Test-only data

`test/support/test_catalogue_repository.dart` is an explicit catalogue fixture used only for isolated test/golden coverage. `test/support/test_order_repository.dart` is likewise test-only order coverage. Neither is wired as a production fallback.

## Allowed local UI state

The following may remain local because they are interaction state rather than trusted business authority:

- cart selections before quote;
- selected item/variant/add-on/quantity/note choices;
- selected ASAP vs scheduled option before server validation;
- temporary loading/error/expanded/collapsed state;
- local display estimates before authoritative quote;
- one placement `clientRequestId` retained across retries of the same intended order;
- local favourites and other explicitly non-authoritative presentation state.

Once quoted/placed, displayed commercial totals, order number and fulfilment status come from the backend response/snapshot.

## Payment demo boundary

Until a real payment task exists, use explicit `Pay at counter`/unpaid semantics. Do not fake payment-success state, processor transactions or refunds.

## Still preview/untrusted beyond this tranche

- loyalty/rewards/offers/promotions;
- real payment/refund handling;
- inventory/depletion;
- branch-capacity scheduling;
- tax/accounting;
- notifications;
- trusted reporting;
- several profile/settings/support surfaces;
- hosted production deployment/release operations.

The final live order E2E validates the current trusted Auth/catalogue/order boundary but does not promote these deferred areas to production authority.
