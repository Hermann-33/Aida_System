# Order and Scheduling Contract

**Updated:** 2026-09-15  
**Current extension:** Phase 7 generalized promotion/discount authority  
**Status:** `COMPLETE` through Phase 7

## Trusted order intent

Clients submit product/customization quantity/note, fulfilment, branch/pickup, tender where permitted, and optional member/voucher intent. Clients are never authority for prices, totals, discount, accepted promotion IDs, order IDs/numbers, customer/member identity, topology, shift, payment state, inventory result, voucher state, promotion usage state, `prepareAt`, schedule capacity or fulfilment status.

Promotions are selected automatically from server configuration. A client does not claim that a promotion applies and does not submit an authoritative promotion discount.

## Quote authority

`quote_order(jsonb)` validates catalogue/customizations, branch/pickup policy and inventory. It optionally validates caller/member-bound voucher intent, then evaluates eligible active promotions from trusted configuration.

The authoritative Phase 7 quote returns:

- `subtotalSen`;
- `voucherDiscountSen`;
- `promotionDiscountSen`;
- total `discountSen`;
- `totalSen`;
- optional voucher snapshot;
- ordered promotion snapshots;
- trusted line and scheduling snapshots.

The commercial invariant is:

```text
voucherDiscountSen + promotionDiscountSen = discountSen
totalSen = subtotalSen - discountSen
sum(lineTotalSen) = subtotalSen
```

Quote is advisory/read-only: it does not consume inventory, a voucher or a promotion use.

## Promotion evaluation

A promotion may be constrained by active window, minimum subtotal, branch scope, product/variant/add-on scope, member requirement, voucher coexistence, global usage limit and per-member usage limit.

Fixed discounts use integer sen. Percentage discounts use basis points and may have a maximum discount. Promotion evaluation is ordered by priority/code/id. Exclusive promotions terminate selection; stackable promotions may compose according to server stacking rules and remaining order value.

## Placement authority

Customer placement derives customer/member from Auth. POS placement derives topology from the server-held terminal credential and requires current employee authorization plus an open shift for a new order.

Placement revalidates schedule/capacity, inventory, voucher intent and promotions transactionally. Candidate promotion rows are locked in deterministic order before final evaluation so usage counts remain stable during placement.

A matching persisted POS retry may be returned after the original shift is later locked/closed only if current employee/terminal authority still resolves and the payload/tender/topology context matches. This does not permit a new order without an open shift and does not consume a promotion twice.

## Immutable commercial snapshot

Accepted order commercial state includes integer-sen subtotal, voucher discount, promotion discount, total discount and total plus line/customization snapshots.

If a voucher is used, `voucher_order_applications` stores an immutable code/reward/type/discount snapshot.

Each accepted promotion is persisted in `promotion_order_applications` with immutable promotion code/name, discount type/value, accepted `discount_sen`, priority, stacking mode and voucher-coexistence snapshot. Later promotion configuration changes do not rewrite accepted orders.

The sum of persisted promotion application discounts must equal authoritative `promotionDiscountSen`, and voucher + persisted promotion discount must equal `orders.discount_sen`.

Phase 3 whole-account deletion may perform only the narrow internal identity/request-digest anonymization transition; accepted product/price/topology/payment/voucher/promotion discount facts remain intact.

## Scheduling and inventory

Server branch policy owns timezone/windows/exceptions, lead/horizon/slot interval and capacity. `prepare_at` is server-derived. Quote checks recipe stock; placement performs atomic non-negative stock consumption; cancellation writes exactly-once inventory reversals.

## Fulfilment

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Transitions require authorization and expected `statusVersion`; time never auto-mutates status. Completion remains the loyalty earning boundary and is idempotently anchored per order.

Cash-paid cancellation remains blocked pending the later refund authority path.

## Validation and live deployment

Validated implementation heads:

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Canonical Phase 7 migrations:

```text
20260915100000_create_promotion_discount_authority.sql
20260915101000_integrate_promotions_with_order_authority.sql
20260915101100_normalize_phase7_nullable_voucher_quote.sql
```

Live AIDA history maps them to:

```text
20260915120917_create_promotion_discount_authority
20260915121057_integrate_promotions_with_order_authority
20260915121119_normalize_phase7_nullable_voucher_quote
```

Project `eswovqxqzfevcdwwcmuh` is `ACTIVE_HEALTHY`. Live checks confirmed Phase 7 RLS/FORCE RLS, revoked direct table access, intended RPC/function presence and grants, retirement of the pending-voucher trigger, and fresh advisors with no new blocking Phase 7 finding.

The SQL inspection connector runs as `supabase_read_only_user` and cannot assume the app `anon` role, so it cannot directly invoke `quote_order` as an end user. Application-role runtime behavior is covered by the blocking database/client/browser regression gates; live verification intentionally did not create production test promotions or orders.

Phase 8–10 remain frozen pending explicit owner authorization.
