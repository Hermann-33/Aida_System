# POS/Admin Mocks and Placeholders Register

Updated: 2026-08-13

## No longer preview in Admin Menu or POS browsing

Admin Menu categories/items/prices/publication/availability/variants/add-on compatibility come from the shared Supabase catalogue through the BFF. POS menu/category cards and modifier choices use the same shared snapshot. `PREVIEW_MENU`, `PREVIEW_CATEGORIES` and `PREVIEW_MODIFIER_GROUPS` are not runtime catalogue authority.

## Order/POS placeholders that must now be replaced by frontend integration

The authoritative order/scheduling backend is live, so these runtime concepts can remain only as temporary UI interaction state—not trusted persistence/business truth:

- client-computed POS cart/order totals shown as if final;
- preview/local order records standing in for persisted orders;
- preview order-number generation;
- fake checkout completion/tender/payment success;
- local-only order lifecycle/status;
- absence of the live Scheduled/Confirmed/Preparing/Ready staff queue;
- absence of server-policy-backed ASAP/Schedule-for-later placement.

Codex must connect the existing POS surfaces to `/api/v1/orders/*` without redesigning the application.

## Allowed local UI state after integration

The browser may keep:

- current unsaved cart selections;
- item/variant/add-on/quantity/note interaction state;
- selected ASAP/scheduled intent before quote;
- view/filter/dialog/loading/error state;
- one `clientRequestId` reused across retries of the same intended placement.

But the persisted quote total, order number, schedule acceptance and order status must come from the BFF/backend.

## Payment demo boundary

No trusted processor exists. Use an explicit `Pay at counter`/unpaid path. Existing tender/payment previews must not be presented as settled real transactions in the integrated demo order flow.

## Still preview beyond TASK-DEMO-ORDER-001

- loyalty/rewards;
- terminal/shift authority not already backed by trusted identity;
- branches/branch scope;
- inventory and depletion;
- marketing;
- real payment/refund processing;
- tax/accounting;
- sales/revenue reporting;
- branch opening-hours/capacity scheduling;
- most settings.

Admin Inventory and Sales Performance may still intentionally derive fake/demo rows from preview fixtures; they must remain clearly outside production inventory/reporting authority and must not be used as order/catalogue truth.