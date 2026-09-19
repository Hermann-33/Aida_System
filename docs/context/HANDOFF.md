# Current Handoff

Updated: 2026-09-16

## Current boundary

Phases 1–8 engineering are `COMPLETE`. Phase 9 is `PARTIAL` at planning/start. The cumulative independent/Astra/Codex audit is intentionally deferred until Phase 10 implementation is complete.

## Exact Phase 8 closure heads

```text
Aida_System             78e6682d2faab83b56e4e8af9beba95a3aa7097b
Backend database audit #254   COMPLETE
Aida_System-Dashboard   9fdc4edad87debcbbdd3ff5b9ad894e66dd8f148
Dashboard CI #177              COMPLETE
```

## Phase 9 baseline

Current orders only support `unpaid|cash` tenders and `unpaid|paid` payment summary. Customer orders are forced unpaid; POS cash becomes paid in the open-shift finalization path. Paid cash cancellation is already blocked pending a refund workflow.

Phase 9 extends that authority with provider-neutral payment/refund records and events, protected derived order payment summary, cash refund handling, webhook/provider-event idempotency scaffolding, reporting integration and strict client/UI contracts.

No normal client may mark an order paid/refunded/settled. External provider activation remains disabled until a real provider/merchant configuration exists.

## External activation boundary

Provider choice, merchant onboarding, production API/webhook credentials and paid-service approval are external activation steps. They must not be guessed or simulated. The provider-neutral backend, cash refund path, reporting and UI can be completed independently.

## App Store boundary

Physical café goods remain non-IAP. Phase 9 must not introduce StoreKit digital purchase semantics. Phase 10 will re-check current Apple rules before submission work.

## Immediate next action

Implement and test the provider-neutral Phase 9 schema/RPC state machine on the Phase 9 branches, document every coherent implementation batch in both repos, then deploy/advisor-verify only after clean local regression closure.
