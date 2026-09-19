# Codebase Map

Updated: 2026-09-11

## Customer/backend repository — `Hermann-33/Aida_System`

### Customer identity/member runtime

- `apps/customer/lib/data/repository/supabase_member_repository.dart` — Supabase Auth and owner-scoped member/profile reads.
- `apps/customer/lib/data/cache/offline_member_cache.dart` — minimum per-user member identity/code cache; never role, pricing or loyalty authority.
- `apps/customer/lib/application/providers.dart` — Auth/member/catalogue/cart/order composition.
- `apps/customer/lib/features/auth/login_screen.dart` — customer sign-in/sign-up UI.

### Customer catalogue/customization runtime

- `apps/customer/lib/data/repository/supabase_catalogue_repository.dart` — `get_catalogue()` decode and `catalogue_revision` invalidation.
- `apps/customer/lib/domain/model/menu_item.dart` — product/add-on identity and customization relationships.
- `apps/customer/lib/domain/model/menu_variant.dart` — variants.
- `apps/customer/lib/domain/model/menu_customization.dart` — reusable option groups/values.
- `apps/customer/lib/features/menu/menu_screen.dart` — customer browse; hides standalone add-on rows/categories.
- `apps/customer/lib/features/menu/item_detail_screen.dart` — Size, Temperature, Sweetness, compatible add-ons, quantity and note.

### Customer order runtime

- `apps/customer/lib/domain/model/cart.dart` — per-line configuration/equivalence and estimate calculation.
- `apps/customer/lib/domain/model/order.dart` — selection/quote/order snapshot models.
- `apps/customer/lib/data/repository/supabase_order_repository.dart` — ordering policy, quote, place, history/detail and owner-scoped invalidation RPCs.
- `apps/customer/lib/application/order_checkout.dart` — policy-derived scheduling and retry-stable `clientRequestId` lifecycle.
- `apps/customer/lib/features/cart/order_checkout_sheet.dart` — Now/Schedule, authoritative quote and pay-at-counter placement.

Phase 1 does not add terminal authority to the customer runtime. Customer placement remains default-branch compatible and terminal-free.

### Preserved customer future work

- `apps/customer/lib/core/config/feature_flags.dart` — compile-time gates for preserved future account-deletion/referral client work.
- `supabase/drafts/` — non-applied prototypes; not backend authority.

## Canonical Supabase ownership

Canonical executable migrations live under `supabase/migrations/`.

Phase 1 / operational-scope migration sequence:

```text
supabase/migrations/20260910014434_create_branch_location_authority.sql
supabase/migrations/20260910014457_index_employee_branch_assignment_actor.sql
supabase/migrations/20260910023510_create_operational_sales_points_and_terminals.sql
supabase/migrations/20260910023552_harden_operational_topology_rls_and_indexes.sql
supabase/migrations/20260910040814_revoke_direct_branch_mutation_grants.sql
supabase/migrations/20260910041057_enforce_terminal_branch_scope_on_resolution.sql
supabase/migrations/20260910042619_differentiate_terminal_resolution_failures.sql
supabase/migrations/20260910044613_grant_branch_rpc_private_impl_execution.sql
supabase/migrations/20260910050152_grant_admin_operational_topology_reads.sql
```

Important existing catalogue/order migrations remain earlier in the same canonical ledger. Already-accepted historical filenames must not be renamed merely to match live migration-history timestamps.

### Backend regression suite

Phase 1 database gate runs:

```text
supabase/tests/branch_authority_integration.sql
supabase/tests/operational_topology_integration.sql
supabase/tests/order_integration.sql
supabase/tests/scheduled_order_operations_integration.sql
```

`.github/workflows/backend-database-audit.yml` starts a clean local Supabase instance, replays canonical migrations and executes those four regressions. The workflow pins Supabase CLI `2.117.0` rather than resolving `latest` at runtime.

Backend database audit run #22 passes all four suites.

## Dashboard repository — `Hermann-33/Aida_System-Dashboard`

### Employee/session server boundary

- `server/employeeBff.ts` — employee login/session/logout, caller-JWT validation, trusted `assignedBranchIds` and fail-closed unassigned staff behavior.
- `server/catalogueBff.ts` — public/Admin catalogue BFF.
- `server/orderBff.ts` — policy/quote/place/queue/detail/status/admin-policy BFF; live POS placement forwards the server-held terminal credential.
- `server/locationBff.ts` — public/Admin branch and employee-branch management BFF.
- `server/terminalBff.ts` — Admin topology, terminal enrolment/status/revocation/credential operations.
- `server/viteBffPlugin.ts` — local Vite mounting of same-origin BFF routes.
- `api/v1/**` — production route adapters for auth, catalogue, branches, Admin operational topology, terminal lifecycle and orders.

No service-role credential or employee bearer token is exposed to React.

### Browser identity/terminal coordination

- `src/auth/employeeSession.ts` — employee-session browser coordination only; HttpOnly tokens remain inaccessible to JS.
- `src/auth/types.ts` — employee identity, assigned branches and operational display types.
- `src/auth/terminalCredential.ts` — browser-facing terminal context/status calls without exposing the underlying terminal credential.
- `src/auth/terminalCredential.test.ts` — terminal-context behavior regressions.
- `src/auth/ProtectedRoute.tsx` — browser route gating only, never backend authorization authority.

### Trusted operational-location client

- `src/features/locations/operationalLocationClient.ts` — typed live branch/sales-point/terminal/Admin employee API client.

### Admin live operational pages

- `src/features/admin/AdminLocationsPage.tsx` — live branches and sales points through trusted APIs; Preview mode remains fixtures.
- `src/features/admin/AdminTerminalsPage.tsx` — live terminal create/list/enrolment-code/revoke flows; Preview remains fixtures.
- `src/features/admin/AdminEmployeesPage.tsx` — live trusted employee directory and branch-assignment mutation; employee account creation/role mutation remains deferred.

### POS live operational runtime

- `src/pages/PosShellPage.tsx` — live staff POS shell, including trusted terminal-state requirement and branch-scope denial presentation.
- `src/pages/liveStaffPos.test.tsx` — live POS shell regressions.
- `src/features/pos/posCatalogue.ts` — shared catalogue -> POS modifier groups.
- `src/features/pos/ModifierSheet.tsx` — modifier selection UI.
- `src/features/pos/CounterWorkspace.tsx` — POS cart/workspace.
- `src/features/orders/orderClient.ts` — selection-only intent mapping plus trusted order/schedule parsing.
- `src/features/orders/OrderCheckoutPanel.tsx` — authoritative quote/place flow.
- `src/features/orders/OrderBoard.tsx` — trusted Active/Scheduled/Ready/History workload projection.

### Phase 1 server tests

Key server regressions include:

- `server/employeeBff.test.ts` — trusted branch assignments and fail-closed staff session behavior;
- `server/locationBff.test.ts` — public/Admin branch and employee-assignment BFF boundaries;
- terminal BFF/unit coverage for enrolment/status/Admin topology paths;
- existing order BFF tests updated for terminal-bound POS placement.

Dashboard CI run #23 passes 31 test files / 150 tests plus lint, typecheck and production build.

## Shared backend model after Phase 1

```text
catalogue_items / variants / add-ons / option groups
orders / immutable line snapshots / events
branches
employee_branch_assignments
sales_points
terminals
private terminal enrolment/credential state
orders.branch_id
orders.sales_point_id
orders.terminal_id
```

The live POS placement contract is terminal-bound; client topology IDs are not placement authority.

## Current closeout state

`TASK-OPS-002` / Phase 1 is `COMPLETE` and frozen for Astra review.

Evidence:

```text
Backend database audit #22      PASS
Customer release audit #114     PASS
Dashboard CI #23                PASS
```

Detailed evidence:

`docs/context/PHASE_1_OPERATIONAL_TOPOLOGY_CLOSEOUT_2026-09-11.md`

PR #20 and PR #17 are the audit boundary. Do not start Phase 2 until Astra findings are resolved or explicitly accepted.

## Deferred code domains

The following existing preview/presentation surfaces must not be mistaken for trusted authority until their later phases:

- shifts/cash and variance approval;
- employee Auth-user provisioning, role mutation and badge/PIN lifecycle;
- branch hours/capacity/customer branch selection;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- reporting/accounting;
- payment/refunds/processor settlement;
- printer/KDS/payment-device integration;
- delivery;
- hosted production/release operations.
