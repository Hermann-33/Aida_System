# Shared Backend Contract

Updated: 2026-09-15

**Current runtime boundary:** Phases 1–7 `COMPLETE` against the validated implementation and live-Supabase boundary.

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
- customer privacy preferences and whole-account deletion/anonymisation boundary.

Clients may submit intent, but never accepted commercial facts or privileged topology/identity state.

## Dashboard trust boundary

Dashboard privileged requests use a same-origin BFF. Employee access/refresh and terminal credentials remain HttpOnly. The BFF forwards the caller JWT and publishable Supabase key; normal flows do not use a service-role credential and do not expose reusable employee bearer or terminal secrets to browser JavaScript.

Preview fixtures are presentation-only and never replace unavailable live authority.

## Customer trust boundary

The customer app uses caller-bound Supabase Auth/RPC access. Public catalogue/legal/support surfaces do not require creation of an anonymous Auth identity. Personalized member, loyalty, wallet, ordering, privacy and deletion capabilities require the appropriate authenticated customer identity.

## Ordering and commercial contract

Clients submit catalogue selections, quantities, customizations/notes, fulfilment/pickup intent, an idempotent `clientRequestId`, and optional member/voucher intent where permitted. They do not submit authoritative prices, totals, accepted promotion IDs, payment state, schedule capacity or inventory outcome.

`quote_order(jsonb)` derives the authoritative quote. Through Phase 7 the commercial invariant is:

```text
voucherDiscountSen + promotionDiscountSen = discountSen
totalSen = subtotalSen - discountSen
sum(lineTotalSen) = subtotalSen
```

Quote does not reserve stock, pickup capacity, a voucher, or promotion usage. Placement transactionally revalidates all of them.

## Phase 7 promotion contract

Promotions are configured by Admin/Owner through caller-bound RPCs and may be scoped by branch, product, variant and add-on. Server rules own active windows, minimum subtotal, fixed-sen or percentage-basis-point value, optional maximum discount, priority, exclusive/stackable behavior, voucher coexistence, member requirement, global usage limit and per-member usage limit.

Clients do not choose accepted promotions. Placement locks candidate promotion rows in deterministic order, re-evaluates eligibility and usage, and persists immutable accepted snapshots in `promotion_order_applications`. Voucher and promotion applications remain distinct facts while reconciling exactly to `orders.discount_sen`.

Idempotent retries return the accepted order and do not consume voucher, promotion, inventory or pickup capacity twice.

## Privacy and retained history

Whole-account deletion is caller-bound and cannot target another user. Customer-owned identity/member/loyalty state is removed; retained order/loyalty/promotion commercial facts are anonymised or detached where required while preserving legitimate non-identifying transaction history. Customer-authored free text and the original customer request digest are scrubbed by the documented deletion boundary.

## Validation baseline

Phase 7 implementation was validated at:

```text
Aida_System             c6abf24b498edb401af878f86d26e1c63a633121
Aida_System-Dashboard   7e14326253b263412da5fa38f47bb137c31d7379
Backend database audit #231   COMPLETE
Customer release audit #311   COMPLETE
Dashboard CI #147             COMPLETE
```

Canonical Phase 7 migrations are deployed to live project `eswovqxqzfevcdwwcmuh`, which is `ACTIVE_HEALTHY`. Fresh security/performance advisors show no Phase 7-created blocking finding; the pre-existing Auth leaked-password-protection warning remains documented.

## Next boundary

Phase 8 reporting/accounting/audit is the next implementation boundary. Reports must remain derived read authority over trusted source facts and must not become a second mutation or commercial-authority path.
