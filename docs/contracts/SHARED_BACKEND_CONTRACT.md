# Shared Backend Contract

Updated: 2026-09-16

**Current runtime boundary:** Phases 1–8 engineering `COMPLETE`. Phase 9 is the next authorized implementation boundary. The independent/Astra/Codex audit is deferred to one cumulative Phase 1–10 audit after Phase 10.

AIDA has one shared backend for the Flutter customer app and the Dashboard/Admin/POS application. Canonical executable database migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Authority model

Supabase/server is authoritative for authenticated identity, trusted roles/disabled state, membership, employee branch scope, branches/sales points/terminals, terminal credential validity, shifts/cash, catalogue/pricing, pickup scheduling/capacity, inventory/recipes/depletion, loyalty/rewards/vouchers, promotions/discounts, order IDs/numbers/status/commercial totals, privacy/account deletion and the source facts used by Phase 8 reporting.

Clients submit intent. They do not author accepted commercial facts, protected topology, payment outcome, stock/capacity outcome, promotion eligibility or report facts.

## Dashboard trust boundary

Dashboard privileged requests use a same-origin BFF. Employee access/refresh and terminal credentials remain HttpOnly. The BFF forwards the caller JWT and publishable Supabase key. Normal browser flows do not use a service-role credential and do not expose reusable employee bearer/terminal secrets to JavaScript.

Preview fixtures are presentation-only. Blocking browser coverage proves Phase 8 preview reporting does not call privileged reporting endpoints.

## Customer trust boundary

The customer app uses caller-bound Supabase Auth/RPC access. Public catalogue/legal/support surfaces do not require unnecessary authentication. Personalized membership, loyalty, wallet, ordering, privacy and deletion capabilities require the appropriate authenticated customer identity.

## Ordering/commercial invariant

```text
voucherDiscountSen + promotionDiscountSen = discountSen
totalSen = subtotalSen - discountSen
sum(lineTotalSen) = subtotalSen
```

Quote does not reserve stock, pickup capacity, vouchers or promotion usage. Placement revalidates and commits them transactionally. Idempotent retries return the accepted order and do not double-consume resources.

## Phase 8 reporting contract

Authenticated Admin/Owner read surfaces:

```text
get_admin_reporting_summary(jsonb)
get_admin_transaction_report(jsonb)
get_admin_audit_events(jsonb)
```

Rules:

- public RPCs are `SECURITY INVOKER` and authenticated-only;
- private implementations are caller-bound `SECURITY DEFINER` functions with empty `search_path`;
- filters are bounded by date range, branch/sales-point topology, page size and offset;
- values come from persisted Phase 1–7 facts;
- accepted order value is not processor settlement;
- voucher/promotion discounts remain separate and reconcile to total discount;
- cancelled orders are excluded from accepted commercial totals;
- paid POS cash is reported only from persisted cash+paid POS facts;
- processor capture/settlement/refunds are explicitly unavailable until Phase 9;
- audit output contains only durable source-backed events and declares known historical coverage gaps;
- reporting creates no mutation authority and widens no direct table grants.

## Phase 8 live/validation baseline

```text
Aida_System             d56aa67d34a2bb006fe60033513c3fdf29b2c092
Aida_System-Dashboard   36024d78778e86aa94ef8bc8a5602780e95f47c0
Backend database audit #252   COMPLETE
Dashboard CI #175              COMPLETE
Canonical migration    20260916100000_create_reporting_audit_authority.sql
Live migration         20260916013938_create_reporting_audit_authority
```

Fresh live advisors show no Phase 8-created WARN/ERROR.

## Phase 9 boundary

Phase 9 must introduce provider-neutral payment/refund authority without weakening the above contract. Trusted state must distinguish payment intent, authorization, capture, settlement/reconciliation, failure/cancellation and refunds. External processor outcomes may only be recorded from authenticated provider/server evidence; clients cannot self-declare paid/refunded/settled states. Cash/unpaid POS semantics remain valid.

Processor-specific activation, merchant onboarding, provider credentials/webhook secrets or paid services require explicit owner approval.
