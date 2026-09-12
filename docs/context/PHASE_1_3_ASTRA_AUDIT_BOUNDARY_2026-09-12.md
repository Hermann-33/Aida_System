# Combined Phase 1–3 Astra Audit Boundary

**Prepared:** 2026-09-12  
**Boundary verdict:** `PARTIAL` — implementation phases are `COMPLETE`; Astra audit has not yet been executed/accepted.  
**Rule:** stop implementation here. Do not begin Phase 4 and do not merge Phase 1, 2 or 3 merely because implementation is complete.

## Cumulative scope

The Phase 3 branches are cumulative descendants of the frozen Phase 1 and Phase 2 work, so they represent the implementation surface for the combined audit while the individual phase PRs remain draft/unmerged.

Audit scope:

```text
Phase 1 — operational topology                  COMPLETE
Phase 2 — shift and cash authority              COMPLETE
Phase 3 — customer privacy/account requirements COMPLETE
Combined Astra audit                            PARTIAL
```

## Phase boundaries and evidence

### Phase 1

Task: `TASK-OPS-002`

```text
Aida_System PR #20 — draft/unmerged
head b3593f1fad60c0edd19b1dabe83851bec143a25c
Backend database audit #41   COMPLETE
Customer release audit #133 COMPLETE

Aida_System-Dashboard PR #17 — draft/unmerged
head e22e55dbe41b34e0f13e3205c5a3031c6363268c
Dashboard validation recorded in Phase 1 closeout COMPLETE
```

Evidence: `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.

### Phase 2

Task: `TASK-OPS-003`

```text
Aida_System PR #21 — draft/unmerged
head 23ecb5d491cd8c15b8def9cf522438c1fb86340b
Backend database audit #52   COMPLETE
Customer release audit #144 COMPLETE

Aida_System-Dashboard PR #18 — draft/unmerged
head f4b1ba94bcea56f52e23c6da2b2eff922edff3a8
Dashboard CI #65             COMPLETE
```

Evidence: `docs/context/PHASE_2_SHIFT_CASH_CLOSEOUT_2026-09-12.md`.

### Phase 3

Task: `TASK-PRIVACY-001`

Implementation validation head:

```text
Aida_System
10ca26a776994e59b76f8afbd7227e296270cd68
Backend database audit #90   COMPLETE
Customer release audit #182 COMPLETE
```

Dashboard runtime did not change for Phase 3; pre-closeout Phase 3 Dashboard head `411056a40edfb1c23fa999504b904d822e151f5d` passed Dashboard CI #66. Final synchronized documentation heads are revalidated separately.

Evidence: `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_CLOSEOUT_2026-09-12.md`.

## Authority chain to audit

```text
Supabase Auth / trusted user_profiles role
 -> employee branch scope
 -> branch
 -> sales point
 -> terminal + server-held terminal credential
 -> shift
 -> POS order / cash ledger

customer Auth + trusted member state
 -> customer order
 -> privacy preferences
 -> whole-account deletion
 -> anonymized retained transaction history
```

## Mandatory Astra checks

### Identity and authorization

- authorization never trusts customer-editable Auth metadata;
- staff/Admin/customer roles come from trusted server state;
- employee branch scope is fail-closed;
- customer self-deletion accepts no target user ID;
- staff/Admin cannot use customer self-deletion;
- stale deleted-customer JWTs cannot regain personalized authority.

### Dashboard/BFF

- employee access/refresh remains HttpOnly;
- terminal credential remains HttpOnly/server-readable only;
- caller JWT is forwarded upstream;
- no service-role secret in normal browser/BFF operational paths;
- no browser-readable reusable employee bearer token;
- state-changing privileged routes remain same-origin protected.

### Operational topology and shifts

- browser/preview identifiers cannot become trusted branch/sales-point/terminal/shift authority;
- terminal enrolment/revocation and employee scope are enforced server-side;
- POS placement requires matching active terminal and open shift;
- topology/shift/tender/payment attribution remains immutable after acceptance;
- cash ledger is append-only and expected cash/variance is server-derived.

### Customer privacy

- deletion is atomic from the database boundary;
- customer profile/member/student/preference identity is removed;
- retained customer orders lose customer/member/Auth identifiers;
- retained customer-authored line/event free text is scrubbed;
- retained commercial/operational facts remain intact;
- no synthetic permanent deleted-customer Auth row exists;
- POS/staff audit identity is not weakened;
- privacy preferences are owner-bound, FORCE-RLS protected and marketing defaults off.

### Commercial authority

- catalogue prices/options/availability and order totals remain server-owned;
- customer/POS clients submit intent, not trusted totals/status/location/payment facts;
- idempotency and optimistic status-version rules remain intact;
- no external payment processor/refund authority is implied by Phase 2 cash/unpaid state.

### App Store/privacy

- in-app whole-account deletion is easy to find and production-enabled;
- retention disclosure matches backend behavior;
- legal/support/privacy surfaces are accessible without unnecessary authentication;
- no unnecessary iOS protected-data or tracking permission/SDK was added;
- physical café goods remain outside StoreKit/IAP.

## Canonical migrations added by Phases 1–3

Canonical executable files exist only in `Hermann-33/Aida_System/supabase/migrations/`.

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

## Known advisor state

The current Supabase security advisor has one pre-existing warning: leaked-password protection is disabled. No Phase 1–3 schema-created security blocker remains. Performance output contains INFO-level unused-index observations only after required FK coverage fixes.

This warning must remain visible to the audit; it must not be falsely represented as a Phase 1–3 regression or silently omitted.

## Deferred / explicitly outside this audit

- external payment capture/refunds/processor settlement;
- branch hours/closures/capacity and explicit customer pickup branch;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- reporting/tax/accounting export;
- employee Auth-user/credential lifecycle;
- printer/KDS/payment-device hardware integration;
- marketing delivery provider;
- delivery/deployment-heavy production infrastructure.

## Exit rule

Astra must return an accepted boundary using project verdict vocabulary (`COMPLETE`, `PARTIAL`, or `FAIL`) and any findings must be resolved or explicitly accepted before Phase 4 begins. Until then this combined audit boundary remains `PARTIAL` and all three phase PRs remain unmerged.