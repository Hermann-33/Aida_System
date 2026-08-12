# Customer Mocks and Placeholders Register

Updated: 2026-08-13

## Removed from production runtime

- hardcoded menu categories/items/prices/availability/images;
- static Small/Medium/Large `ItemSize` enum and deltas;
- category-name logic for whether sizes/add-ons apply;
- fake catalogue ratings and bonus-point presentation.

Customer catalogue now fails visibly if the backend is unavailable; it does not fall back to sample menu data.

## Test-only catalogue data

`test/support/test_catalogue_repository.dart` is an explicit 4-category/16-item test fixture and is never wired as a production fallback. Its values exist only to keep isolated widget/golden coverage representative of the canonical seed.

## Removed order/checkout placeholders

The live customer runtime no longer uses these obsolete placeholders:

- random local order-number generation in checkout;
- local-only `PastOrder` persistence/history as order truth;
- the fixed local `OrderStatus.ready` model;
- the timer-driven confirmation timeline that automatically moves through preparing/ready;
- cart-derived subtotal being treated as the final trusted order total;
- payment-method copy that implies Cash/Card/E-wallet/Student Wallet was actually processed;
- absence of server-policy-backed ASAP/Schedule-for-later selection.

ADR-0010 and `ORDER_AND_SCHEDULING_CONTRACT.md` now replace them while preserving the existing visual design. The explicit test repository remains test-only.

## Allowed local UI state after integration

The following may remain local because they are interaction state, not trusted business authority:

- current cart selections before quote;
- selected item/variant/add-on/quantity/note choices;
- selected ASAP vs scheduled option before server validation;
- temporary loading/error/expanded/collapsed state;
- a placement `clientRequestId` retained across retries of the same intended order.

Once quoted/placed, displayed commercial totals/order number/status must come from the backend response.

## Payment demo boundary

Until a real payment task exists, use an explicit `Pay at counter`/unpaid demo path. Do not fake payment-success state or a processor transaction.

## Still preview/untrusted beyond this task

Loyalty/rewards/offers/promotions, real payment/refund handling, inventory, branch-capacity scheduling, tax/accounting, notifications and reporting remain preview/unimplemented until their bounded trusted backend tasks.
