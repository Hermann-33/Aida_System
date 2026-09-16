# Phase 9 Validation Notes — 2026-09-16

Status: `PARTIAL`

## Governance

Phases 1–8 engineering are `COMPLETE`. Independent/Astra/Codex audit is deferred by owner instruction to one cumulative Phase 1–10 audit after Phase 10. Normal Phase 9 engineering validation remains mandatory.

## First backend authority batch

Canonical migration added:

```text
supabase/migrations/20260916110000_create_payment_refund_authority.sql
```

The migration extends, rather than replaces, the existing order payment model. It adds:

- `orders.refunded_sen` and protected payment-summary states `unpaid|pending|paid|partially_refunded|refunded`;
- tender support for `external` while retaining `unpaid|cash` behavior;
- non-secret `payment_provider_configs` activation metadata;
- provider-neutral `payment_intents` and append-only `payment_events`;
- `payment_refunds` and append-only `payment_refund_events`;
- webhook idempotency/digest receipts without raw provider payloads or secrets;
- authenticated read/request RPCs for order payment state and external intent/refund requests;
- service-role-only provider-event application RPCs;
- Admin/Owner cash refund authority tied to an open terminal/shift and a trusted cash-out ledger movement;
- protected order payment projection so clients cannot directly mark orders paid/refunded;
- cancellation protection until pending/paid/partially-refunded payment is resolved.

No processor is activated and no provider credentials/secrets are committed. With no active provider configuration, external payment creation fails closed.

## Blocking regression

`supabase/tests/payment_refund_authority_integration.sql` covers:

- grants and direct-table denial;
- external intent idempotency;
- authorization vs capture vs settlement separation;
- provider-event replay/digest conflict handling;
- refund reservation and overrun denial;
- partial/full refund projection;
- cancellation blocked until full refund;
- fail-closed provider-unavailable behavior;
- append-only payment event history.

The backend database audit workflow now runs this regression after the Phase 8 report regression and before historical contention gates.

## Current validation boundary

The first Phase 9 migration/test batch is **not yet accepted**. The exact-head database audit must complete cleanly; any migration/replay or test defect is repaired before Dashboard/customer Phase 9 wiring proceeds.

True simultaneous refund contention and cash-refund end-to-end coverage remain required before Phase 9 engineering closure.

## External activation boundary

Provider choice, merchant onboarding, production API credentials/webhook secrets and any cost-bearing service remain explicit owner-approval boundaries. Provider-specific success/settlement must never be fabricated.
