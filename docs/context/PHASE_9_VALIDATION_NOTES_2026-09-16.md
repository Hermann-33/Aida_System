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

Static inspection isolated a test-harness defect: the regression denied authenticated direct-table access and then contradicted that contract by selecting refund IDs directly from `payment_refunds`. Commit `8ca2209b4f1d2af28af4dd05f1cf826588b42b33` repairs the test without weakening production authority: refund IDs are now extracted from the protected `refunds` array returned by the payment RPC snapshot.

Backend database audit #264 then exposed the next real boundary at `payment_refund_authority_integration.sql:134`: `public.apply_payment_provider_event(...)` is a SECURITY INVOKER wrapper whose explicitly granted private implementation could not be resolved because `service_role` lacked `USAGE` on schema `private`. The same schema-resolution requirement applies to authenticated Phase 9 invoker wrappers. Canonical corrective migration `20260916111000_grant_phase9_private_rpc_schema_usage.sql` grants only schema `USAGE` to `authenticated` and `service_role`; it does not grant table access or any additional function execution. Exact-head clean CI remains required.

## Live Supabase inspection boundary

The Supabase connection available in the prior inspection exposed only project `Stone Set` (`pjltldrernuvrjsnmcqg`), not the documented AIDA project `eswovqxqzfevcdwwcmuh`. No Phase 9 migration was applied and no AIDA live state/advisor claim was made from the wrong project.

## Current validation boundary

The Phase 9 migration/test batch remains `PARTIAL` until the clean database audit reruns successfully through the historical contention gates. After that, true simultaneous refund contention and cash-refund end-to-end coverage remain required before Dashboard/customer wiring and live deployment.

## External activation boundary

Provider choice, merchant onboarding, production API credentials/webhook secrets and any cost-bearing service remain explicit owner-approval boundaries. Provider-specific success/settlement must never be fabricated.
