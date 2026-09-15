# System Map

Updated: 2026-09-15

| System | Runtime | Trusted source |
|---|---|---|
| Customer | Flutter/Riverpod | Supabase Auth/member + catalogue/order/branch/loyalty RPCs |
| Dashboard/Admin/POS | React/Vite | same-origin HttpOnly employee/terminal BFF + caller-JWT RPCs |
| Backend | Supabase | Auth, Postgres, FORCE RLS, controlled RPCs, authorized invalidation |

## Authority chain through Phase 6

```text
P1 branch -> sales point -> terminal -> employee scope -> POS attribution
P2 terminal + employee -> shift -> POS order / cash ledger
P3 customer -> privacy/deletion -> anonymized retained history
P4 branch calendar/policy -> pickup slot capacity -> accepted quote/order
P5 recipe -> branch inventory -> transactional depletion/reversal
P6 member -> points/stamps -> reward/voucher -> discount/consumption
```

Clients send intent. Supabase/server owns resulting identity, topology, shift/cash/payment/commercial, schedule, stock and loyalty state.

## Customer order flow

```text
catalogue + branch/pickup state + wallet
 -> cart / pickup / voucher intent
 -> quote_order
 -> server validates catalogue + branch + schedule + inventory + voucher
 -> authoritative subtotal/discount/total
 -> place_customer_order
 -> revalidation + capacity + inventory + voucher consumption in transaction
 -> immutable order/commercial snapshot
```

## POS flow

```text
HttpOnly employee session + HttpOnly terminal credential
 -> open shift
 -> member lookup (optional)
 -> catalogue/cart/member/voucher intent
 -> authoritative quote
 -> place_pos_order
 -> trusted topology + shift/tender + inventory + voucher authority
 -> persisted snapshot
```

Matching idempotent retries are resolvable under current terminal/caller authority even after the original shift is later locked/closed; new placement still requires an open shift.

## Privacy flow

```text
auth.uid()
 -> delete_own_account
 -> collect owned members/orders/vouchers
 -> delete customer-owned loyalty state
 -> detach identifying loyalty snapshot references
 -> scrub order line/event free text + original request digest
 -> anonymize retained customer order identity
 -> delete Auth/member/profile-owned state
```

## Validation boundary

```text
Backend database audit #190   COMPLETE
Customer release audit #281   COMPLETE
Dashboard CI #126             COMPLETE
Live Supabase deploy/advisors COMPLETE
```

Full Phase 6 evidence: `docs/context/PHASE_6_LOYALTY_REWARDS_VOUCHERS_CLOSEOUT_2026-09-15.md`.

## Deferred

Phase 7 promotions/discounts; Phase 8 reporting/accounting; external payment capture/refunds/settlement; employee credential lifecycle; hardware integrations; supplier/lot/procurement expansion; delivery/deployment-heavy production work.