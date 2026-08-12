# Customer Mocks and Placeholders Register

Updated: 2026-08-13

## Removed from production runtime

- hardcoded menu categories/items/prices/availability/images;
- static Small/Medium/Large `ItemSize` enum and deltas;
- category-name logic for whether sizes/add-ons apply;
- fake catalogue ratings and bonus-point presentation.

Customer catalogue now fails visibly if the backend is unavailable; it does not fall back to sample menu data.

## Test-only

`test/support/test_catalogue_repository.dart` is an explicit 4-category/16-item test fixture and is never wired as a production fallback. Its values exist to keep isolated widget/golden coverage representative of the canonical seed.

## Still preview/untrusted

Loyalty/rewards/offers/promos, local cart/checkout/order tracking/history and other not-yet-integrated domains remain preview until their bounded backend tasks.
