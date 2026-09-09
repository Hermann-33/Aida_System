# Current Handoff

Updated: 2026-08-23

## Task

`TASK-MENU-CUSTOMIZATION-001 — per-drink option groups, per-line add-ons, Now terminology, and post-add navigation`

**Verdict:** COMPLETE.

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

## 2026-09-09 — TASK-UI-REDESIGN-004

Audited integration of `customer-app-redesign` is being carried by PR #19 from `codex/task-ui-redesign-004-audit-integration`.

The merge strategy preserves useful source work without silently activating unfinished backend features:

- active UI/branding refresh is included;
- account-deletion/referral SQL prototypes are preserved under `supabase/drafts/`, not canonical migrations;
- related client paths are compile-time gated off by default;
- Staff/order demo/test controls are retained only for debug builds and use synthetic demo orders;
- production order state remains Supabase-authoritative;
- stale generated iOS project churn is not copied; App Store migration notes are preserved separately.

Final merge requires the customer release-audit workflow to pass on the final PR head. PR #19 must be squash-merged so mixed source-branch ancestry is not introduced into `master`.
