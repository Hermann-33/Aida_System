# Dashboard Backend Integration Plan

Updated: 2026-09-15

This document describes the **current integration state through Phase 7** and the remaining later-phase work. It is not an implementation wishlist for already-completed capabilities.

## Current architecture

Dashboard/Admin/POS uses the shared Supabase backend through a same-origin BFF. Employee session and terminal credential material stay HttpOnly/server-side. BFF handlers forward the caller JWT and publishable key so Supabase RPC/RLS remains authorization authority.

Production Dashboard must not use a service-role credential as a shortcut and must not expose reusable employee/terminal secrets to browser JavaScript.

## Integrated live capabilities

### Phase 1 — operational topology

Live branches, employee branch scope, sales points, terminals, enrolment/revocation and POS topology attribution.

### Phase 2 — shifts and cash

Open/resume/lock/close shift authority, cash movements/reconciliation/history and new-order open-shift enforcement.

### Phase 3 — customer/privacy dependency

Dashboard retained transaction views respect the customer anonymisation boundary; staff audit identity is not erased by customer self-deletion.

### Phase 4 — scheduling

Branch pickup policy, service windows/exceptions, lead/horizon/slot capacity and authoritative quote/place scheduling are live.

### Phase 5 — inventory and recipes

Branch inventory, movements, recipes/components and order-time transactional stock consumption/reversal are live.

### Phase 6 — loyalty/rewards/vouchers

Loyalty program/reward configuration, member wallet/support adjustments, POS member lookup and voucher-aware quote/place are live through caller-bound BFF/RPC flows.

### Phase 7 — promotions/discounts

`/admin/rewards/campaigns` is connected to live promotion authority. BFF endpoints use `get_promotion_admin_state` and `save_promotion`; the browser does not write promotion tables directly.

Campaign configuration supports fixed/percent discounts, minimum subtotal, optional cap, active windows, priority, exclusive/stackable behavior, voucher coexistence, member requirement, global/per-member limits and branch/product/variant/add-on scope.

POS quote/order parsing accepts separate `voucherDiscountSen` and `promotionDiscountSen` plus immutable promotion snapshots. Placement remains fully server-authoritative and re-evaluates promotions under deterministic locks.

## Integration invariants

- live mode never falls back to preview fixtures;
- preview mode never calls privileged live endpoints;
- client IDs/amounts are intent only unless explicitly documented as trusted server snapshots;
- all money is integer sen;
- accepted order history remains immutable/snapshotted;
- caller identity is derived from the authenticated session, not request-supplied actor IDs;
- branch/terminal/shift/payment/commercial state remains server-derived.

## Validation through Phase 7

```text
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Dashboard CI covers lint, typecheck, unit tests, live POS browser regression, preview isolation and production build. Backend CI covers cumulative migrations/regressions and true Phase 7 final-promotion-use contention.

Live AIDA Supabase is `ACTIVE_HEALTHY`; Phase 7 migrations are deployed and advisors show no new blocking Phase 7 finding.

## Remaining integration plan

### Phase 8 — reporting/accounting/audit

Replace remaining report/audit presentation with trusted read-only derived RPCs/views. Establish branch/timezone filters, revenue/order/cash/discount/loyalty/inventory reconciliation, export/access control and immutable audit-source semantics. Reports must not mutate source transactions.

### Phase 9 — payments/refunds/external integrations

Add processor-specific authority only after provider/credential/cost approvals. Model intent, authorization, capture, settlement, refund, webhook/idempotency and reconciliation separately. Preserve existing cash/unpaid semantics.

### Phase 10 — release

Production/release integration audit, legal/support URLs, privacy metadata/manifests, review credentials/demo path, release artifacts and current Apple rule verification.

## Explicitly separate/deferred

Badge/PIN credential provisioning and hardware integrations remain outside the completed Phase 1–7 backend integration unless a later approved scope explicitly takes ownership.
