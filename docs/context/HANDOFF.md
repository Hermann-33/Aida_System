# Current Handoff

Updated: 2026-08-29

## Task

Three tasks, all on branch `customer-app-redesign`, all **uncommitted**:

- `TASK-REDESIGN-001` — presentation-layer pass across most of the customer
  app. **Verdict: COMPLETE** for its own scope.
- `TASK-REFERRAL-001` — "Invite a friend" referral program.
  **Verdict: PARTIAL** — migration drafted, unapplied/unverified.
- `TASK-ACCT-001` — customer self-service account deletion.
  **Verdict: PARTIAL** — migration + client drafted, unapplied/unverified.

Detailed implementation/validation evidence:

- `docs/frontend/UI_REDESIGN_SPEC.md` §20
- `docs/context/BACKEND_MIGRATIONS_2026-08-29.md`

No PR, merge, or **commit** exists for any of the three — see "Next action"
below.

Previous task (`TASK-MENU-CUSTOMIZATION-001`, COMPLETE) remains recorded
below unchanged; its own evidence stays at
`docs/context/MENU_CUSTOMIZATION_2026-08-23.md`, matching branch
`codex/task-menu-customization-001-modifier-groups`.

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

This entry (`TASK-MENU-CUSTOMIZATION-001`) is ready for repository merge/release handling, but those are separate explicit actions. If merging, merge both matching task branches so the two frontends remain contract-compatible with the already-live backend.

After a customer merge, build a fresh APK from the merged customer default branch before distribution. The final Codex validation did not use a connected physical Android device.

**For the 2026-08-29 work (see below), the next actions are different and more pressing:**

1. **Commit.** All three tasks' changes are sitting uncommitted in the
   working tree — nothing described in this update exists in git history
   yet. This should happen before any further work risks losing it.
2. **Get real access to the live Aida Supabase project** (ref
   `eswovqxqzfevcdwwcmuh`) and apply/verify the two drafted migrations
   (`TASK-REFERRAL-001`, `TASK-ACCT-001`) — run `supabase db lint`, apply
   both, execute `supabase/tests/account_deletion_integration.sql`, write
   and run an equivalent regression for the referral migration, and check
   the security/performance advisors. Full detail:
   `docs/context/BACKEND_MIGRATIONS_2026-08-29.md`.
3. Only after (2) should either task's verdict move from PARTIAL toward
   COMPLETE.
4. Cross-repository documentation sync to
   `Hermann-33/Aida_System-Dashboard` remains PENDING for all three tasks —
   that repository was not inspected in this session.

## Deferred domains

Branch authority/capacity, terminal/sales-point lifecycle, shifts/cash reconciliation, payment/refunds, loyalty (partial exception: `TASK-REFERRAL-001`, drafted/unapplied), inventory, promotions/discounts, tax/accounting/reporting, delivery and hosted production operations remain separate tasks.

## 2026-08-19 addition — customer UI redesign documentation

Separate from the above: branch `customer-app-redesign` on
`Hermann-33/Aida_System` carried a presentation-layer redesign of Menu/Item
detail/Cart/Checkout sheet/Rewards, documented in
`docs/frontend/UI_REDESIGN_SPEC.md`. It did not change any backend
contract, data flow, or `UI_SCREEN_MAP.md` status at the time. It did
surface one open item: the checkout sheet could construct a
`requestedPickupAt` the backend's 15-minute slot-alignment validation
would reject, plus a client-only 8am–5pm scheduling window with no server
counterpart.

**Resolved 2026-08-24:** `customer-app-redesign` was merged with
`hermann/master` (carrying `TASK-MENU-CUSTOMIZATION-001`, described
above). The merge adopted `hermann/master`'s server-slot-driven scheduling
wheel, closing both flagged items — see `UI_REDESIGN_SPEC.md` §19 for the
full merge record, including how the two branches' differing Add-to-cart
navigation behavior was reconciled. Post-merge: `flutter analyze` 0
issues, `flutter test` 55/55 passing. Cross-repository documentation sync
to `Hermann-33/Aida_System-Dashboard` remains **PENDING** — out of scope
for both tasks.

## 2026-08-29 addition — three more tasks, all uncommitted

Still on `customer-app-redesign`, still unmerged, and unlike every entry
above, **none of this is committed to git**. See "Task" at the top of this
file for the three-task breakdown (`TASK-REDESIGN-001` COMPLETE,
`TASK-REFERRAL-001`/`TASK-ACCT-001` both PARTIAL) and "Next action" above
for what happens before any of it can move further.

One environment fact worth carrying forward for whoever picks this up:
this session had no working access to the live Aida Supabase project. The
only reachable Supabase MCP connection resolved to an unrelated project
("Cheater's Market", ref `gcqbayehikvbwvvseyoc`) in a different
organization — not a permissions issue on Aida's project, just a
differently-configured connection in this environment. Check your own
session's Supabase MCP target before assuming either drafted migration can
be applied directly from where you're sitting.

### What changed

**Customer, presentation-layer (`TASK-REDESIGN-001`):** membership card,
profile, order-confirmation, menu (search added), home (Favorites chip),
rewards (tear-to-apply animation), item detail (option-tile restyle), cart,
and the app shell/bottom nav were all materially changed; a splash screen,
an `ErrorPage`, a redesigned Settings screen, and an explicitly-temporary
demo order-progress subsystem were added; every `SnackBar` in the app was
replaced by a new `AidaPopup` overlay component. Full detail:
`docs/frontend/UI_REDESIGN_SPEC.md` §20.

**Backend (`TASK-REFERRAL-001` + `TASK-ACCT-001`):** two migrations drafted
in `supabase/migrations/` — a referral-bonus points ledger and a
customer self-service account-deletion RPC. Neither is applied to live
Supabase. Full detail: `docs/context/BACKEND_MIGRATIONS_2026-08-29.md`.

### Executable validation

Customer, run 2026-08-29 from `apps/customer`:

- `flutter analyze` → 1 pre-existing, unrelated issue only;
- `flutter test` → 55 passed / 0 failed, including regenerated-and-reviewed
  golden baselines for every screen this pass actually changed.

No Dashboard validation — that repository was not touched.

### Cross-repository documentation sync

**PENDING** for all three tasks — `Hermann-33/Aida_System-Dashboard` was
not inspected, cloned, or modified this session.
