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

That workflow still does not include the dedicated simultaneous-refund contention regression or a complete cash-refund E2E/contention gate. Those remain mandatory before Phase 9 closeout.

## Live AIDA reconciliation boundary — 2026-09-17

AIDA project `eswovqxqzfevcdwwcmuh` is visible and `ACTIVE_HEALTHY`.

Migration history contains:

```text
20260917055816_create_payment_refund_authority
```

Inspection of `supabase_migrations.schema_migrations.statements` proved that this live entry contains only comments saying the canonical repository body should be applied; it did not execute the Phase 9 DDL. Correspondingly, live inspection showed the expected Phase 9 payment/refund tables and `orders.refunded_sen` were absent. The later private-schema grant migration was also absent from live history and `service_role` did not have the required `private` schema usage.

No migration-history row will be rewritten or deleted. The corrective path is the new canonical reconciliation migration `20260917154500_reconcile_phase9_payment_refund_live_schema.sql`, followed by the normal migration/advisor/live verification gates.

## Current validation boundary

Current backend branch head after adding the reconciliation migration is `7896246b6e779359e15e20baba235ab928866462`.

Next mandatory gates:

1. clean database audit on the reconciliation head;
2. apply the reconciliation body and private-schema usage repair to live AIDA through migration tooling;
3. verify live Phase 9 tables/columns/functions/grants/RLS and run security/performance advisors;
4. add true simultaneous-refund contention and cash-refund E2E/contention coverage;
5. integrate trusted payment/refund state into Phase 8 reporting, Flutter and Dashboard/BFF;
6. exact-head customer/Dashboard/backend validation and synchronized closeout docs.

## External activation boundary

Provider choice, merchant onboarding, production API credentials/webhook secrets and any cost-bearing service remain explicit owner-approval boundaries. Provider-specific success, settlement or refund outcomes must never be fabricated.
