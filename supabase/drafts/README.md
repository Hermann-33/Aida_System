# Supabase draft work

Files in this directory are preserved future work only.

They are intentionally **outside** `supabase/migrations/` so normal migration replay/push tooling does not apply them automatically.

Current preserved drafts:

- `20260826120000_add_customer_account_deletion.sql` — prototype for customer self-service account deletion / retained-order anonymisation.
- `20260828120000_add_referral_program.sql` — prototype for referrals and initial loyalty-credit behavior.
- `tests/account_deletion_integration.sql` — prototype regression for the deletion draft.

Before promotion into canonical migrations, each draft must receive its own bounded task, security/RLS review, fresh migration timestamp, executable SQL regression, advisor review, client contract validation, and documentation closeout.

Do not treat these files as deployed/live Supabase state.
