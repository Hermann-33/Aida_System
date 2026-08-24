# Menu Customization Closeout — 2026-08-23

## Task

`TASK-MENU-CUSTOMIZATION-001 — per-drink option groups, per-line add-ons, Now terminology, and post-add navigation`

**Verdict:** COMPLETE.

This task extends the accepted shared-catalogue/order architecture with reusable drink customization groups while preserving Supabase as catalogue, compatibility, pricing, quote and order authority.

## Delivered behavior

### Customer app

A drink detail can now expose, from the live catalogue:

- Size / variant where applicable;
- Temperature;
- Sweetness;
- compatible per-line add-ons;
- quantity;
- optional note.

Add-ons remain catalogue items of kind `addon`, but customer browsing filters them out as standalone menu products/categories. They appear only when the edited drink declares compatibility. Two copies of the same drink can therefore carry different add-on and option selections without sharing state.

Customer-facing fulfilment terminology is `Now | Schedule`; the trusted wire/backend enum remains `asap | scheduled` for compatibility.

After a configured item is added, the item-detail route closes immediately and returns the customer to Menu.

The existing AIDA customer visual language is preserved: cream/ivory and white surfaces, coffee/burgundy selected state, Playfair + Plus Jakarta Sans, existing tactile/neumorphic controls, the existing scheduled pickup wheel, explicit unavailable text/semantics, and non-color-only selected indicators.

### Dashboard / POS

Admin Menu management can mark a product as a drink and configure each standard option per item:

- customer-facing label;
- price delta in sen;
- availability;
- exactly one available default per required group.

Compatible add-ons remain product-specific checkboxes in the same editor.

POS consumes the same catalogue groups. Temperature and Sweetness are required single-choice groups; compatible add-ons are optional multi-select. Unavailable options remain visible/disabled and cannot be submitted.

The implementation reuses the established Dashboard tokens, Admin form/card classes, native radio/checkbox semantics, focus-visible behavior and POS modifier density.

## Shared backend

Live Supabase migrations:

1. `20260822135421_add_drink_customization_catalogue`
2. `20260822135602_integrate_drink_customizations_with_orders`
3. `20260822141814_harden_drink_customization_indexes_and_rls`
4. `20260822143542_grant_public_drink_customization_reads`

Canonical SQL lives in the customer repository `supabase/migrations/` directory.

New/extended trusted data includes:

- `catalogue_items.is_drink`;
- `catalogue_option_groups`;
- `catalogue_option_values`;
- `catalogue_item_option_values`;
- `order_lines.option_total_sen`;
- `order_line_options` immutable snapshots.

Current standard groups are:

```text
Temperature
- Hot
- Iced

Sweetness
- Regular
- Less sweet
- Least sweet
```

The backend remains authoritative. Clients send only selection IDs and intent. Order lines may include:

```text
itemId
variantId
addOnIds[]
optionValueIds[]
quantity
note
```

Clients do not submit trusted names, option labels, price deltas, unit prices, totals, customer/member identity, order status or payment truth.

`quote_order(jsonb)` validates option ownership/availability, enforces at most one selected value per required group, supplies the configured available default when an older client omits a group selection, and calculates:

```text
base price
+ variant delta
+ option deltas
+ compatible add-ons
= authoritative unit price
```

The deployed quote contract is `pricingVersion = 2`.

Selected option group/value identity, customer-facing snapshot labels and price deltas are persisted in `order_line_options` so later catalogue edits do not rewrite historical orders.

## Live backend verification

Checked on 2026-08-23 against project `eswovqxqzfevcdwwcmuh`:

```text
catalogue revision:       130
drink products:            11
non-drink products:         4
add-ons:                    4
invalid required groups:    0
Iced Drinks with Hot on:    0
```

Every live drink group has at least one available value and exactly one available default.

Privilege checks confirm:

- anonymous can execute `get_catalogue()` and `quote_order(jsonb)`;
- authenticated can execute `quote_order(jsonb)`;
- anonymous/authenticated catalogue-option reads have the intended table grants plus RLS;
- ordinary authenticated users have no direct `SELECT` grant on immutable `order_line_options`.

The current database connector runs as a read-only inspection role and cannot `SET ROLE anon`, so closeout did not manufacture a production order merely to exercise the RPC. The deployed `quote_order` definition was inspected directly and executable client tests cover the emitted option-ID payload contract.

## RLS / advisor state

The new option catalogue and order snapshot tables retain RLS + FORCE RLS according to their role.

Post-DDL security advisor result:

- one pre-existing WARN only: `auth_leaked_password_protection` / Leaked Password Protection Disabled.

No new security WARN/ERROR was introduced by this task.

Performance advisor results are INFO-only unused-index notices, including recently added FK-supporting indexes on the small current dataset.

## Customer executable validation

Codex final validation commit:

`404662aec382364c8e70fcee8d66b38d4b303f0a` — `fix: complete customer modifier group validation`

Reported environment/results:

- Flutter 3.44.7;
- Dart 3.12.2;
- JDK 21.0.12;
- `flutter pub get`: PASS;
- format check: PASS, 86 files / 0 changes;
- `flutter analyze`: PASS, no issues;
- `flutter test`: PASS, 55 passed / 0 failed / 0 skipped;
- `git diff --check`: PASS;
- secret scan: PASS;
- exact-size UI/golden QA: PASS at 390x844 and 430x932;
- long labels and text scale 1.2 exercised;
- no Android device was connected for this final validation pass.

The validation fixes make unavailable server options visible but disabled, add explicit selected check icons/semantics, enlarge add-on touch targets, prevent fixed-nav overlap, and add focused catalogue/cart/order regressions.

## Dashboard executable validation

Codex final validation commit:

`af0fcd2babfa02073f882ec63ddbec102e591672` — `fix: validate dashboard menu customization`

Reported environment/results:

- Node v24.11.1;
- npm 11.6.2;
- `npm ci`: PASS, 203 packages / 0 vulnerabilities;
- lint: PASS with two established Fast Refresh warnings;
- typecheck: PASS;
- Vitest: PASS, 29 files / 129 tests;
- production build: PASS with existing large-chunk advisory only;
- Playwright: PASS, 10/10;
- `git diff --check`: PASS;
- visual QA: PASS at 1366x768 and 1440x900;
- browser console: no errors or warnings caused by this task.

The final UI pass aligned Admin drink-option rows with existing tokens/classes, preserved native labelled radios/checkboxes and reduced-motion/focus behavior, and verified POS required/optional modifier semantics.

## Trust-boundary result

Preserved:

- Supabase catalogue/pricing/quote/order authority;
- caller-ID-only order intents;
- same-origin HttpOnly employee BFF architecture;
- Admin/Owner-only catalogue mutation;
- staff excluded from Admin;
- no service-role credential in Flutter/Vite/browser code;
- no browser employee bearer-token persistence;
- no fabricated branch/terminal/shift authority;
- Pay-at-counter remains unpaid presentation, not payment settlement.

## Branch / merge state at closeout

Matching task branches:

`codex/task-menu-customization-001-modifier-groups`

Before documentation closeout, the customer branch was 37 commits ahead of `master` and 0 behind; the Dashboard branch was 12 commits ahead of `main` and 0 behind.

No PR is created or merged by this closeout. Merge/deployment remain separate repository/release actions.

## Deferred domains

Still separate tasks:

- branch-specific catalogue/scheduling/capacity;
- terminal/sales-point authority;
- shifts/cash reconciliation;
- payment/refunds;
- loyalty;
- inventory;
- promotions/discounts;
- tax/accounting/reporting;
- delivery;
- hosted production operations.
