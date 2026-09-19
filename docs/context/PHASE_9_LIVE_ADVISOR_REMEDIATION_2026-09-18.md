# Phase 9 Live Advisor Remediation — 2026-09-18

Status: `PARTIAL`

Live AIDA `eswovqxqzfevcdwwcmuh` contains the reconciled Phase 9 payment/refund authority and Phase 9 reporting upgrade. Verified live objects include `payment_intents`, `payment_refunds`, `payment_events`, `payment_refund_events`, `payment_webhook_receipts`, `payment_provider_configs`, and `orders.refunded_sen`; all six Phase 9 public tables have RLS enabled.

Live migration history retains the earlier erroneous comments-only `create_payment_refund_authority` ledger entry and separately records the real reconciliation, private-schema usage repair, reporting upgrade and webhook-FK index remediation. The bad historical ledger row is not rewritten.

Security Advisor rerun after the index deployment reports no Phase 9 WARN/ERROR. Phase 9 tables remain under the intentional `RLS Enabled No Policy` INFO pattern because direct table access is denied and authority is RPC-mediated. The pre-existing Auth leaked-password-protection WARN remains outside Phase 9.

Performance Advisor initially identified two Phase 9-created unindexed foreign keys on `payment_webhook_receipts.payment_intent_id` and `payment_webhook_receipts.refund_id`. Canonical migration `20260918130500_index_phase9_webhook_foreign_keys.sql` was committed and deployed. The advisor rerun no longer reports `unindexed_foreign_keys`; the two new indexes appear only as expected `unused_index` INFO immediately after creation. Exact-head clean replay/CI remains mandatory before Phase 9 closeout.

No external processor is activated. Provider choice, merchant onboarding, production credentials/webhook secrets and cost-bearing services remain owner-approval boundaries.
