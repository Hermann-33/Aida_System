# AIDA Café Security Review

Updated: 2026-09-11

**Current verdict:** Phase 1 operational topology is `COMPLETE`. Identity, employee branch scope, catalogue/pricing, ordering/scheduling, fulfilment, branch/sales-point/terminal identity and POS operational attribution are server-controlled. No Phase 1-created security blocker remains.

## Core trust controls

- Supabase Auth is trusted user identity.
- `user_profiles.app_role` plus `disabled_at` are trusted employee authorization state.
- `members` is trusted customer membership state.
- Public signup cannot self-promote role, member code, verification outcome or operational branch scope.
- Dashboard privileged traffic uses same-origin HttpOnly employee sessions and caller-JWT Supabase access.
- No service-role key or browser-readable employee bearer token is part of normal runtime architecture.
- Customer Flutter uses public/publishable configuration with customer-scoped RLS/RPC authority.

## Employee branch-scope controls

`employee_branch_assignments` is authoritative operational scope.

- ordinary staff can operate only assigned branches;
- staff with no assignment fail closed;
- order reads/transitions re-check trusted branch scope;
- terminal resolution re-checks trusted branch scope;
- removing a branch assignment immediately prevents that staff member from resolving a terminal in the removed branch;
- Admin/Owner remain global operational roles for the current tranche.

Preview/browser state cannot manufacture branch authority.

## Operational topology controls

Trusted topology:

```text
branches
 -> sales_points
 -> terminals
```

Backend invariants:

- IDs are server-owned;
- topology relationships are foreign-keyed and server-validated;
- branch identity on all orders is immutable;
- POS sales-point/terminal attribution is immutable;
- customer orders remain terminal-free;
- direct branch/sales-point/terminal DML is denied to browser roles.

`branches`, `sales_points` and `terminals` use RLS + FORCE RLS. Authenticated SELECT on `sales_points`/`terminals` exists only to support SECURITY INVOKER Admin topology reads; RLS limits rows to Admin/Owner. Anonymous SELECT remains denied.

## Terminal enrolment and credential controls

Terminal activation requires a one-time manager-issued enrolment code.

Possessing the code alone is insufficient. `enrol_terminal` validates authenticated employee state and branch authorization before issuing a terminal credential.

Security properties proven by regression:

- failed authorization does not consume the one-time code;
- a used code cannot be replayed;
- codes expire;
- the terminal credential is stored by the Dashboard BFF in an HttpOnly cookie, not normal React state;
- private credential storage contains hashed authority state rather than a browser-readable credential catalogue;
- terminal resolution revalidates active terminal, sales point, branch and employee branch scope;
- revocation invalidates terminal resolution and POS placement immediately.

## POS placement controls

The credentialless POS signature is not executable by `authenticated`:

```text
place_pos_order(jsonb)        denied
place_pos_order(jsonb,text)   allowed for authenticated caller subject to server validation
```

The terminal-bound placement function derives `branch_id`, `sales_point_id` and `terminal_id` from the validated terminal credential. Browser-supplied topology IDs are not trusted placement authority.

Order pricing remains server-owned through `quote_order`. `clientRequestId` preserves idempotency, and immutable operational attribution prevents later workstation/browser rewriting.

## Catalogue/pricing controls

Catalogue IDs, availability, variants, required options, compatible add-ons and integer-sen pricing are server data.

Clients send only selection intent. `quote_order(jsonb)` revalidates all selections and computes `pricingVersion=2` authoritative prices.

Historical option/add-on/commercial snapshots remain immutable after catalogue changes.

## Scheduling/fulfilment controls

- scheduling is validated against server policy/time;
- scheduled orders persist immutable `prepareAt`;
- `scheduleState` is server-derived;
- time never auto-mutates fulfilment status;
- status changes require legal transition, authorized staff branch scope and expected `statusVersion`;
- stale transitions fail.

Branch-specific hours/closures/capacity are not yet implemented and must not be invented by clients.

## Dashboard/BFF controls

The Dashboard same-origin boundary preserves:

- HttpOnly access/refresh cookies;
- HttpOnly terminal credential cookie;
- Secure cookies on HTTPS;
- same-origin protection on state-changing routes;
- server-side employee role/disabled/branch validation;
- caller JWT forwarding to Supabase;
- server-side terminal credential forwarding only where required;
- no browser-readable employee bearer-token persistence;
- no service-role credential in browser/Vite code.

Explicit UI Preview remains non-authoritative and cannot substitute fixture IDs for live branch/terminal authority.

## Writable-database regression evidence

Backend database audit run #22 reconstructed a clean Supabase instance from canonical migrations and passed:

```text
branch_authority_integration.sql              PASS
operational_topology_integration.sql         PASS
order_integration.sql                        PASS
scheduled_order_operations_integration.sql   PASS
```

This proves the intended allow/deny rules on a fresh install rather than relying only on live-schema inspection.

## Client executable evidence

```text
Customer release audit #114   PASS
Dashboard CI #23              PASS
Dashboard Vitest              31 files / 150 tests PASS
```

## Advisor state

Current Supabase security advisor reports one pre-existing WARN only:

```text
auth_leaked_password_protection — Leaked Password Protection Disabled
```

No Phase 1-created security WARN/ERROR remains.

Performance findings are INFO-only unused indexes on the current small dataset. The missing FK-supporting index previously identified for `employee_branch_assignments.assigned_by` was fixed.

## Preserved non-live work

Account-deletion/referral SQL under `supabase/drafts/` remains non-applied and must not be treated as live authority. Related client surfaces remain default-off where preserved.

## Still deferred security/authority domains

- shift/cash authority and variance approval;
- employee Auth-user provisioning, role mutation and badge/PIN lifecycle;
- branch hours/closures/capacity and explicit customer pickup branch;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- tax/accounting/reporting;
- payment capture/refunds/processor settlement;
- printer/KDS/payment-device integrations;
- delivery;
- hosted production operations.

Full Phase 1 evidence: `docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`.
