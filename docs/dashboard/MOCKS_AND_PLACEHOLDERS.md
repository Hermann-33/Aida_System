# POS/Admin Mocks and Placeholders Register

Updated: 2026-08-17

## No longer preview in trusted current paths

The following are live/shared-backend integrations rather than preview authority:

- protected Admin Members directory;
- Admin Menu categories/items/prices/publication/availability/variants/add-on compatibility;
- POS catalogue browsing/customization;
- authoritative POS quote/place;
- ASAP/scheduled pickup policy;
- live order queue/detail;
- versioned fulfilment status transitions.

`PREVIEW_MENU`, `PREVIEW_CATEGORIES`, `PREVIEW_MODIFIER_GROUPS` and preview transaction/order records are not runtime authority for those trusted paths.

## Removed order/POS preview authority

The active POS placement and Orders rail no longer treat these as trusted persistence/business truth:

- client-computed cart/order totals shown as final;
- preview/local order records standing in for persisted orders;
- preview order-number generation;
- fake checkout/tender/payment success;
- local-only order lifecycle/status;
- preview orders as queue fallback;
- fake status progression or local completion authority.

The existing POS surfaces use `/api/v1/orders/*` without replacing the established AIDA design system.

## Allowed local UI state

The browser may keep:

- current unsaved cart selections;
- item/variant/add-on/quantity/note interaction state;
- local estimate before server quote;
- selected ASAP/scheduled intent before quote;
- view/filter/dialog/loading/error state;
- one `clientRequestId` reused across retries of the same intended placement.

Persisted quote total, order number, schedule acceptance and order status come from the BFF/backend.

## Payment demo boundary

No trusted processor exists. Use explicit `Pay at counter`/unpaid semantics. Existing tender/payment previews must not be presented as settled real transactions.

## Still preview/deferred beyond TASK-CLOSEOUT-001

- loyalty/rewards;
- terminal/device enrolment authority beyond current preview/local behavior;
- shift/cash authority;
- branches/branch scope and employee-management mutations not yet backed by trusted server contracts;
- inventory and depletion;
- marketing publication;
- real payment/refund processing;
- tax/accounting;
- sales/revenue reporting;
- branch opening-hours/capacity scheduling;
- many settings/integration/audit presentation surfaces;
- hosted production deployment/release operations.

Admin Inventory and Sales Performance may intentionally derive demo rows from preview fixtures; those rows remain outside production inventory/reporting authority and must not be used as order/catalogue truth.

The final live order E2E validates the current trusted order path only; it does not promote these deferred domains.
