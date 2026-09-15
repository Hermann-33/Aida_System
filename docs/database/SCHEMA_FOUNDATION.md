# Database Schema Foundation

Updated: 2026-09-15

Canonical executable migrations are owned only by `Hermann-33/Aida_System/supabase/migrations/`; the Dashboard mirrors schema documentation but does not own a second migration ledger.

## Trusted schema through Phase 6

Identity/member: `user_profiles`, `members`, `student_verifications`, `customer_privacy_preferences`.

Catalogue/orders: shared catalogue tables; `orders`, line/add-on/option snapshots and `order_events`.

Operational topology/shift: `branches`, `employee_branch_assignments`, `sales_points`, `terminals`, private terminal credentials/codes, `shifts`, `cash_movements`.

Scheduling: branch ordering policies, service windows/exceptions and accepted scheduling/capacity facts.

Inventory: `inventory_items`, `branch_inventory`, `inventory_movements`, `recipes`, `recipe_components`.

Phase 6 loyalty:

```text
loyalty_program_config
member_loyalty_accounts
loyalty_order_awards
loyalty_point_ledger
loyalty_stamp_ledger
reward_catalogue
member_vouchers
voucher_order_applications
orders.discount_sen
```

## Phase 6 invariants

- loyalty current balances are server-maintained and non-negative;
- order awards provide exactly-once completed-order earning;
- point/stamp history is application append-only; account deletion may remove customer-owned rows;
- vouchers have server-owned source/status/expiry and immutable reward eligibility snapshots;
- voucher order applications preserve accepted non-identifying commercial facts;
- order discount is server-derived and constrained to `0 <= discount <= subtotal`, with `total = subtotal - discount`;
- Phase 6 tables use RLS + FORCE RLS and deny direct authenticated mutation;
- required foreign keys have covering indexes after `20260915002800_index_loyalty_foreign_keys.sql`.

## Phase 1–3 remediation invariants

`private.create_order_impl_v2(...)` is not executable by ordinary authenticated callers. The guarded POS authority wrapper owns retry/new-order decisions. Whole-account deletion can perform only the expected customer identity + digest anonymization transition and deletes customer-owned loyalty state before Auth/member teardown.

## Canonical Phase 6 tail

```text
20260914183500_create_loyalty_rewards_voucher_authority.sql
20260914183600_harden_loyalty_authority_foundation.sql
20260914183800_integrate_vouchers_with_order_authority.sql
20260914183900_make_voucher_consumption_trigger_internal.sql
20260914184000_preserve_loyalty_privacy_deletion.sql
20260914184100_expose_voucher_commercial_snapshot.sql
20260914184200_separate_voucher_quote_from_consumption_lock.sql
20260914184300_add_loyalty_admin_authority.sql
20260914184400_add_loyalty_program_configuration_authority.sql
20260914184500_add_pos_loyalty_lookup_authority.sql
20260914235500_restore_privacy_anonymization_boundary.sql
20260914235600_harden_pos_order_authority_boundary.sql
20260915000500_reconcile_loyalty_account_deletion.sql
20260915002000_reconcile_partial_phase6_live_schema.sql
20260915002800_index_loyalty_foreign_keys.sql
```

## Validation

Backend database audit #190 reconstructed the cumulative schema from canonical migrations and passed all regressions through Phase 6. Live AIDA Supabase is deployed and advisor-checked. Phase 7 generalized promotion/discount schema is not started.