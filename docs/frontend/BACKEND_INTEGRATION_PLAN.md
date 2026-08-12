# Customer Backend Integration Plan

Updated: 2026-08-13

## Auth/member

Supabase Auth and owner-scoped member/profile source exist on the auth stack. Canonical live SQL regression and the full Flutter suite passed before TASK-DEMO-ORDER-001. ADR-0003's minimum offline QR material is cached durably per user and cleared on logout/user switch. Deployed/device Auth E2E remains open because approved real identities are absent.

## Catalogue — integrated

Customer menu uses `CatalogueRepository` -> Supabase `get_catalogue()`. One snapshot feeds categories, featured/popular and menu items. `catalogue_revision` Realtime events invalidate that snapshot. Base prices, availability, images, per-item variants and compatible add-ons come from database records.

Production runtime has no hardcoded migrated catalogue or `ItemSize` pricing authority.

## Orders and scheduled pickup — backend ready, Flutter integration next

ADR-0010 and `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md` are authoritative.

The live backend now provides:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- owner-scoped `orders` Realtime

### Required Flutter integration

1. Keep the current cart as **selection state**, not commercial authority.
2. Build a trusted payload from catalogue item IDs, variant IDs, add-on IDs, quantities and notes.
3. Read `get_ordering_policy()` to offer ASAP vs Schedule for later.
4. Generate selectable scheduled slots from backend `serverNow`, timezone, lead, interval and horizon rather than a device-clock-only hardcode.
5. Call `quote_order()` before final placement and render the returned authoritative subtotal/total/line prices.
6. Require a signed-in customer for placement. `place_customer_order()` derives trusted customer/member identity server-side.
7. Generate a UUID `clientRequestId` once for a placement attempt and reuse that same UUID for network retries. Generate a new UUID only when starting a genuinely new order placement.
8. Clear the cart only after the backend returns a successful persisted order.
9. Replace random local order numbers with `orderNumber` from the backend.
10. Replace local-only `PastOrder` authority with `get_my_orders()`/`get_order()` snapshots.
11. Subscribe to owner-authorized `orders` changes and re-fetch the affected order; persisted backend status replaces the current fake timer progression.
12. Preserve the current AIDA cart, confirmation and history visual language. This is an integration, not a redesign.

### Scheduling rules the UI must reflect

Current defaults:

- `Asia/Kuala_Lumpur`
- 15-minute minimum lead
- 15-minute slots
- 7-day maximum advance

Do not claim branch opening-hours/capacity validation because the backend does not yet model it.

### Payment presentation

No real payment processor exists. Remove/disable UI that implies Cash/Card/E-wallet/Student Wallet was actually processed. For the demo use an explicit `Pay at counter`/unpaid flow. Do not display `Payment received` as a trusted backend state.

## Realtime/error behavior

- Catalogue: `catalogue_revision` -> refetch catalogue.
- Orders: authorized `orders` change -> refetch full order with `get_order()`.
- If a quote/placement fails because an item/variant/add-on became unavailable, surface a theme-consistent actionable message and keep the cart for correction/retry.
- Do not silently fall back to local totals/order history after a backend error.

## Customer validation result

Implemented on the shared task branch. Flutter 3.44.9 passes pub get, zero-issue analyze and 40/40 tests, including quote/scheduling/idempotency/cart/history-status/Realtime behavior. No golden baseline changed. Deployed real-identity cross-client proof remains external work under ADR-0004.

## Validation required after frontend implementation

- `flutter pub get`
- `flutter analyze`
- full `flutter test`
- focused quote/scheduling/idempotency/history/Realtime provider/repository tests
- deliberate golden review for any changed cart/confirmation/history screens
- no blind `--update-goldens`
- cross-client demo proof once approved identities exist

## Deferred customer backend domains

Loyalty earning/redemption, real payments/refunds, notifications, student-review workflow, profile writes beyond current authority, branch-specific scheduling/capacity, inventory and reporting remain separate tasks.
