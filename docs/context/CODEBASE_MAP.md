# Codebase Map

Updated: 2026-08-23

## Customer repository — `Hermann-33/Aida_System`

### Identity/member runtime

- `apps/customer/lib/data/repository/supabase_member_repository.dart` — Supabase Auth + owner-scoped member/profile reads.
- `apps/customer/lib/data/cache/offline_member_cache.dart` — minimum per-user member ID/code cache; no role/pricing/loyalty authority.
- `apps/customer/lib/application/providers.dart` — Auth/member/catalogue/cart/order composition.
- `apps/customer/lib/features/auth/login_screen.dart` — customer Supabase sign-in/sign-up UI.

### Shared catalogue / modifier runtime

- `apps/customer/lib/data/repository/supabase_catalogue_repository.dart` — `get_catalogue()` decoding, including `isDrink`, variants, compatible add-ons and customization groups; `catalogue_revision` stream.
- `apps/customer/lib/domain/model/catalogue_snapshot.dart` — snapshot envelope.
- `apps/customer/lib/domain/model/menu_item.dart` — product/add-on identity, drink flag, compatible add-ons and customization groups.
- `apps/customer/lib/domain/model/menu_variant.dart` — size/variant data.
- `apps/customer/lib/domain/model/menu_customization.dart` — reusable customization group/option models and available/default helpers.
- `apps/customer/lib/features/menu/menu_screen.dart` — customer browse; filters non-product add-ons/add-on-only category from normal browsing.
- `apps/customer/lib/features/menu/item_detail_screen.dart` — Size + Temperature + Sweetness + compatible add-ons + quantity/note; adds configured line and returns to Menu.
- `apps/customer/test/data/supabase_catalogue_decoder_test.dart` — focused catalogue payload decoding regression.
- `apps/customer/test/widgets/item_detail_customization_test.dart` — option/add-on UI, disabled state, long-label/touch-target/viewport regressions.
- `apps/customer/test/widgets/menu_addon_visibility_test.dart` — protects add-on browse filtering.

### Customer cart / order runtime

- `apps/customer/lib/domain/model/cart.dart` — cart line identity/equivalence and estimate calculation include option/add-on selections/deltas.
- `apps/customer/lib/features/cart/cart_screen.dart` — configured-line summary and estimate-only subtotal.
- `apps/customer/lib/domain/model/order.dart` — trusted order selection/quote/snapshot models; `optionValueIds`, option snapshots and numeric order-number tolerant decode.
- `apps/customer/lib/data/repository/supabase_order_repository.dart` — policy/quote/place/history/detail RPC boundary + owner-scoped order invalidation.
- `apps/customer/lib/application/order_checkout.dart` — policy-derived scheduling, UUID generation, retry-stable placement session.
- `apps/customer/lib/features/cart/order_checkout_sheet.dart` — `Now | Schedule`, policy-derived tactile wheel, authoritative quote and Pay-at-counter placement.
- `apps/customer/test/domain/cart_customization_test.dart` — distinct option/add-on line identity and estimate regressions.
- `apps/customer/test/domain/order_test.dart` — option-ID request serialization/commercial-field trust boundary.
- `apps/customer/test/widgets/cart_flow_test.dart` — configured item -> cart -> quote/place and navigation regressions.
- `apps/customer/test/support/test_catalogue_repository.dart`, `test/support/test_order_repository.dart` — test-only adapters, never runtime authority.

### Customer design system

- `apps/customer/lib/core/theme/aida_colors.dart` — AIDA cream/rose/espresso/gold semantic palette.
- `apps/customer/lib/core/theme/aida_type.dart` — Playfair + Plus Jakarta Sans typography helpers.
- `apps/customer/lib/core/widgets/neumorphic_control.dart` — shared tactile control language.
- `apps/customer/lib/core/widgets/product_image.dart` — live catalogue image primary + safe fallback presentation.
- `docs/frontend/UI_REDESIGN_SPEC.md` — accepted customer visual/component behavior, extended by menu customization closeout.

### Canonical Supabase ownership

Relevant canonical migration files include:

- `supabase/migrations/20260812231500_create_shared_catalogue.sql`;
- `supabase/migrations/20260812235000_harden_catalogue_rls_policies.sql`;
- `supabase/migrations/20260812182212_create_authoritative_orders_and_scheduling.sql`;
- `supabase/migrations/20260812183029_index_order_foreign_keys.sql`;
- `supabase/migrations/20260820151421_add_scheduled_order_preparation_window.sql`;
- `supabase/migrations/20260820214041_refresh_catalogue_product_images.sql`;
- `supabase/migrations/20260820221139_replace_americano_catalogue_image.sql`;
- `supabase/migrations/20260822135421_add_drink_customization_catalogue.sql`;
- `supabase/migrations/20260822135602_integrate_drink_customizations_with_orders.sql`;
- `supabase/migrations/20260822141814_harden_drink_customization_indexes_and_rls.sql`;
- `supabase/migrations/20260822143542_grant_public_drink_customization_reads.sql`.

Supabase's applied migration-history timestamps for some older migrations differ from these historical canonical filenames; do not rename already-accepted migration files merely to make the timestamp labels match.

Canonical backend regressions live under `supabase/tests/`. TASK-MENU-CUSTOMIZATION-001 adds `menu_customization_integration.sql` as a transactionally safe contract regression.

## Dashboard repository — `Hermann-33/Aida_System-Dashboard`

### Employee/Admin server boundary

- `server/employeeBff.ts` — employee login/session/logout with HttpOnly cookies and caller-JWT semantics.
- `server/catalogueBff.ts` — public/Admin catalogue BFF.
- `server/orderBff.ts` — policy/quote/place/queue/detail/status/admin-policy BFF.
- `api/v1/**` — production route adapters.
- `src/auth/employeeSession.ts`, `src/auth/ProtectedRoute.tsx` — browser session coordination only; not backend authorization authority.

### Shared catalogue / Admin frontend

- `src/features/catalogue/catalogueClient.ts` — typed catalogue snapshot including `isDrink` and `customizationGroups`; safe empty-group fallback for older responses.
- `src/features/catalogue/catalogueClient.test.ts` — customization parsing regressions.
- `src/features/admin/AdminMenuPage.tsx` — catalogue listing and new item creation with Drink toggle.
- `src/features/admin/AdminMenuEditorPage.tsx` — variants, drink option labels/deltas/availability/defaults and compatible add-ons.
- `src/features/admin/AdminMenuFlows.test.tsx` — Admin preview/read-only, new-drink and option-save validation.
- `src/features/admin/admin.css` — token-based responsive Menu editor rows/cards; no separate design system.

### POS modifier / order frontend

- `src/features/pos/posCatalogue.ts` — shared catalogue -> POS modifier groups: variant required, Temperature/Sweetness required single-choice, compatible add-ons optional multi-select.
- `src/features/pos/ModifierSheet.tsx` — modifier selection UI with native fieldset/legend semantics, unavailable state and existing POS density.
- `src/features/pos/CounterWorkspace.tsx` — product selection/cart workspace.
- `src/features/pos/posCatalogue.test.ts`, `ModifierSheet.test.tsx`, `CounterWorkspace.test.tsx` — modifier mapping, selection and independent-line regressions.
- `src/features/orders/orderClient.ts` — selection-only order intent mapping including `optionValueIds`, strict order/preparation parsing and legal status table.
- `src/features/orders/OrderCheckoutPanel.tsx` — authoritative quote/place and Now/Schedule presentation.
- `src/features/orders/OrderBoard.tsx` / workload helpers — Active/Scheduled/Ready/History projection from trusted backend snapshots.
- `src/features/orders/*.test.ts*` — quote/order/status/customization regressions.

### Dashboard design system

- `src/styles/tokens.css` — canonical ivory/surface/espresso/burgundy/blush/gold/taupe/semantic tokens, spacing/radii, focus and reduced-motion behavior.
- existing Admin/POS button/card/form classes remain the styling authority for modifier-group UI.

## Shared backend model introduced by menu customization

```text
catalogue_items.is_drink
catalogue_option_groups
catalogue_option_values
catalogue_item_option_values
order_lines.option_total_sen
order_line_options
```

The deployed quote contract is `pricingVersion=2`; clients send option value IDs, not trusted commercial outcomes.

## Current closeout state

TASK-MENU-CUSTOMIZATION-001 is COMPLETE on matching task branches after:

- Customer final validation commit `404662aec382364c8e70fcee8d66b38d4b303f0a` and 55/55 Flutter tests;
- Dashboard final validation commit `af0fcd2babfa02073f882ec63ddbec102e591672`, Vitest 129/129 and Playwright 10/10;
- live Supabase migration/grant/RLS/advisor verification;
- mirrored contract/context/security documentation reconciliation.

Detailed evidence: `docs/context/MENU_CUSTOMIZATION_2026-08-23.md`.

No PR/merge is included in this closeout. Payment, loyalty, inventory, reporting, branch/capacity, terminal/shift and hosted-production domains remain deferred.

## 2026-09-09 customer redesign / preserved future work

New/updated customer areas:

- `apps/customer/lib/core/widgets/aida_popup.dart` — shared transient customer feedback overlay.
- `apps/customer/lib/core/config/feature_flags.dart` — compile-time gates for preserved account-deletion/referral client surfaces.
- `apps/customer/lib/features/splash/splash_screen.dart` — branded startup presentation that hands off to the existing Auth gate.
- `apps/customer/lib/features/profile/settings_screen.dart` — redesigned Settings surface; account deletion remains draft-gated.
- `apps/customer/lib/features/order_progress/liquid_stage_tracker.dart` — presentation for real persisted order status.
- `supabase/drafts/` — preserved, non-applied privacy/referral backend prototypes.
- `docs/frontend/UI_REDESIGN_AUDIT_2026-09-09.md` — final audit/merge boundaries.
- `docs/frontend/IOS_TOOLCHAIN_DRAFT_2026-08-29.md` — retained iOS migration/toolchain observations.

Demo-only order-progress provider/capsule/staff-test tooling is intentionally absent from the final tree.



## TASK-OPS-001 branch authority additions

### Canonical Supabase migrations

- `supabase/migrations/20260910014434_create_branch_location_authority.sql` — trusted branch directory, employee assignments, immutable order branch identity, branch-scoped order authorization and Admin/Owner branch RPCs.
- `supabase/migrations/20260910014457_index_employee_branch_assignment_actor.sql` — FK-supporting actor index identified by the Supabase performance advisor.
- `supabase/tests/branch_authority_integration.sql` — transactional branch/RLS/role/order-scope regression; committed but not executed in this session because the connected inspection role is read-only.

### Dashboard employee session

- `server/employeeBff.ts` on `codex/task-ops-001-branch-authority` reads `employee_branch_assignments` with the authenticated employee caller JWT and returns real `assignedBranchIds`.
- ordinary staff with no trusted assignment fail closed with `EMPLOYEE_BRANCH_REQUIRED`;
- Admin/Owner preserve global operational authority for this tranche;
- `server/employeeBff.test.ts` covers branch-claim mapping and missing-assignment failure.

The existing `AdminLocationsPage.tsx` and `AdminEmployeesPage.tsx` remain preview/session-local presentation until their dedicated BFF/API wiring task. Their fixture branch data is not backend authority.
