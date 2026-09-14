# Supabase Status

**Status date:** 2026-09-12  
**Project:** Aida System  
**Ref:** `eswovqxqzfevcdwwcmuh`  
**Region:** `ap-southeast-1`  
**Implementation verdict:** Phases 1–3 `COMPLETE`; combined Astra audit `PARTIAL`.

## Current role

Supabase is the shared trusted backend for the Flutter customer app and React Dashboard/Admin/POS. Canonical executable migration files live only in `Hermann-33/Aida_System/supabase/migrations/`.

Trusted authority now covers:

- Supabase Auth identity;
- `user_profiles` trusted role/disabled state;
- `members` customer membership identity;
- catalogue/options/add-ons/prices;
- authoritative quote/order commercial snapshots and scheduling;
- branch identity and employee branch assignments;
- sales points, terminals, enrolment/revocation and terminal credentials;
- terminal-bound POS attribution;
- shift lifecycle and append-only cash movements;
- server-derived expected cash and closing variance;
- POS shift/tender/payment classification;
- customer privacy preferences;
- caller-bound whole-account deletion/anonymization;
- anonymized retained customer transaction history with customer-authored retained line/event free text scrubbed.

## Phase 1 topology resources

```text
public.branches
public.employee_branch_assignments
public.sales_points
public.terminals
private.terminal_enrolment_codes
private.terminal_credentials
public.orders.branch_id
public.orders.sales_point_id
public.orders.terminal_id
```

Operational topology remains server-owned. Browser/client payloads cannot substitute trusted branch/sales-point/terminal authority. Employee scope, terminal status and revocation are enforced server-side.

## Phase 2 shift/cash resources

```text
public.shifts
public.cash_movements
public.orders.shift_id
public.orders.tender_type
public.orders.payment_state
public.orders.paid_at
```

New POS placement requires a matching open shift. Cash movements are append-only. Opening float/movements use integer sen. Expected cash and variance are server-derived. Non-zero variance close requires Admin/Owner authority. Cash/unpaid is internal settlement classification; external processor settlement/refunds remain deferred.

## Phase 3 privacy/account resources

```text
public.customer_privacy_preferences
public.orders.customer_deleted_at
public.get_my_privacy_preferences()
public.save_my_privacy_preferences(boolean, boolean)
public.delete_own_account()
```

Whole-account deletion is caller-bound to `auth.uid()` and accepts no target user ID. Public wrappers are `SECURITY INVOKER`; private privileged helpers bind the actor to the authenticated caller and trusted customer profile. Staff/Admin cannot use customer self-deletion.

Retained customer transaction history loses `customer_user_id`, `member_id` and `created_by_user_id`, gains `customer_deleted_at`, and has retained `order_lines.note` / `order_events.reason` cleared. Commercial/operational facts remain retained. POS/staff actor identity is not weakened.

`customer_privacy_preferences` has FORCE RLS with no direct authenticated table grants. Marketing defaults off; transactional notifications default on.

## Relevant migration tail

Phase 1:

```text
20260910014434 create_branch_location_authority
20260910014457 index_employee_branch_assignment_actor
20260910023510 create_operational_sales_points_and_terminals
20260910023552 harden_operational_topology_rls_and_indexes
20260910040814 revoke_direct_branch_mutation_grants
20260910041057 enforce_terminal_branch_scope_on_resolution
20260910042619 differentiate_terminal_resolution_failures
20260910044613 grant_branch_rpc_private_impl_execution
20260910050152 grant_admin_operational_topology_reads
```

Phase 2:

```text
20260911235419 create_shift_cash_authority_schema
20260911235626 implement_shift_cash_authority_functions
20260911235651 harden_shift_cash_authority_permissions
20260912000002 index_shift_cash_foreign_keys
```

Phase 3:

```text
20260912014924 customer_privacy_account_requirements
20260912015010 harden_customer_privacy_rpc_boundary
20260912020434 allow_customer_deletion_without_member_dependency
20260912020652 allow_disabled_customer_account_deletion
20260912021143 scrub_customer_free_text_on_account_deletion
```

Live migration inspection confirmed all Phase 1–3 migrations above are applied to project `eswovqxqzfevcdwwcmuh`.

## Data/API permission observations

Fresh live verification on 2026-09-12 confirmed:

```text
authenticated delete_own_account execute                  true
anon delete_own_account execute                           false
authenticated save_my_privacy_preferences execute         true
anon save_my_privacy_preferences execute                  false
authenticated direct privacy-preference SELECT grant      false
authenticated direct privacy-preference UPDATE grant      false
```

The live deletion helper also includes the retained line-note/event-reason scrub before order anonymization.

Dashboard employee access continues through same-origin HttpOnly BFF cookies with caller-JWT forwarding. Terminal credential remains HttpOnly/server-readable. No service-role secret or browser-readable reusable employee bearer token is introduced.

## Executable database evidence

Phase 3 implementation head `10ca26a776994e59b76f8afbd7227e296270cd68` passed Backend database audit #90 with:

```text
branch_authority_integration.sql                         COMPLETE
operational_topology_integration.sql                    COMPLETE
order_integration.sql                                   COMPLETE
scheduled_order_operations_integration.sql              COMPLETE
shift_cash_authority_integration.sql                    COMPLETE
customer_privacy_account_integration.sql                COMPLETE
customer_privacy_free_text_integration.sql              COMPLETE
customer_privacy_student_cascade_integration.sql        COMPLETE
```

Customer release audit #182 is also `COMPLETE` at that implementation head.

## Advisor state

Fresh security advisor review reports one pre-existing warning only:

```text
auth_leaked_password_protection — Leaked Password Protection Disabled
```

No Phase 1–3-created security blocker remains.

Performance advisor findings are INFO-level unused-index observations only. Required Phase 2 foreign-key support indexes were added; no current missing-FK/index blocker was reported.

## Deferred backend authority

- branch hours/closures/capacity and explicit customer pickup branch;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- reporting/tax/accounting export;
- external payment capture/refunds/processor settlement;
- employee Auth-user/credential lifecycle;
- printer/KDS/payment-device integration;
- notification/marketing delivery provider;
- delivery and deployment-heavy production infrastructure.

## Governance

Phases 1–3 remain draft/unmerged. Implementation is stopped. The next boundary is `docs/context/PHASE_1_3_ASTRA_AUDIT_BOUNDARY_2026-09-12.md`, currently `PARTIAL` until Astra review is executed/accepted. Phase 4 is blocked.