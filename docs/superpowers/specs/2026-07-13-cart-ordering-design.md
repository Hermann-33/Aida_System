# Cart & Ordering — Design Spec

| Field | Detail |
|---|---|
| **Component** | Customer App — Cart, Item Configuration, Favorites |
| **Date** | 13 July 2026 |
| **Status** | Approved for implementation |
| **Supersedes** | The browse-only v1 decision recorded in `2026-07-10-aida-customer-app-design.md` §2 and PRD v2.2 |

## 1. Why This Exists

v1 was scoped browse-only: no cart, no ordering, tapping an item just showed detail. The client asked for real ordering controls (size, add-ons, quantity, "Add to Cart") three times across three separate screens before it was clear this was a genuine requirement, not a one-off styling reference. This spec reopens that scope deliberately, with explicit boundaries on what "real" means here.

## 2. What "Real" Means: Checkout Has No Backend

**Decision:** Checkout ends in a convincing confirmation screen. No order is persisted anywhere beyond the running app session, and nothing is sent to a backend, because no backend exists yet for this project (§3.3 of the unified PRD — the customer app's own repository is still `MockMemberRepository`).

This is not a limitation to work around — it is the correct scope for this stage. The cart and checkout flow are built the same way everything else in this app has been: against a repository-shaped interface, in memory, so a real backend can be wired in later with the UI unchanged.

## 3. Scope Decisions

| Question | Decision | Reasoning |
|---|---|---|
| Size variants | **Yes** — Small / Medium / Large | Explicit client request. |
| Size price scheme | M = current price, S = −RM 1.00, L = +RM 1.50, uniform | **Placeholder.** Same caveat as every price in this app: real deltas are the owner's call. |
| Which items get sizes | Coffee and Iced Drinks only | Food and Add-ons items don't have size variants in any real café. |
| Add-ons | Per-item compatibility checklist | Client explicitly chose this over "browse add-ons as separate items." |
| Add-on compatibility | Coffee + Iced Drinks → Extra Shot / Oat Milk / Whipped Cream. Food/Add-ons → none. | Reasonable default; flagged as needing a sanity check, not a verified business rule. |
| Special instructions | Free-text note per cart line | Client request ("a note if he wants something special"). |
| Favorites | Session-only, in-memory | Client's explicit choice, made after being told this means favorites reset on app close. Documented here as a known, accepted limitation — not an oversight. |
| Favorites access | Heart toggle on Item Detail header; a filter toggle on Menu to view favorited items only | No dedicated favorites screen — reuses the category-filter mechanism already built. |
| Cart access | Floating bar above the bottom nav, visible on any tab once the cart is non-empty | Preserves the nav's existing 5-slot layout and the QR's centered elevation (CUS-17); this is also how the reference app itself does it. |
| Order outcome | Mock order number, cart cleared, no persistence | Per §2. |
| Payment method selector | Shown on the Cart screen for completeness, using the real methods already in PRD §13.3 (Cash/Card/E-wallet/Student Wallet) | Not wired to any processor. Reuses documented data instead of inventing a new concept. |

## 4. Domain Model Additions

```
ItemSize          — enum { small, medium, large }, each with a price delta
CartLineItem      — { item, size?, addOnIds, quantity, note? } + computed line price
Cart              — { lineItems } + computed subtotal
MenuItem          — gains `compatibleAddOnIds: List<String>` (empty by default)
```

Two line items merge into one (quantity increments) only when item, size, add-ons, and note all match exactly. Any difference — including a different note — is a separate line. This matches how every real cart works: a "no ice" latte and a plain latte are different orders.

## 5. State

`CartNotifier` and `FavoritesNotifier` — both plain in-memory Riverpod `Notifier`s, both cleared on app restart, following the same pattern as every other provider in this app. No new persistence dependency is introduced.

## 6. Screens

**Item Detail (extended):** size picker (only where sizes apply), add-ons checklist (only where compatible), quantity stepper, note field, favorite heart in the header, "Add to Cart" showing a live computed price. The old single "+" button is removed here — a real cart makes it redundant.

**Cart / Checkout (new):** line items with their configuration shown, quantity +/−, remove, computed subtotal, a payment-method selector, "Place Order."

**Order Confirmation (new):** mock order number, thank-you message, "Back to Menu" — clears the cart.

**Floating cart bar (new, shared):** lives in the app shell, shown on any tab whenever the cart is non-empty. Shows item count and subtotal. Tapping it opens Cart.

**Menu (extended):** a favorites-filter toggle in the header, reusing the existing category-filter logic with an added boolean dimension.

**Popular Picks grid card:** the existing non-functional "+" (added and explicitly flagged as decorative in an earlier commit) is **retired** in favor of this real cart. It either opens detail directly (where the real Add to Cart lives) or is removed; decided during implementation, not a scope question.

## 7. Edge Cases

- Sold-out items can still be favorited, but Add to Cart is disabled — a customer may want it back on the menu later.
- Removing the last cart line hides the floating bar automatically (it's driven by cart emptiness, not a separate visibility flag).
- Changing size or add-ons on the detail page updates the shown price live, before the item is added.

## 8. Testing

- Cart merge logic: identical configuration merges quantity; any differing field (size, add-ons, note) produces a separate line.
- Price computation: size delta + sum of add-on prices, matches the displayed live price.
- Favorites toggle persists across navigation within a session (Riverpod state) and is empty again after a simulated fresh app start.
- Floating bar visibility tracks cart emptiness exactly.

## 9. Open Items (Not Blocking This Implementation)

- Real size price deltas — owner decision, pending.
- Add-on compatibility mapping — reasonable default in place, pending a sanity check.
- Whether favorites should eventually persist to device storage — deferred; this spec explicitly scopes it out per §3.
