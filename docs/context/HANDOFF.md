# Current Handoff

Updated: 2026-09-10

## Task

`TASK-UI-REDESIGN-004 — audited customer UI refresh and safe future-work preservation`

**Verdict:** READY TO MERGE.

Detailed implementation/validation evidence:

`docs/context/MENU_CUSTOMIZATION_2026-08-23.md`

Matching task branches:

`codex/task-menu-customization-001-modifier-groups`

No PR or merge was created by this closeout.

## What changed

### Customer

- drink detail is catalogue-driven for Size, Temperature, Sweetness and compatible add-ons;
- selected option/add-on state belongs to the individual cart line;
- add-on catalogue rows/categories are hidden from normal customer browsing;
- local cart estimates include variant + option + add-on deltas while server quote remains final authority;
- order intents include `optionValueIds` but no trusted prices/totals;
- unavailable options remain visible/disabled with explicit text/semantics;
- `Add to cart` immediately returns to Menu;
- checkout presentation says `Now`, while the backend wire value remains `asap`;
- accepted policy-derived Schedule wheel remains intact.

### Dashboard / POS

- Admin can mark a product as a drink;
- each drink option exposes editable customer label, price delta, availability and default;
- every required group must have at least one available option and exactly one available default;
- compatible add-ons remain per-product checkboxes;
- POS maps variants + required Temperature/Sweetness + optional add-ons into per-line modifier state;
- POS order payload includes `optionValueIds` only as selection IDs;
- preview remains read-only; staff remains excluded from Admin.

### Backend

Live migrations:

```text
20260822135421 add_drink_customization_catalogue
20260822135602 integrate_drink_customizations_with_orders
20260822141814 harden_drink_customization_indexes_and_rls
20260822143542 grant_public_drink_customization_reads
```

Trusted additions:

- `catalogue_items.is_drink`;
- `catalogue_option_groups`;
- `catalogue_option_values`;
- `catalogue_item_option_values`;
- `order_lines.option_total_sen`;
- `order_line_options` immutable selected-option snapshots;
- `pricingVersion=2` quote calculation includes option deltas.

The live quote definition supplies the configured available default for a required group when an older client omits an `optionValueId`, preserving rollout compatibility.

## Live closeout checks

Checked on 2026-08-23:

```text
catalogue revision         130
drink products              11
non-drink products           4
add-ons                      4
invalid required groups      0
Iced Drinks with Hot on      0
```

Public/authenticated function/table grants align with the intended RLS boundary. Ordinary authenticated users have no direct read grant on immutable `order_line_options`.

Supabase security advisor has one pre-existing WARN only: Leaked Password Protection Disabled. Performance findings are INFO-only unused indexes.

## Executable validation

### Customer

Final validation commit:

`404662aec382364c8e70fcee8d66b38d4b303f0a`

Results:

- Flutter 3.44.7 / Dart 3.12.2 / JDK 21.0.12;
- `flutter pub get` PASS;
- format PASS;
- analyze PASS;
- Flutter tests 55 passed / 0 failed / 0 skipped;
- `git diff --check` PASS;
- secret scan PASS;
- UI/golden review PASS at 390x844 and 430x932;
- no physical Android device was connected for this final pass.

### Dashboard

Final validation commit:

`af0fcd2babfa02073f882ec63ddbec102e591672`

Results:

- Node v24.11.1 / npm 11.6.2;
- `npm ci` PASS, 0 vulnerabilities;
- lint PASS with two established Fast Refresh warnings;
- typecheck PASS;
- Vitest 29 files / 129 tests PASS;
- build PASS with existing large-chunk advisory only;
- Playwright 10/10 PASS;
- `git diff --check` PASS;
- visual QA PASS at 1366x768 and 1440x900;
- no task-related browser console errors/warnings.

## UI consistency

Customer customization keeps the accepted AIDA rose/cream/espresso palette, Playfair + Plus Jakarta Sans, tactile/neumorphic controls, existing hero/sheet hierarchy, selected check indicators and explicit disabled text.

Dashboard uses the existing design tokens, Admin cards/form classes, labelled native radios/checkboxes, focus-visible/reduced-motion behavior and existing POS modifier density. No Luckin styling or second theme was introduced.

## Security/trust result

Preserved:

- Supabase commercial authority;
- RLS/FORCE-RLS boundaries;
- Admin/Owner catalogue mutation;
- caller-JWT same-origin HttpOnly employee BFF;
- no browser employee token persistence;
- no service-role credential in clients;
- no fabricated branch/terminal/shift authority;
- Pay-at-counter remains unpaid presentation, not payment settlement.

## Next action

This task is ready for repository merge/release handling, but those are separate explicit actions. If merging, merge both matching task branches so the two frontends remain contract-compatible with the already-live backend.

After a customer merge, build a fresh APK from the merged customer default branch before distribution. The final Codex validation did not use a connected physical Android device.

## Deferred domains

Branch authority/capacity, terminal/sales-point lifecycle, shifts/cash reconciliation, payment/refunds, loyalty, inventory, promotions/discounts, tax/accounting/reporting, delivery and hosted production operations remain separate tasks.

## 2026-09-10 — TASK-UI-REDESIGN-004 final handoff

PR #19 carries the audited integration from `codex/task-ui-redesign-004-audit-integration`.

Final accepted scope:

- reviewed customer UI/branding refresh is active;
- all demo-only order/status/test tooling is removed;
- account-deletion/referral SQL prototypes are preserved under `supabase/drafts/`, not canonical migrations;
- related account-deletion/referral client surfaces are compile-time gated off by default;
- useful iOS migration observations are documented, while stale generated Xcode/CocoaPods state is excluded;
- production order status remains Supabase-authoritative;
- generated golden failure artifacts are excluded.

Release compatibility correction:

- `share_plus 13.3.0` caused the release APK build to fail because that package generation requires Kotlin 2.2-era Android artifacts;
- the dormant referral-sharing prototype is pinned to `share_plus 11.1.0` instead of forcing an unrelated Android toolchain migration in this UI task;
- lockfile dependencies are reconciled accordingly.

Executable validation:

- workflow: Customer release audit run #87;
- code head: `7388c1bd40b7da4c0ce56041b8e0e02ece3847db`;
- dependency resolution PASS;
- Flutter analyze PASS;
- non-golden regression PASS;
- golden regression PASS;
- release APK build PASS;
- release APK upload PASS.

The subsequent branch changes are documentation-only closeout. PR #19 must be squash-merged so the original mixed source-branch ancestry does not enter `master`.



## 2026-09-10 — TASK-OPS-001 branch authority handoff

**Verdict:** PARTIAL.

Matching task branches:

```text
Hermann-33/Aida_System
  codex/task-ops-001-branch-authority

Hermann-33/Aida_System-Dashboard
  codex/task-ops-001-branch-authority
```

Live backend changes:

- deployed `20260910014434 create_branch_location_authority`;
- deployed `20260910014457 index_employee_branch_assignment_actor`;
- created trusted `BR-MAIN — Main Café`;
- added `branches` and `employee_branch_assignments`;
- added immutable non-null `orders.branch_id`;
- backfilled all existing orders and employee scopes;
- scoped ordinary staff order reads/status transitions by branch;
- preserved Admin/Owner global scope and existing-client default-branch compatibility;
- added Admin/Owner branch and employee-assignment RPCs;
- preserved RLS/FORCE-RLS and caller-JWT architecture.

Live verification:

```text
branches                  1
active defaults           1
orders without branch     0 / 25
employee assignments      3
staff without assignment  0
security advisor          1 pre-existing WARN only
new unindexed FK findings 0
```

Repository integration:

- canonical migration files recorded in the customer repository;
- branch authority SQL regression added;
- Dashboard employee BFF now loads trusted `assignedBranchIds`;
- missing staff assignment fails closed;
- BFF unit tests updated.

Remaining gate:

- execute `supabase/tests/branch_authority_integration.sql` on a writable local/dev database;
- run Dashboard lint/typecheck/Vitest/build on the task branch;
- wire Admin Locations/Employees to the new trusted branch APIs in a bounded Dashboard task.

Exact next backend dependency: trusted sales-point/terminal authority under branches, followed by shift/cash authority. Branch opening-hours/capacity remains a separate scheduling task.
