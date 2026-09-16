# Shared Backend Contract

Updated: 2026-09-16

**Current runtime boundary:** Phases 1–7 `COMPLETE`; Phase 8 implementation/live backend `COMPLETE`, formal Phase 8 verdict `PARTIAL` pending the independent/Astra audit gate.

AIDA has one shared backend for the Flutter customer app and the Dashboard/Admin/POS application. Canonical executable database migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Authority model

Supabase/server is authoritative for:

- authenticated identity, trusted application role and disabled state;
- members and employee branch scope;
- branches, sales points and terminals;
- terminal credential validity and shift/cash state;
- catalogue items, variants, add-ons and prices;
- branch pickup policy, service windows, exceptions, lead/horizon/slot capacity and server-derived preparation time;
- recipes, branch inventory, transactional depletion and cancellation reversals;
- loyalty balances, earning, rewards, vouchers and one-time voucher consumption;
- promotion configuration, eligibility, stacking, usage limits and accepted promotion applications;
- order IDs/numbers, commercial totals, status/version, topology and accepted history;
- customer privacy preferences and whole-account deletion/anonymisation boundary;
- source facts used by Phase 8 reporting/reconciliation/audit projections.

Clients may submit intent, but never accepted commercial facts or privileged topology/identity state. Phase 8 report clients submit filters only; they do not author report facts.

## Dashboard trust boundary

Dashboard privileged requests use a same-origin BFF. Employee access/refresh and terminal credentials remain HttpOnly. The BFF forwards the caller JWT and publishable Supabase key; normal flows do not use a service-role credential and do not expose reusable employee bearer or terminal secrets to browser JavaScript.

Preview fixtures are presentation-only and never replace unavailable live authority. Phase 8 browser regression explicitly proves preview reporting pages do not call privileged reporting endpoints.

## Customer trust boundary

The customer app uses caller-bound Supabase Auth/RPC access. Public catalogue/legal/support surfaces do not require creation of an anonymous Auth identity. Personalized member, loyalty, wallet, ordering, privacy and deletion capabilities require the appropriate authenticated customer identity.

Phase 8 adds no customer mutation surface and does not change customer commercial authority.

## Ordering and commercial contract

Clients submit catalogue selections, quantities, customizations/notes, fulfilment/pickup intent, an idempotent `clientRequestId`, and optional member/voucher intent where permitted. They do not submit authoritative prices, totals, accepted promotion IDs, payment state, schedule capacity or inventory outcome.

`quote_order(jsonb)` derives the authoritative quote. The commercial invariant remains:

```text
voucherDiscountSen + promotionDiscountSen = discountSen
totalSen = subtotalSen - discountSen
sum(lineTotalSen) = subtotalSen
```

Quote does not reserve stock, pickup capacity, a voucher, or promotion usage. Placement transactionally revalidates all of them.

## Promotion contract

Promotions are configured by Admin/Owner through caller-bound RPCs and may be scoped by branch, product, variant and add-on. Server rules own active windows, minimum subtotal, fixed-sen or percentage-basis-point value, optional maximum discount, priority, exclusive/stackable behavior, voucher coexistence, member requirement, global usage limit and per-member usage limit.

Clients do not choose accepted promotions. Placement locks candidate promotion rows in deterministic order, re-evaluates eligibility and usage, and persists immutable accepted snapshots in `promotion_order_applications`. Voucher and promotion applications remain distinct facts while reconciling exactly to `orders.discount_sen`.

Idempotent retries return the accepted order and do not consume voucher, promotion, inventory or pickup capacity twice.

## Phase 8 reporting contract

Phase 8 exposes three read-only authenticated Admin/Owner RPCs:

```text
get_admin_reporting_summary(jsonb)
get_admin_transaction_report(jsonb)
get_admin_audit_events(jsonb)
```

The public functions are `SECURITY INVOKER`; guarded private implementations are caller-bound and `SECURITY DEFINER` with empty `search_path`.

Reporting rules:

- report filters are bounded by validated date range, branch/sales-point relationship, page size and offset;
- report values are derived from persisted Phase 1–7 source facts;
- commercial totals are labelled accepted order value, not processor settlement;
- voucher and promotion discounts remain separate and reconcile to total discount;
- cancelled orders are excluded from accepted commercial totals;
- paid POS cash is reported only from persisted `cash` + `paid` POS order facts;
- processor capture/settlement/refunds are explicitly unavailable until Phase 9;
- inventory quantities remain grouped by inventory item/base unit rather than collapsed across incompatible units;
- the audit projection exposes only durable source-backed events and declares known historical coverage gaps instead of fabricating them;
- the reporting RPCs create no mutation authority and do not widen direct table grants.

## Privacy and retained history

Whole-account deletion is caller-bound and cannot target another user. Customer-owned identity/member/loyalty state is removed; retained order/loyalty/promotion commercial facts are anonymised or detached where required while preserving legitimate non-identifying transaction history. Customer-authored free text and the original customer request digest are scrubbed by the documented deletion boundary.

Phase 8 transaction reporting does not expose customer PII merely because it exists in source tables; only the bounded operational/commercial fields in the report contract are returned.

## Phase 8 validation and live baseline

Implementation/live validation immediately before final Phase 8 documentation refresh:

```text
Aida_System             bde55b9e4ec20f95bb19d041b33a068e18f4abb6
Backend database audit #249   COMPLETE

Aida_System-Dashboard   8cc99f77bba8e4ff355e4c0a246a8a79742d1406
Dashboard CI #173              COMPLETE
```

Canonical Phase 8 migration:

```text
20260916100000_create_reporting_audit_authority.sql
```

Live AIDA migration-history entry:

```text
20260916013938_create_reporting_audit_authority
```

Fresh live security/performance advisors show no Phase 8-created warning/error. The pre-existing Supabase Auth leaked-password-protection warning remains documented separately.

## Next boundary

Phase 8 implementation, repository validation and live deployment/advisors are complete. Formal Phase 8 status remains `PARTIAL` until the required independent/Astra audit boundary is completed or explicitly accepted. Phase 9 payments/refunds/external integrations must not begin before that gate is resolved.
