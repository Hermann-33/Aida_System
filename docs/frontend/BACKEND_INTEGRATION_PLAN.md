# Customer Backend Integration Plan

Updated: 2026-08-14

ADR-0003, ADR-0004, ADR-0009, ADR-0010 and the shared backend/order contracts remain authoritative.

## Auth/member — integrated and physically validated

Implemented customer boundaries:

- Supabase Auth sign-up/sign-in/session/logout;
- trusted customer profile/member provisioning;
- server-generated member code;
- student self-declaration -> pending only;
- owner-scoped profile/member reads;
- minimum per-user offline member-code cache with logout/user-switch cleanup;
- public project URL/publishable-key configuration only.

TASK-AUTH-006 fixed Android release networking by adding `android.permission.INTERNET` to the main manifest. The user installed the fixed release app and successfully created a real customer. The resulting trusted member appeared in Dashboard Members.

Account-recovery delivery/callback behavior was not part of that manual closeout evidence and must not be overstated.

## Catalogue — integrated and physically validated

Customer menu uses `CatalogueRepository` -> Supabase `get_catalogue()`. One authoritative snapshot feeds categories, featured/popular and menu/item detail. `catalogue_revision` Realtime events invalidate/refetch that snapshot.

Base prices, publication, availability, images, per-item variants and compatible add-ons come from the database. Production runtime has no hardcoded migrated catalogue or `ItemSize` price authority.

The user physically validated a real Dashboard Owner price mutation -> Supabase catalogue revision/data -> installed Android customer UI update.

## Orders and scheduled pickup — customer integration implemented

Customer Flutter consumes:

- `get_ordering_policy()`
- `quote_order(jsonb)`
- `place_customer_order(jsonb)`
- `get_order(uuid)`
- `get_my_orders(integer)`
- owner-scoped `orders` Realtime invalidation

Current behavior:

1. Cart remains selection/interaction state, not trusted commercial authority.
2. Order payloads contain catalogue item IDs, variant IDs, add-on IDs, quantities, notes and fulfilment intent only.
3. Checkout reads server ordering policy and supports ASAP / Schedule for later.
4. Schedule slots derive from server policy/timezone/lead/interval/horizon.
5. `quote_order()` runs before placement; backend line prices/subtotal/total win.
6. Placement requires the authenticated active customer/member; identity derives server-side.
7. A UUID `clientRequestId` is reused for retries of the same placement intent.
8. Cart clears only after successful persisted placement and remains on failure.
9. Server `orderNumber`, total, schedule and status replace local/random authority.
10. Order history/detail use backend snapshots rather than local `PastOrder` truth.
11. Owner-authorized order changes invalidate/refetch the affected backend snapshot.
12. No client timer manufactures Preparing/Ready status.
13. Demo payment presentation is explicit **Pay at counter / unpaid** only.

Current scheduling defaults are Asia/Kuala_Lumpur, 15-minute minimum lead, 15-minute slots and 7-day maximum advance. Branch opening hours/closures/capacity are not modeled.

## Error/offline boundaries

- Catalogue failure is visible; no production fixture fallback.
- Quote/place validation failures retain the cart for correction/retry.
- Realtime disconnect does not create local status authority; refresh can re-read trusted state.
- Minimum offline member-code cache is not an offline order queue and never stores role/pricing/order authority.
- Transport errors use bounded user-safe connectivity messages without exposing raw host/token details.

## Android release build — runtime fixed, reproducibility pending closeout

The fixed APK physically reaches Supabase. One engineering gate remains: release build configuration must be reproducible from committed Git.

At the TASK-CLOSEOUT-001 starting point the repository still pins AGP 8.7.0 while the resolved AndroidX set requires AGP 8.9.1+. The prior successful APK used preserved local build compatibility settings. Closeout must commit a supported AGP/Gradle/Kotlin combination and prove a clean-worktree release build with INTERNET permission present.

## Validation evidence already available

- TASK-AUTH-006 Flutter 3.44.9 analyze: pass.
- TASK-AUTH-006 full tests: 44/44 pass.
- Final TASK-AUTH-006 APK declared `android.permission.INTERNET`.
- User physical customer signup succeeded from the fixed release app.
- New customer appeared in Dashboard Members.
- User physical Dashboard catalogue mutation -> customer app refresh succeeded.
- Earlier customer order-focused suites passed quote/scheduling/idempotency/cart/history/status/Realtime behavior.

Dated live evidence is recorded in `docs/context/CLOSEOUT_EVIDENCE_2026-08-14.md`.

## Remaining customer closeout gates

1. Make the Android release toolchain reproducible from committed Git in a clean worktree.
2. Rerun full Flutter analyze/tests/release build on the final closeout head.
3. Rerun applicable Auth/catalogue/order backend/security regressions without leaving synthetic data.
4. Coordinate with Dashboard closeout to prove customer placement -> staff transition -> customer authorized status refresh.
5. Reconcile byte-identical mirrored shared documentation before merge.

No additional manual phone validation is required merely to repeat the already-proven Android networking/Auth/catalogue paths unless closeout materially changes those runtime boundaries.

## Deferred customer backend domains

Loyalty earning/redemption, real payment/refunds, notifications, student-review workflow beyond current pending declaration, profile writes beyond current authority, branch-specific scheduling/capacity, inventory and reporting remain separate bounded tasks.
