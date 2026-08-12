# Codebase Map

Updated: 2026-08-12

## Customer

- `lib/data/repository/supabase_catalogue_repository.dart` — live catalogue snapshot + revision stream.
- `lib/domain/repository/catalogue_repository.dart` — customer read-only catalogue capability.
- `lib/domain/model/catalogue_snapshot.dart`, `menu_variant.dart`, `menu_item.dart` — backend catalogue contract.
- `lib/application/providers.dart` — one catalogue snapshot feeds featured/categories/popular/menu providers.
- `lib/features/menu/` — renders DB variants/add-ons/prices.
- `lib/domain/model/item_size.dart` — removed.
- `mock_member_repository.dart` — no runtime menu data.
- `test/support/test_catalogue_repository.dart` — test-only fixture; never production fallback.
- `supabase/migrations/20260812231500_create_shared_catalogue.sql` and `20260812235000_harden_catalogue_rls_policies.sql` — canonical catalogue schema.
- `supabase/tests/catalogue_integration.sql` — RLS/mutation/revision/audit regression.

## Dashboard

- `server/catalogueBff.ts` — public/admin catalogue handlers using publishable key or validated caller JWT.
- `api/v1/catalogue.ts` and `api/v1/admin/catalogue*` — deployment adapters.
- `src/features/catalogue/catalogueClient.ts` — browser contracts.
- `AdminMenuPage.tsx` / `AdminMenuEditorPage.tsx` — live DB management.
- `server/catalogueBff.test.ts` — BFF authorization contract tests.

POS checkout preview remains separate from Admin catalogue authority.
