-- Phase 9 live advisor remediation: cover webhook receipt foreign keys.
-- Canonical executable migration; no provider activation or secret material.

create index if not exists payment_webhook_receipts_payment_intent_idx
  on public.payment_webhook_receipts (payment_intent_id)
  where payment_intent_id is not null;

create index if not exists payment_webhook_receipts_refund_idx
  on public.payment_webhook_receipts (refund_id)
  where refund_id is not null;
