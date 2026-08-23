# Active Context

**As of:** 2026-08-23
**Current task:** `TASK-MENU-CUSTOMIZATION-001 — per-drink option groups, per-line add-ons, Now terminology, and post-add navigation`
**Current verdict:** COMPLETE — live Supabase catalogue/order customization authority is in place; Customer and Dashboard/POS integrations pass executable validation and UI/theme review; backend grants/RLS/advisors and canonical documentation are reconciled.

Detailed closeout evidence:

- `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`

Previous scheduled-order operations work remains COMPLETE and is documented in:

- `docs/context/SCHEDULED_ORDER_OPERATIONS_2026-08-20.md`

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
