# Dashboard State and Data Flow

Updated: 2026-09-15

**Current live boundary:** Phases 1–7 `COMPLETE`.

The Dashboard/Admin/POS application is a thin privileged client over the shared Supabase backend. Live privileged calls use the same-origin BFF; preview mode is presentation-only and isolated from privileged APIs.

## Employee/session flow

```text
browser login/employee action
 -> same-origin BFF
 -> Supabase Auth / caller-bound RPC
 -> HttpOnly employee access + refresh cookies
 -> trusted user_profile role/disabled-state checks
```

Browser JavaScript does not own reusable employee bearer tokens. Terminal credentials likewise remain HttpOnly/server-held.

## Topology and shift flow

```text
Admin branch/sales-point/terminal UI
 -> BFF -> caller-bound admin RPCs -> trusted topology

POS request
 -> server-held terminal credential
 -> terminal context + employee branch scope
 -> open shift requirement
 -> POS order/cash authority
```

A new POS order requires current employee/terminal authorization and an open shift. Matching idempotent retries can resolve an already accepted order without creating new shift authority.

## Catalogue, scheduling and inventory

Catalogue reads/writes use the shared canonical catalogue. Branch pickup configuration owns timezone, windows/exceptions, lead/horizon/slot interval and capacity. Inventory administration owns branch stock, recipes and movements.

POS quote/place does not calculate accepted prices, pickup capacity or stock outcome in the browser. Supabase validates and returns them.

## Loyalty and voucher flow

```text
POS member intent / Admin loyalty support
 -> BFF
 -> caller-bound loyalty RPCs
 -> member loyalty account / reward / voucher authority

order quote/place with voucher intent
 -> server validates ownership/status/expiry/eligibility
 -> accepted voucher discount snapshot
 -> one-time consumption at placement
```

Points, stamps, rewards and vouchers shown in live Dashboard flows come from trusted backend state. Preview fixtures do not become live loyalty authority.

## Phase 7 promotion flow

```text
/admin/rewards/campaigns
 -> promotion BFF route
 -> get_promotion_admin_state / save_promotion
 -> server-owned promotion + scope tables
```

Admin/Owner can configure fixed/percentage offers, windows, subtotal/cap, priority, exclusive/stackable mode, voucher coexistence, member/usage limits and branch/product/variant/add-on scope.

POS order flow:

```text
cart/member/voucher intent
 -> authoritative quote_order
 -> schedule + stock + voucher validation
 -> automatic promotion evaluation
 -> voucherDiscountSen + promotionDiscountSen + discountSen + totalSen
 -> POS presentation

place
 -> deterministic promotion locks + full revalidation
 -> accepted order
 -> immutable voucher/promotion application snapshots
```

The browser never submits an accepted promotion ID or authoritative promotion discount. A promotion shown on the accepted order is a server snapshot.

## Order board and status

Order lists/snapshots are strict-parsed. Commercial arithmetic must reconcile before the UI trusts the payload. Staff status transitions use server authorization and expected `statusVersion`; display concepts such as due/overdue do not mutate persisted status.

## Preview isolation

Preview mode may provide deterministic fixtures for visual testing, but it must not call privileged live routes. Browser CI contains a blocking preview-isolation regression. Live mode must fail closed rather than silently substitute fixture authority.

## Deferred flows

Phase 8 will replace/extend reporting/accounting/audit presentation with trusted derived reports. Phase 9 owns external payment/refund/settlement integrations. Hardware and Badge/PIN lifecycle remain separately deferred. Phase 10 owns final release/App Store verification.
