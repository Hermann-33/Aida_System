# Phase 9 Validation Notes — 2026-09-16

Status: `PARTIAL`

## Governance

Phases 1–8 engineering are `COMPLETE`. Independent/Astra/Codex audit is deferred by owner instruction to one cumulative Phase 1–10 audit after Phase 10. Normal Phase 9 engineering validation remains mandatory.

## Provider-neutral backend authority

Canonical migrations:

```text
supabase/migrations/20260916110000_create_payment_refund_authority.sql
supabase/migrations/20260916111000_grant_phase9_private_rpc_schema_usage.sql
supabase/migrations/20260917154500_reconcile_phase9_payment_refund_live_schema.sql
```

The main authority adds `orders.refunded_sen`, external tender/payment projection, non-secret provider activation metadata, provider-neutral payment intents/events, refund records/events, webhook digest/idempotency receipts, caller-bound payment-state/request RPCs, service-role-only provider event application, Admin/Owner cash refunds tied to a trusted open shift/cash-out movement, and cancellation protection while payment is unresolved. No processor is activated and no provider credentials/secrets are committed.

The `20260916111000` repair grants only `USAGE` on schema `private` to `authenticated` and `service_role` so SECURITY INVOKER wrappers can resolve explicitly granted private implementation functions. It does not grant table access or additional function execution.

`20260917154500` intentionally replays the already-validated `20260916110000` migration body. It exists only to reconcile live AIDA after an erroneous migration-service call recorded the Phase 9 migration name with comments instead of executing the canonical SQL. Clean repository replay remains authoritative and must prove that this duplicate/idempotent reconciliation migration is safe.

## Database regression status

`supabase/tests/payment_refund_authority_integration.sql` covers direct-table denial, intent idempotency, authorization/capture/settlement separation, provider-event replay conflicts, refund reservation, partial/full refund projection, cancellation protection, provider-unavailable failure and append-only history.

Backend database audit #266 on head `1f3a21939be72a10d871486295d31a80844b7094` passed the complete Phase 1–9 regression chain that existed at that head, including `Payment and refund authority regression` and the historical Phase 4–7 contention gates.

Two additional blocking Phase 9 gates are now committed and wired into `.github/workflows/backend-database-audit.yml`:

```text
supabase/tests/cash_refund_authority_integration.sql
supabase/tests/phase9_refund_concurrency_setup.sql
supabase/tests/phase9_refund_concurrency_regression.sh
```

The cash-refund regression performs real sales-point/terminal creation, terminal enrolment, open-shift authority, cash POS placement and `refund_cash_order`. It requires the payment projection to reconcile and an idempotent retry to leave exactly one succeeded refund row, one refund event and one matching `cash_out` movement.

The true-concurrency regression creates one trusted 1,000-sen captured external order, starts two independent authenticated Admin transactions requesting 600-sen refunds with different idempotency keys, deliberately holds the first order lock, and requires exactly one reservation to succeed. The loser must fail on remaining refundable balance. Postconditions require exactly one active refund reservation totaling 600 sen and no false succeeded-refund projection on the order.

Exact-head CI is required before these new gates are accepted as passing.

## Customer payment contract

The Flutter customer app now has a dedicated payment capability rather than mixing provider lifecycle into order placement:

```text
apps/customer/lib/domain/model/order_payment.dart
apps/customer/lib/domain/repository/payment_repository.dart
apps/customer/lib/data/repository/supabase_payment_repository.dart
apps/customer/lib/application/payment_providers.dart
apps/customer/test/domain/order_payment_phase9_contract_test.dart
```

`OrderPaymentSnapshot` strictly validates tender/payment state, provider-intent amount/currency, paid timestamps, refunded/refundable reconciliation, succeeded refund totals and total reserved refunds. External paid/refunded projections require a captured provider intent; cash payment cannot carry provider intent. `SupabasePaymentRepository` calls only the caller-bound `get_order_payment_state` and `request_external_payment` RPCs and maps provider-unavailable responses to a truthful unavailable result rather than fabricating processor success.

The customer release workflow was also corrected to recognize cumulative PR bases through Phase 9 (`codex/phase-7-promotions-discounts`, `codex/phase-8-reporting-accounting-audit`, `codex/phase-9-payments-refunds-integrations`). This prevents stacked Phase 9/10 client work from bypassing static analysis, non-golden tests, blocking goldens and release APK validation.


## Dashboard payment/refund contract

The Dashboard now has a same-origin Phase 9 payment/refund boundary:

```text
server/paymentBff.ts
server/paymentBff.test.ts
api/v1/admin/payments/state.ts
api/v1/admin/payments/refund.ts
src/features/payments/paymentClient.ts
src/features/payments/paymentClient.test.ts
```

Admin payment reads and refund requests reuse the HttpOnly employee session. Cash refunds additionally consume the HttpOnly terminal credential only inside the BFF before calling `refund_cash_order`; the browser never receives that credential. External refunds call only the authenticated caller-bound `request_external_refund` RPC. The BFF uses the Supabase publishable key plus caller JWT and never uses a service-role credential.

The strict Dashboard payment parser validates accepted order amount/currency against the latest intent, payment/tender states, paid timestamps, succeeded-refund reconciliation, active refund reservations and external captured-payment requirements. The existing order parser now accepts `external`, `pending`, `partially_refunded` and `refunded` and cross-checks its summary fields against the nested protected payment projection. Customer orders may use unpaid/external authority but can never acquire POS cash authority.

Dashboard CI remains required before this batch is accepted.


## Admin transaction refund workflow

`AdminTransactionsPage` now keeps Phase 8 accepted-order reporting semantics separate from Phase 9 payment authority. The transaction list continues to represent accepted commercial value; opening a live transaction loads `get_order_payment_state` through the Admin BFF for current tender, capture, settlement and refund facts.

The live drawer now:
- displays trusted tender/payment/refund state and provider lifecycle state;
- computes requestable refund balance from succeeded plus requested/processing reservations so the UI does not encourage over-reservation;
- submits integer-sen refund intent with a fresh idempotency key;
- uses the cash path only through the enrolled-terminal/open-shift BFF authority;
- labels external refunds as requests until provider success evidence exists;
- keeps all privileged payment/refund calls disabled in UI preview mode.

`src/features/admin/AdminTransactionsPage.test.tsx` covers protected payment-state loading, a cash-refund submission and preview isolation. Dashboard CI remains required before accepting the UI batch.


## Dashboard CI trigger repair

The Dashboard CI workflow previously targeted only pull requests into `main`, so the Phase 9 draft PR stacked on the validated Phase 8 branch could not produce exact-head CI. The workflow now also recognizes the cumulative remediation/Phase 7/Phase 8/Phase 9 bases. This restores mandatory lint, typecheck, unit, browser, preview-isolation and production-build validation for stacked Phase 9 work and the later Phase 10 branch.

Exact-head Dashboard CI remains required before accepting the Dashboard payment/refund batch.


## Phase 9 reporting and provider-capability completion

Canonical follow-up migration:

```text
supabase/migrations/20260918120400_upgrade_phase9_reporting_payment_facts.sql
```

This migration preserves immutable accepted order value while adding source-backed Phase 9 payment/refund reporting and provider capability enforcement.

- External refund insertion is guarded by `payment_refunds_provider_capability`; a provider whose non-secret configuration declares `supports_refunds=false` fails closed with `REFUND_PROVIDER_UNSUPPORTED`.
- `get_payment_provider_admin_state()` exposes Admin/Owner read-only non-secret provider activation/capability metadata only. It exposes no API key, webhook secret or merchant credential.
- `get_admin_reporting_summary` now layers trusted payment facts over the Phase 8 accepted-value report: captured gross, cash/external captured value, pending external value, succeeded refunds, cash/external refunds, net captured after refunds, payment-state counts and external settlement-state buckets. Accepted order value is not redefined as settlement.
- `paidPosCashSen` continues to represent gross paid POS cash accepted value even after a non-cancelled cash order becomes partially or fully refunded.
- `get_admin_transaction_report` now includes per-order `refundedSen`, `refundableSen`, active refund reservation total, reconciliation status, latest provider intent lifecycle and refund snapshots while keeping `totalSen` as the immutable accepted order value.
- `get_admin_payment_audit_events` provides a separate paged source-backed projection over append-only payment/refund events, including payload digests for reconciliation but never raw provider payloads or secrets.

Blocking regression:

```text
supabase/tests/payment_reporting_phase9_integration.sql
```

The regression proves unsupported external refunds fail closed, then enables refund capability and verifies capture → refund success, non-secret provider state, accepted/captured/refunded/net reporting reconciliation, transaction-level refund facts and payment/refund audit coverage. It is wired into the backend database audit. Exact-head CI remains required.


## Cumulative Phase 8 reporting regression repair

Because all canonical migrations are replayed before the regression suite, the historical Phase 8 reporting test must validate the cumulative Phase 9 read model rather than require Phase 9 fields to be absent. `reporting_accounting_audit_integration.sql` now preserves the original guarantees while asserting the upgraded contract:

- accepted order value remains distinct from processor settlement;
- refund/provider lifecycle availability is declared truthfully;
- the Phase 8 no-refund fixture has `refundedSen=0`, `refundableSen=totalSen`, zero reserved refunds, no provider intent and an empty refund list;
- discount and immutable order-line reconciliation remain unchanged.

This is a test expectation repair only; it does not weaken production authority.


## Dashboard provider-status and payment-audit read boundary

The Dashboard read side now exposes Phase 9 provider/payment reporting through separate same-origin contracts:

- `GET /api/v1/admin/payments/providers` → caller-bound `get_payment_provider_admin_state()`;
- `GET /api/v1/admin/reporting/payment-audit` → caller-bound `get_admin_payment_audit_events(jsonb)`.

The provider route returns non-secret capability/activation metadata only. The payment-audit route preserves its own pagination and coverage declaration instead of pretending to be merged into the older general audit stream.

`paymentClient.ts` now strictly parses provider environment/activation/channel/refund-capability metadata. `reportingClient.ts` now strictly parses Phase 9 payment summary facts, transaction refund/provider lifecycle facts and the separate payment-audit report. Tests cover caller-JWT/publishable-key forwarding, accepted-value versus refund/capture semantics, and raw-provider-payload exclusion. Dashboard CI remains required.

## Live AIDA reconciliation boundary — 2026-09-17

AIDA project `eswovqxqzfevcdwwcmuh` is visible and `ACTIVE_HEALTHY`.

Migration history contains:

```text
20260917055816_create_payment_refund_authority
```

Inspection of `supabase_migrations.schema_migrations.statements` proved that this live entry contains only comments saying the canonical repository body should be applied; it did not execute the Phase 9 DDL. Correspondingly, live inspection showed the expected Phase 9 payment/refund tables and `orders.refunded_sen` were absent. The later private-schema grant migration was also absent from live history and `service_role` did not have the required `private` schema usage.

No migration-history row will be rewritten or deleted. The corrective path is the new canonical reconciliation migration `20260917154500_reconcile_phase9_payment_refund_live_schema.sql`, followed by the normal migration/advisor/live verification gates.

## Current validation boundary

The repository contains the reconciliation migration, both missing payment/refund concurrency/cash-refund gates and the initial strict Flutter payment contract. Exact-head database and customer release CI are required on the latest Phase 9 branch tip before live reconciliation/client presentation is considered validated.

Next mandatory gates:

1. clean database audit on the reconciliation + cash-refund + contention head;
2. customer analysis/tests/goldens/release build for the new payment contract;
3. apply the reconciliation body and private-schema usage repair to live AIDA through migration tooling;
4. verify live Phase 9 tables/columns/functions/grants/RLS and run security/performance advisors;
5. integrate trusted payment/refund state into Phase 8 reporting and Dashboard/BFF, then customer presentation where useful;
6. exact-head customer/Dashboard/backend validation and synchronized closeout docs.

## External activation boundary

Provider choice, merchant onboarding, production API credentials/webhook secrets and any cost-bearing service remain explicit owner-approval boundaries. Provider-specific success, settlement or refund outcomes must never be fabricated.
