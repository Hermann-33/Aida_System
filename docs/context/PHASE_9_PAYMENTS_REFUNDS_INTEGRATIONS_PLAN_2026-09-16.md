# Phase 9 Plan — Payments, Refunds and External Integrations

Date: 2026-09-16  
Verdict at start: `PARTIAL`

## Goal

Add provider-neutral, server-authoritative payment/refund lifecycle authority without fabricating external processor outcomes and without weakening the Phase 1–8 trust boundaries.

Phase 9 engineering completion does **not** require pretending that a processor merchant account, production webhook secret or settlement feed exists. Provider-specific activation remains a separately documented external activation step requiring explicit owner approval when it has cost, credentials or merchant onboarding.

## Baseline being extended

At Phase 8 closeout:

- `orders.tender_type` is limited to `unpaid|cash`;
- `orders.payment_state` is limited to `unpaid|paid`;
- customer orders are forced to unpaid/no-shift shape;
- POS cash is finalized as paid inside the open-shift authority;
- paid cash orders cannot be cancelled without a refund workflow;
- Phase 8 reporting intentionally has no processor/refund truth.

Phase 9 must extend this model rather than creating a competing payment truth.

## Provider-neutral data authority

Canonical backend work will introduce durable payment/refund resources equivalent to:

- payment intents/attempts bound to an order, amount, currency, channel and idempotency key;
- append-only payment events with provider-event idempotency/digest metadata;
- refund records with bounded amount and explicit lifecycle state;
- append-only refund events;
- webhook receipt/idempotency records suitable for a later server-side provider adapter;
- order-level derived payment summary fields that remain protected from direct client mutation.

No provider secret belongs in browser/Flutter data, public tables or client-authored payloads.

## State model

Payment lifecycle must distinguish at least:

```text
created
requires_action / authorized
captured
failed / cancelled
```

Order payment summary must distinguish at least:

```text
unpaid
pending
paid
partially_refunded
refunded
```

Refund lifecycle must distinguish at least:

```text
requested
processing
succeeded
failed / cancelled
```

Captured/refunded truth may only advance from trusted server/provider evidence or the explicit trusted cash-refund workflow. Customer/POS clients cannot self-declare paid, captured, settled or refunded state.

## Cash refund authority

Cash is already a trusted internal tender and must become fully operable in Phase 9. A cash refund workflow will:

- require authorized staff/manager context and an appropriate open shift/terminal context;
- lock the order/refund state before calculating refundable balance;
- reject refund overrun and duplicate idempotency keys;
- record the refund and append-only event;
- record the corresponding trusted cash-out movement;
- update only the protected derived order payment summary through an internal guard;
- permit cancellation only when the order/payment/refund state allows it.

Simultaneous refund attempts must not exceed the captured/paid amount.

## External provider boundary

Provider-specific network calls are intentionally adapter-bound. Until a provider is approved/configured:

- no external payment option is shown as available to customers;
- no fake capture/settlement/refund result is persisted;
- provider webhook application helpers are not callable by normal anon/authenticated clients;
- provider secrets remain outside browser/Flutter code and outside non-secret configuration tables.

A later adapter may use server-side credentials/secret storage and an authenticated webhook boundary to translate provider events into the canonical payment state machine.

## RPC / authorization boundary

Expected public caller surfaces include read-only payment state for the order owner and Admin/Owner operational payment/refund state. Any refund-request/cash-refund mutation is caller-bound and role-checked.

Provider-event application remains internal/server-only. Public wrappers remain `SECURITY INVOKER` where caller identity is the authority; guarded private implementations use empty `search_path` and explicit actor checks.

## Order integration

Phase 9 may extend `orders.tender_type` with an external/provider-neutral value and `orders.payment_state` with pending/refund summaries. Existing cash/unpaid behavior must remain backward compatible.

The order commercial total remains immutable. Payment/refund events compensate against the accepted order; they do not rewrite historical item prices, voucher/promotion application snapshots or `total_sen`.

## Reporting integration

Phase 8 report RPCs will be upgraded to project trusted Phase 9 payment/refund facts, including captured amount, refundable/refunded amount and payment method/state where source-backed.

Reporting must continue to separate:

- accepted order value;
- captured/paid value;
- refunded value;
- settlement/reconciliation status.

It must never equate authorization/capture with provider settlement unless a trusted settlement fact actually exists.

## Dashboard scope

Production Admin/POS work will include:

- strict payment/refund client/BFF contracts;
- transaction payment/refund detail;
- operational refund workflow for supported trusted tender paths;
- payment/refund reporting based on source-backed facts;
- integrations/provider-status UI that truthfully shows an external provider as unconfigured until activation.

Preview mode remains isolated and must not call privileged payment/refund routes.

## Customer scope

Flutter order models/history will parse trusted payment/refund summary fields fail-closed. No external-pay call-to-action is enabled until a real provider adapter is configured. Existing order placement remains usable with supported unpaid/pay-at-pickup behavior.

## Tests / closure gates

Phase 9 engineering cannot be `COMPLETE` without:

1. clean canonical migration replay;
2. SQL authorization/state-machine/idempotency/refund-bound regressions;
3. true contention proof that simultaneous refunds cannot exceed refundable value;
4. existing Phase 1–8 regressions remaining green;
5. customer model/static/test/release gates where affected;
6. Dashboard lint/typecheck/unit/E2E/build plus preview isolation;
7. live AIDA migration deployment and function/grant verification;
8. fresh Supabase security/performance advisors with no Phase 9-created actionable WARN/ERROR;
9. Phase 8 reporting upgraded to trusted Phase 9 facts;
10. synchronized architecture/contracts/status/closeout docs in both repos.

External processor activation is documented separately and is not to be fabricated as a completed engineering gate.

## App Store impact

AIDA sells physical café goods. Current Apple App Review Guideline 3.1.3(e) requires physical goods/services consumed outside the app to use non-IAP payment methods such as Apple Pay or traditional card entry. Phase 9 must therefore keep café payment outside StoreKit/IAP.

Official reference: https://developer.apple.com/app-store/review/guidelines/

Phase 10 will re-check the then-current official rules and reconcile the final provider/SDK/privacy behavior before submission.

## Audit governance

The owner explicitly deferred the independent/Astra/Codex audit until Phase 10 implementation is complete. Normal Phase 9 engineering validation remains mandatory. After Phase 9 engineering closeout, proceed directly to Phase 10.
