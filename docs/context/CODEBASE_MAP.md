# Codebase Map

Updated: 2026-08-13

## Customer

- `lib/data/repository/supabase_member_repository.dart` — Supabase Auth, owner member/profile reads, and connectivity-only fallback to minimum cached member-code material.
- `lib/data/cache/offline_member_cache.dart` — per-user durable minimum member ID/code cache for offline QR; excludes authorization, verification, loyalty, and pricing state.

- `lib/data/repository/supabase_catalogue_repository.dart` — live catalogue snapshot + revision stream.
- `lib/domain/repository/catalogue_repository.dart` — customer read-only catalogue capability.
- `lib/domain/model/catalogue_snapshot.dart`, `menu_variant.dart`, `menu_item.dart` — backend catalogue contract.
- `lib/application/providers.dart` — one catalogue snapshot feeds featured/categories/popular/menu providers.
- `lib/features/menu/` — renders DB variants/add-ons/prices.
- `lib/domain/model/item_size.dart` — removed.
- `mock_member_repository.dart` — no runtime menu data.
- `test/support/test_catalogue_repository.dart` — explicit test-only representation of the 4-category/16-item seed; never a production fallback.
- `test/application/catalogue_provider_test.dart` — proves a revision event invalidates and re-fetches the catalogue snapshot.
- `test/data/offline_member_cache_test.dart` — proves minimum-only persistence, per-user isolation, cleanup, and malformed-entry rejection.
- `pubspec.yaml` / `pubspec.lock` — direct `shared_preferences: 2.5.5` plus pinned `supabase_flutter: 2.15.4` dependency graph.
- `supabase/migrations/20260812231500_create_shared_catalogue.sql` and `20260812235000_harden_catalogue_rls_policies.sql` — canonical catalogue schema.
- `supabase/tests/catalogue_integration.sql` — RLS/mutation/revision/audit regression.

## Dashboard

- `server/catalogueBff.ts` — public/admin catalogue handlers using publishable key or validated caller JWT.
- `api/v1/catalogue.ts` and `api/v1/admin/catalogue*` — deployment adapters.
- `src/features/catalogue/catalogueClient.ts` — browser contracts.
- `AdminMenuPage.tsx` / `AdminMenuEditorPage.tsx` — live DB management.
- `server/catalogueBff.test.ts` — BFF authorization contract tests.
- `src/features/pos/posCatalogue.ts` — maps the shared snapshot into POS category/product/variant/compatible-add-on presentation.
- `src/features/pos/CounterWorkspace.tsx` / `ModifierSheet.tsx` — shared catalogue browsing/configuration; cart/order/payment remains preview and untrusted.
- `AdminMenuFlows.test.tsx`, `posCatalogue.test.ts`, `CounterWorkspace.test.tsx` — Admin payload and POS shared-catalogue coverage.

POS order, total, checkout and payment preview remain separate from catalogue authority.
