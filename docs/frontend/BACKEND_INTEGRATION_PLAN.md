# Customer Backend Integration Plan

Updated: 2026-08-17

## Auth/member — integrated and validated

Supabase Auth and owner-scoped member/profile reads are integrated. Canonical live SQL regression and the full Flutter suite pass. ADR-0003's minimum offline QR material is cached durably per user and cleared on logout/user switch.

Physical Android validation proved release connectivity, customer signup, trusted profile/member provisioning and Dashboard Members visibility. The final live order E2E also authenticated a real customer normally with exactly one active member.

## Catalogue — integrated and validated

Customer menu uses `CatalogueRepository` → Supabase `get_catalogue()`. One snapshot feeds categories, featured/popular and menu items. `catalogue_revision` Realtime events invalidate that snapshot. Base prices, availability, images, per-item variants and compatible add-ons come from database records.

Production runtime has no hardcoded migrated catalogue or `ItemSize` pricing authority. A real Owner catalogue price mutation was observed in the installed Android app after revision invalidation/refetch.

## Orders and scheduled pickup — integrated and validated

ADR-0010 and `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md` are authoritative.

The customer backend boundary provides:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- owner-scoped `orders` Realtime

### Implemented Flutter integration

1. Keep the cart as **selection state**, not commercial authority.
2. Build trusted payloads from catalogue item IDs, variant IDs, compatible add-on IDs, quantities and notes.
3. Read `get_ordering_policy()` to offer ASAP vs Schedule for later.
4. Generate scheduled slots from backend `serverNow`, timezone, lead, interval and horizon rather than a device-clock-only hardcode.
5. Call `quote_order()` before placement and render the returned authoritative subtotal/total/line prices.
6. Require a signed-in active member for customer placement; trusted identity/member state is derived server-side.
7. Generate one UUID `clientRequestId` for an intended placement and reuse it for network retries of that same order.
8. Clear the cart only after a successful persisted placement.
9. Use the server `orderNumber`, total and status.
10. Use `get_my_orders()` / `get_order()` for history/detail.
11. Subscribe to owner-authorized `orders` changes and re-fetch; persisted status replaces fake timer progression.
12. Preserve the existing AIDA visual language; this integration does not create a second design system.

### Scheduling rules

Current defaults:

- `Asia/Kuala_Lumpur`
- 15-minute minimum lead
- 15-minute slots
- 7-day maximum advance

Branch opening-hours/capacity are not modeled and must not be presented as validated guarantees.

### Payment presentation

No real payment processor exists. The current authoritative demo path is explicit `Pay at counter`/unpaid. Cash/Card/E-wallet/Student Wallet must not be presented as successfully processed backend payment state.

## Realtime/error behavior

- Catalogue: `catalogue_revision` → re-fetch catalogue.
- Orders: authorized `orders` change → re-fetch full order with `get_order()`.
- If quote/placement fails because catalogue/schedule state changed, surface an actionable error and keep the cart for correction/retry.
- Do not silently fall back to local totals or local order history after a backend error.

## Final customer validation result

Customer implementation is COMPLETE for the current tranche:

- Flutter 3.44.9 `pub get`: PASS
- analyze: PASS, no issues
- tests: PASS, 44/44
- release APK: PASS
- independent clean-worktree release build: PASS
- final APK declares `android.permission.INTERNET`
- canonical Auth/member, catalogue and order SQL regressions: PASS transactionally
- physical Android signup/member provisioning: PASS
- Owner catalogue mutation → installed app refresh: PASS

Final cross-client order proof on 2026-08-17 used the supported customer boundary to quote Sandwich ASAP at 1,290 sen and persist order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`). Customer-authorized `get_order` reads then observed Dashboard-persisted `preparing`, `ready` and `completed` states. The final status is `completed`, version 4.

## Deferred customer domains

Loyalty earning/redemption, real payments/refunds, notifications, student-review workflow, profile writes beyond current authority, branch-specific scheduling/capacity, inventory, reporting and hosted production release operations remain separate tasks.
