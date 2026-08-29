# Active Context

**As of:** 2026-08-29
**Current tasks (uncommitted on `customer-app-redesign`):**

- `TASK-REDESIGN-001 — app-wide popup redesign, Rewards tear-to-apply animation, membership card/profile/order-confirmation redesigns, menu search, splash screen, demo order-progress system, new Settings screen` — **COMPLETE** for presentation-layer scope.
- `TASK-REFERRAL-001 — "Invite a friend" referral program` — **PARTIAL**: migration drafted, not applied/verified against live Supabase.
- `TASK-ACCT-001 — customer self-service account deletion` — **PARTIAL**: migration + client complete, not applied/verified against live Supabase.

Detailed evidence:

- `docs/frontend/UI_REDESIGN_SPEC.md` §20 (`TASK-REDESIGN-001`)
- `docs/context/BACKEND_MIGRATIONS_2026-08-29.md` (`TASK-REFERRAL-001`, `TASK-ACCT-001`)

**Important:** none of this work is committed to git as of 2026-08-29 — it
is working-tree state on `customer-app-redesign`. It is also large: it
touches most customer-app screens plus two shared-backend migrations. This
task's environment had no access to the live Aida Supabase project (the
only reachable Supabase MCP connection resolved to an unrelated project,
"Cheater's Market") — see `docs/context/SUPABASE_STATUS.md`.

Previous menu-customization work remains COMPLETE and is documented in:

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

`Add to cart` creates the configured line, briefly shows an in-place confirmation, then returns to Menu — see `docs/frontend/UI_REDESIGN_SPEC.md` §19 for how the two branches' differing Add-to-cart behavior was reconciled during the 2026-08-24 merge. Distinct Temperature/Sweetness/add-on combinations remain distinct cart configurations.

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
- loyalty — partial exception: `TASK-REFERRAL-001` migration drafted, unapplied (see 2026-08-29 addition below);
- inventory;
- promotions/discounts;
- tax/accounting/reporting;
- delivery;
- hosted production deployment.

## 2026-08-19 — customer UI redesign (documentation task)

**Task:** `TASK-UI-REDESIGN-001 — document the customer UI redesign` (mobile-repository scope only).

**Verdict:** COMPLETE for this task's mobile-documentation scope.

Branch: `customer-app-redesign` (pushed to `Hermann-33/Aida_System`, not yet merged/PR'd). A presentation-layer redesign of five customer surfaces — Menu, Item detail, Cart, Checkout sheet, Rewards — was inspected and documented in the new `docs/frontend/UI_REDESIGN_SPEC.md`. No backend, data-flow, or trust-boundary fact from this file changed as a result: `UI_SCREEN_MAP.md`'s table is unchanged (same file paths, purpose, data source, status for all five surfaces).

One real interaction-boundary change was found and flagged at the time (not fixed, per this task's documentation-first scope): the checkout sheet's pickup-time picker no longer clamped minute selection to `OrderingPolicy.slotIntervalMinutes`, so a non-15-minute selection would fail `quote_order` against the current backend contract; same-day scheduling also enforced a client-only 8am–5pm window with no server-side counterpart. Both were recorded in `UI_REDESIGN_SPEC.md`, `UI_SCREEN_MAP.md` and `FRAGILE_BOUNDARIES.md`.

**Resolved 2026-08-24:** merging `customer-app-redesign` with `hermann/master` (which had independently landed `TASK-MENU-CUSTOMIZATION-001`) replaced that picker with a server-slot-driven wheel; see `UI_REDESIGN_SPEC.md` §19. Both flagged items are closed.

Customer toolchain re-verified on this branch at the time: `flutter analyze` 0 issues; `flutter test` 40/44 passing, with the same 4 golden-image failures (`home`, `home scrolled`, `menu with a category selected`, `membership card`) that predate this redesign and were not touched. Post-merge (2026-08-24) all 55 tests pass; see "Menu customization — live contract" above for the merged state.

Cross-repository documentation sync: **PENDING** — `Hermann-33/Aida_System-Dashboard` was not in scope for this task and was not inspected, cloned, or modified.

## 2026-08-29 — large uncommitted presentation pass + two drafted backend migrations

**Tasks:** `TASK-REDESIGN-001` (COMPLETE, presentation-layer),
`TASK-REFERRAL-001` and `TASK-ACCT-001` (both PARTIAL, backend).

Still on branch `customer-app-redesign`, still unmerged, and — unlike every
prior entry in this file — **still uncommitted**. This pass is
substantially larger than the 2026-08-19 redesign documented above: it
touches the membership card, profile, order confirmation, menu (search),
home (Favorites), rewards (a real tear-to-apply animation with a permanent
torn resting state), item detail (option-tile restyle), cart, and the app
shell/bottom nav, and adds three new screens (a splash screen, an
`ErrorPage`, a redesigned Settings screen) plus one explicitly-temporary
demo-only order-progress subsystem. Every remaining `SnackBar` in the app
was replaced by a new shared `AidaPopup` overlay component. Full
screen-by-screen detail: `docs/frontend/UI_REDESIGN_SPEC.md` §20.

Separately, two real backend migrations were drafted in the same working
tree: `TASK-REFERRAL-001` (a referral-bonus points ledger — the first real,
non-mock loyalty field in the schema) and `TASK-ACCT-001` (customer
self-service account deletion, an App/Play Store review requirement).
Neither has been applied to or verified against the live Aida Supabase
project — this task's environment had no access to it (see the note at the
top of this file). Full evidence, including exactly why each is PARTIAL:
`docs/context/BACKEND_MIGRATIONS_2026-08-29.md`.

Customer toolchain, run 2026-08-29 from `apps/customer`: `flutter analyze`
→ 1 pre-existing, unrelated issue (`axisAlignment` deprecation in
`order_checkout_sheet.dart`); `flutter test` → 55/55 passing, including
regenerated-and-reviewed golden baselines for the screens this pass
actually changed.

Cross-repository documentation sync: **PENDING** —
`Hermann-33/Aida_System-Dashboard` was not inspected or modified by any of
this session's work.
