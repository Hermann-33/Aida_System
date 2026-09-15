# Order and Scheduling Contract

**Updated:** 2026-09-15  
**Current extension:** Phase 6 loyalty/voucher commercial authority  
**Status:** `COMPLETE` through Phase 6

## Trusted order intent

Clients submit product/customization quantity/note, fulfilment, branch/pickup, tender where permitted, and optional member/voucher intent. Clients are never authority for prices, totals, discount, order IDs/numbers, customer/member identity, topology, shift, payment state, inventory result, voucher state, `prepareAt`, schedule capacity or fulfilment status.

## Quote authority

`quote_order(jsonb)` validates catalogue/customizations, branch/pickup policy and inventory. In Phase 6 it optionally validates caller/member-bound voucher intent and returns server-derived `discountSen` and `totalSen`. Quote does not consume inventory or a voucher.

## Placement authority

Customer placement derives customer/member from Auth. POS placement derives topology from the server-held terminal credential and requires current employee authorization plus an open shift for a new order. Placement revalidates schedule/capacity, inventory and voucher intent transactionally.

A matching persisted POS retry may be returned after the original shift is later locked/closed only if current employee/terminal authority still resolves and the payload/tender/topology context matches. This does not permit a new order without an open shift.

## Immutable commercial snapshot

Accepted order commercial state includes integer-sen subtotal, discount and total plus line/customization snapshots. If a voucher is used, `voucher_order_applications` stores an immutable code/reward/type/discount snapshot. Later reward/catalogue changes do not rewrite accepted orders.

Phase 3 whole-account deletion may perform only the narrow internal identity/request-digest anonymization transition; accepted product/price/topology/payment/discount facts remain intact.

## Scheduling and inventory

Server branch policy owns timezone/windows/exceptions, lead/horizon/slot interval and capacity. `prepare_at` is server-derived. Quote checks recipe stock; placement performs atomic non-negative stock consumption; cancellation writes exactly-once inventory reversals.

## Fulfilment

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Transitions require authorization and expected `statusVersion`; time never auto-mutates status. Completion is the Phase 6 loyalty earning boundary and is idempotently anchored per order.

Cash-paid cancellation remains blocked pending the later refund authority path.

## Validation

Backend database audit #190 passed the complete cumulative order/scheduling/shift/privacy/inventory/loyalty regression suite. Customer release audit #281 and Dashboard CI #126 are also `COMPLETE`.