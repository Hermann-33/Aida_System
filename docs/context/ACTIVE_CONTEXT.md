# Active Context

**As of:** 2026-09-10
**Current task:** `TASK-OPS-001 — branch/location authority foundation`
**Current verdict:** PARTIAL — live Supabase branch authority is deployed and repository integration is in progress; executable writable-database regression and Dashboard location-management wiring remain open.

Detailed current evidence:

- `docs/frontend/UI_REDESIGN_AUDIT_2026-09-09.md`
- PR #19 / `codex/task-ui-redesign-004-audit-integration`
- customer release audit run #87 PASS on code head `7388c1bd40b7da4c0ce56041b8e0e02ece3847db`

Previous menu-customization closeout remains COMPLETE and is documented in:

- `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`

Previous scheduled-order operations work remains COMPLETE and is documented in:

- `docs/context/SCHEDULED_ORDER_OPERATIONS_2026-08-20.md`

## TASK-UI-REDESIGN-004 current integration

The final integration accepts the reviewed mobile presentation refresh and excludes all demo-only order/status/test tooling. Production order status remains persisted Supabase state only.

Useful future work is preserved without becoming live authority:

- account-deletion/referral SQL prototypes live only under `supabase/drafts/`;
- `AIDA_ENABLE_ACCOUNT_DELETION_DRAFT` defaults false;
- `AIDA_ENABLE_REFERRAL_DRAFT` defaults false;
- no new canonical Supabase migration is introduced;
- referral sharing is pinned to `share_plus 11.1.0` to remain compatible with the current Android toolchain until a dedicated Android modernization task.

The reviewed UI remains within AIDA's existing cream/coffee/espresso/rose theme and accepted typography/control language.

## Current product reality

AIDA Café is one product across the Flutter customer app, React Dashboard/Admin/POS and shared Supabase project `eswovqxqzfevcdwwcmuh`.

The implemented trusted tranche now includes:

- Supabase Auth/member provisioning;
- protected same-origin employee/Admin sessions;
- shared catalogue and revision invalidation;
- catalogue-driven product variants, per-drink option groups and compatible add-ons;
- authoritative quote/order pricing and immutable line snapshots;
- Now/scheduled pickup and server-owned scheduled preparation classification;
- customer history/status plus owner-scoped Realtime invalidation;
- Dashboard POS ordering, operational queue and legal versioned status transitions;
- the verified AIDA customer redesign and matching Dashboard theme integration.

Frontends remain non-authoritative for identity, roles, catalogue commercial truth, modifier validity, pricing, order state, payment, loyalty, inventory or reporting.

## Menu customization — live contract

Standard drink groups are currently:

```text
Temperature: Hot | Iced
Sweetness: Regular | Less sweet | Least sweet
```

The groups are reusable server catalogue definitions. Per drink, Admin/Owner can configure customer label, price delta, availability and exactly one available default.

Compatible add-ons remain catalogue items of kind `addon`, linked to individual products. Customer browsing hides add-on rows/categories as standalone products; the same add-on can be selected independently on one cart line and omitted from another.

Order intents now support:

```text
itemId
variantId
optionValueIds[]
addOnIds[]
quantity
note
```

Supabase revalidates all selected IDs and calculates authoritative price. `pricingVersion=2` includes option deltas. `order_line_options` stores immutable group/value/label/price snapshots.

Older clients that omit option IDs are handled by the live quote function through each group's configured available default. Clients still must not submit trusted labels/prices/totals.

## Customer behavior

Customer-facing item configuration now presents Size, Temperature, Sweetness and compatible Customize/add-on controls from the catalogue. Unavailable options remain visible but disabled with explicit semantics; selected state is not color-only.

`Add to cart` creates the configured line and immediately returns to Menu. Distinct Temperature/Sweetness/add-on combinations remain distinct cart configurations.

Checkout terminology is `Now | Schedule`; only the customer-facing label changed. The wire/backend value remains `asap` for compatibility. The accepted tactile scheduling wheel still renders only policy-derived valid pickup slots.

## Dashboard / POS behavior

Admin Menu management exposes drink status plus per-option label, price delta, availability and default controls, along with compatible add-on checkboxes. Invalid required groups are rejected before save and by the backend.

POS consumes the same catalogue contract:

- variants: required single-choice when present;
- Temperature/Sweetness: required single-choice;
- add-ons: optional multi-select;
- unavailable options: visible/disabled and not selectable.

Order placement sends IDs/quantity/note/fulfilment intent only. Same-origin HttpOnly employee-session architecture and Admin/Owner authorization remain unchanged.

## Live evidence

Checked on 2026-08-23:

```text
catalogue revision         130
drink products              11
non-drink products           4
add-ons                      4
invalid required groups      0
Iced Drinks with Hot on      0
```

Live migrations:

- `20260822135421_add_drink_customization_catalogue`
- `20260822135602_integrate_drink_customizations_with_orders`
- `20260822141814_harden_drink_customization_indexes_and_rls`
- `20260822143542_grant_public_drink_customization_reads`

Privilege checks confirm public catalogue/quote execution and intended option-table reads while ordinary authenticated users retain no direct `order_line_options` table read.

Security advisor: one pre-existing WARN only — `auth_leaked_password_protection` / Leaked Password Protection Disabled. Performance findings are INFO-only unused indexes.

## Executable client evidence

Customer final Codex validation commit:

`404662aec382364c8e70fcee8d66b38d4b303f0a`

- Flutter 3.44.7 / Dart 3.12.2 / JDK 21.0.12;
- analyze PASS;
- 55/55 tests PASS;
- format and `git diff --check` PASS;
- exact-size UI/golden QA PASS at 390x844 and 430x932;
- secret scan PASS;
- no physical Android device was connected for this final validation pass.

Dashboard final Codex validation commit:

`af0fcd2babfa02073f882ec63ddbec102e591672`

- `npm ci` PASS, 0 vulnerabilities;
- lint PASS with two pre-existing Fast Refresh warnings;
- typecheck PASS;
- Vitest 129/129 PASS across 29 files;
- production build PASS with existing chunk-size advisory;
- Playwright 10/10 PASS;
- desktop visual QA PASS at 1366x768 and 1440x900;
- no task-related console errors/warnings.

Both UI reviews PASS against the existing AIDA theme/design systems; no Luckin branding/palette or second design system was introduced.

## Branch state / release boundary

Matching task branches:

`codex/task-menu-customization-001-modifier-groups`

Before documentation closeout:

- customer branch: 37 commits ahead of `master`, 0 behind;
- Dashboard branch: 12 commits ahead of `main`, 0 behind.

No PR or merge is part of this closeout. Merge, APK build/install and hosted release remain separate explicit actions.

## Still deferred

- branch-specific catalogue/scheduling/capacity and branch-scoped queues;
- terminal/sales-point authority;
- shifts/cash reconciliation;
- payment/refunds;
- loyalty;
- inventory;
- promotions/discounts;
- tax/accounting/reporting;
- delivery;
- hosted production deployment.


## TASK-OPS-001 — branch/location authority foundation

Live Supabase now contains trusted branch authority:

- `branches` with one active default `BR-MAIN — Main Café`;
- `employee_branch_assignments` for trusted employee operational scope;
- immutable `orders.branch_id`, backfilled for all pre-existing orders;
- ordinary staff order reads/transitions restricted to assigned branches;
- Admin/Owner remain global operational roles for this tranche;
- existing customer/POS payloads remain compatible by resolving the active default branch server-side;
- branch directory and employee-assignment mutation RPCs are Admin/Owner-authorized;
- all new exposed tables use RLS + FORCE RLS and explicit Data API grants.

Live migrations:

```text
20260910014434 create_branch_location_authority
20260910014457 index_employee_branch_assignment_actor
```

Current live verification:

```text
branches                  1
active default branches   1
default code              BR-MAIN
orders without branch     0
existing orders           25
employee assignments      3
staff without assignment  0
```

Dashboard task-branch integration replaces the hardcoded empty `assignedBranchIds` session claim with caller-JWT-backed `employee_branch_assignments` reads, fails closed for ordinary staff with no branch assignment, and exposes same-origin BFF/API routes for public/Admin branch reads, branch mutation, Admin employee listing and employee-branch assignment mutation.

Validation gap: the connected SQL inspection role is read-only, so `supabase/tests/branch_authority_integration.sql` is committed but has not been executed against a writable local/dev database in this session.

The previous customer UI redesign PR #19 is merged and closed. Any earlier `READY TO MERGE` wording for PR #19 is historical/stale.

Accepted decision: `docs/decisions/ADR-0011-branch-authority-and-operational-scope.md`.
