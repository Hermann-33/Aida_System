# Customer Mocks and Placeholders Register

Updated: 2026-08-20

## Removed from production runtime

- hardcoded menu categories/items/prices/availability/images as commercial catalogue authority;
- static Small/Medium/Large `ItemSize` enum and deltas;
- category-name logic for whether sizes/add-ons apply;
- fake catalogue ratings and bonus-point presentation;
- random local order-number generation;
- local-only `PastOrder` persistence/history as order truth;
- fixed/local order status authority;
- timer-driven fulfilment progression;
- cart-derived subtotal as final trusted order total;
- payment-method copy implying a processor payment succeeded;
- absence of server-policy-backed ASAP/Schedule-for-later selection;
- the old explicit `AidaLogo` placeholder box: the shared widget now uses the bundled `assets/images/aida_logo.jpg` presentation asset.

Customer catalogue/order flows now fail visibly when the backend boundary fails; they do not fall back to sample commercial/order authority.

## Presentation assets versus trusted data

The redesign adds/uses bundled imagery, but these assets are presentation only:

- `aida_logo.jpg` is a bundled logo image used by the shared `AidaLogo` widget and Rewards watermark. It is not member/identity data.
- category cut-out art may be used by the Menu category rail and as `MenuListItem` image fallback. It does not replace the server `MenuItem.imageUrl`, product ID, name, availability or price.
- `ProductImage` still prefers a non-empty server `imageUrl` and falls back gracefully when it is absent or fails to load.

Because the logo is bundled, its use on Membership QR does not add a network dependency to the offline-critical card.

## Test-only data

`test/support/test_catalogue_repository.dart` is an explicit catalogue fixture used only for isolated test/golden coverage. `test/support/test_order_repository.dart` is likewise test-only order coverage. Neither is wired as a production fallback.

The test order repository records quote requests so post-redesign tests can prove that the scheduled checkout UI submits server-policy-derived timestamps. This instrumentation exists only in `test/`.

## Allowed local UI state

The following may remain local because they are interaction state rather than trusted business authority:

- cart selections before quote;
- selected item/variant/add-on/quantity/note choices;
- selected ASAP vs scheduled option before server validation;
- Menu category/favorites selection;
- temporary loading/error/expanded/collapsed/animation state;
- local display estimates before authoritative quote;
- one placement `clientRequestId` retained across retries of the same intended order;
- local favourites and other explicitly non-authoritative presentation state.

Once quoted/placed, displayed commercial totals, order number and fulfilment status come from the backend response/snapshot.

## Rewards mixed-data boundary

The redesigned Rewards screen is intentionally mixed, not wholly mock:

- member name/code presentation comes from `displayedMemberProvider`, whose base is the real owner-scoped Supabase member/profile read;
- points, reward catalogue and vouchers remain delegated to `MockMemberRepository` pending the trusted loyalty task.

A real member name beside a preview points balance does not make the balance authoritative. Reward redemption and voucher consumption are still deferred.

## Payment demo boundary

Until a real payment task exists, use explicit `Pay at counter`/unpaid semantics. Do not fake payment-success state, processor transactions or refunds.

## Still preview/untrusted beyond this tranche

- loyalty points/stamps/rewards/vouchers and redemption/consumption;
- offers/promotions as trusted commercial authority;
- real payment/refund handling;
- inventory/depletion;
- branch-capacity/opening-hours scheduling;
- tax/accounting;
- notifications;
- trusted reporting;
- several profile/settings/support surfaces;
- hosted production deployment/release operations.

The final live order E2E validates the current trusted Auth/catalogue/order boundary but does not promote these deferred areas to production authority.

See `UI_REDESIGN_AUDIT_2026-08-20.md` for the post-merge redesign audit.
