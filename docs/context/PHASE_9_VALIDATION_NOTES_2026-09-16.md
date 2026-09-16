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

`supabase/tests/payment_refund_authority_integration.sql` covers grants/direct-table denial, intent idempotency, authorization/capture/settlement separation, provider-event replay conflicts, refund reservation, partial/full refund projection, cancellation protection, provider-unavailable failure and append-only history.

Backend database audit #261 at exact head `06479ccba677c6915aefd54d1a910b5581f9eb81` passed every Phase 1–8 regression and failed only at `Payment and refund authority regression`; downstream contention gates were correctly skipped.

Static inspection isolated a test-harness defect that violates the boundary the same test asserts: after proving `authenticated` has no direct privileges on `public.payment_refunds`, the regression later executes direct `select` queries against that table while still under `set local role authenticated` to discover refund IDs. The public payment snapshot already exposes refund IDs through its protected `refunds` array, so the regression must obtain IDs from the RPC response rather than weakening table grants. Production grants must not be relaxed to make the test green.

## Live Supabase inspection boundary

The Supabase connection available in this run exposes only project `Stone Set` (`pjltldrernuvrjsnmcqg`), not the documented AIDA project `eswovqxqzfevcdwwcmuh`. No Phase 9 migration was applied and no AIDA live state/advisor claim was made from the wrong project.

## Current validation boundary

The Phase 9 migration/test batch is not accepted. Repair the regression to consume refund IDs from the protected RPC snapshot, rerun the clean database audit through the historical contention gates, then add the required true simultaneous refund contention and cash-refund end-to-end coverage before Dashboard/customer wiring and live deployment.

## External activation boundary

Provider choice, merchant onboarding, production API credentials/webhook secrets and any cost-bearing service remain explicit owner-approval boundaries. Provider-specific success/settlement must never be fabricated.
