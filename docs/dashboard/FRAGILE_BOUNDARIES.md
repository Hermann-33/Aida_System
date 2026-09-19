# Dashboard Fragile Boundaries

Updated: 2026-09-15

These boundaries are security/commercial invariants. UI convenience must not weaken them.

## 1. Same-origin privileged session

Employee access/refresh tokens and terminal credentials remain HttpOnly/server-side. Browser JavaScript must not receive reusable employee bearer tokens, refresh tokens, service-role credentials or terminal secrets. Dashboard BFF calls forward the caller JWT and publishable key and preserve Supabase authorization checks.

## 2. Preview is never authority

Preview fixtures are visual/test data only. Preview mode must not contact privileged APIs, and live failures must not silently fall back to preview state. This is a blocking browser regression.

## 3. Branch / terminal / shift attribution

The browser may request an action but cannot choose trusted terminal, branch, sales point or shift attribution. New POS orders require current employee/terminal authority plus an open shift. Idempotent retries cannot be used to create a new order after shift closure.

## 4. Commercial arithmetic

Catalogue price, subtotal, discount components and total are server-derived integer sen. Dashboard parsers fail closed when line totals, subtotal, voucher/promotion discount components or total do not reconcile.

```text
voucherDiscountSen + promotionDiscountSen = discountSen
totalSen = subtotalSen - discountSen
```

## 5. Scheduling and inventory

Pickup availability, capacity and `prepareAt` are server-owned. Inventory/recipe availability is advisory at quote and transactionally consumed at placement. The Dashboard must not infer acceptance from local clocks, displayed stock or optimistic UI.

## 6. Loyalty and vouchers

Member lookup is caller/terminal/open-shift bound for POS. Voucher ownership, status, expiry, reward eligibility and one-time consumption are server-owned. Changing or clearing a POS member must invalidate stale voucher intent rather than carrying it across identities.

## 7. Phase 7 promotions

Campaign configuration is Admin/Owner-only through caller-bound RPCs. Direct promotion-table authority is revoked.

The browser must never:

- submit an accepted promotion ID as order authority;
- calculate the accepted promotion discount;
- assume a quoted promotion is reserved;
- infer usage-limit availability from cached campaign state;
- rewrite an accepted promotion snapshot after configuration changes.

Placement re-evaluates promotions after deterministic candidate-row locks. A concurrent last-use race may remove a discount without invalidating the underlying purchase; the accepted placement response is authoritative.

Exclusive/stackable behavior, voucher coexistence, member requirement, usage limits, branch/catalogue scope, active window and minimum subtotal are server rules.

## 8. Accepted order history

Voucher and promotion applications are immutable commercial facts. UI edits to campaign/reward/catalogue configuration must never rewrite accepted orders. Cancellation/refund changes must use explicit server-controlled state/compensating events, not destructive history edits.

## 9. Customer privacy

Admin/POS surfaces must not regain customer identity after whole-account deletion by retaining browser caches or fixture identifiers. Legitimately retained commercial history is non-identifying under the documented deletion boundary.

## 10. Deferred boundaries

Reporting/accounting/audit is Phase 8 and must be derived read authority. External payment capture/refunds/settlement is Phase 9. Badge/PIN provisioning and hardware integrations remain deferred. Final production/App Store release checks are Phase 10.
