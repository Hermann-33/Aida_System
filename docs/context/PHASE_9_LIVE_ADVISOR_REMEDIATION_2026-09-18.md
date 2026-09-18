# Phase 9 Live Advisor Remediation — 2026-09-18

Status: `PARTIAL`

Live AIDA `eswovqxqzfevcdwwcmuh` now contains the reconciled Phase 9 payment/refund authority and the Phase 9 reporting upgrade. Verified live objects include `payment_intents`, `payment_refunds`, `payment_events`, `payment_refund_events`, `payment_webhook_receipts`, `payment_provider_configs`, and `orders.refunded_sen`; all six Phase 9 public tables have RLS enabled.

Live migration history currently includes `reconcile_phase9_payment_refund_live_schema`, `grant_phase9_private_rpc_schema_usage`, and `upgrade_phase9_reporting_payment_facts` after the earlier erroneous comments-only `create_payment_refund_authority` ledger entry. The bad historical ledger row is retained; it is not rewritten.

Post-deployment Security Advisor reports no Phase 9 WARN/ERROR. The Phase 9 tables appear only under the intentional `RLS Enabled No Policy` INFO pattern because access is RPC-mediated and direct table grants are denied. The pre-existing Auth leaked-password-protection WARN remains outside the Phase 9 schema batch.

Post-deployment Performance Advisor identified two Phase 9-created actionable INFO findings: `payment_webhook_receipts.payment_intent_id` and `payment_webhook_receipts.refund_id` lacked covering indexes. Canonical migration `20260918130500_index_phase9_webhook_foreign_keys.sql` adds partial covering indexes for both nullable foreign keys. It must pass exact-head clean replay, be deployed to live AIDA, and be followed by security/performance advisor reruns before Phase 9 can close.

No external processor is activated. Provider choice, merchant onboarding, production credentials/webhook secrets and cost-bearing services remain owner-approval boundaries.
