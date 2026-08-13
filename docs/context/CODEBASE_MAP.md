# Codebase Map

Updated: 2026-08-14

## Customer repository — `Hermann-33/Aida_System`

### Existing identity/catalogue runtime

- `apps/customer/android/app/src/main/AndroidManifest.xml` — production Android permissions, including required Supabase network access.
- `apps/customer/android/settings.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties` and `android/gradle.properties` — committed Android release toolchain compatibility settings (AGP 8.9.1, Gradle 8.11.1 and Flutter legacy DSL opt-outs).
- `apps/customer/test/android_release_manifest_test.dart` and `test/data/supabase_member_repository_test.dart` — release-network and Auth error-mapping regressions.

- `apps/customer/lib/data/repository/supabase_member_repository.dart` — Supabase Auth plus owner member/profile reads and minimum cached member-code fallback.
- `apps/customer/lib/data/cache/offline_member_cache.dart` — per-user durable member ID/code cache only; excludes roles, verification, loyalty and pricing authority.
- `apps/customer/lib/data/repository/supabase_catalogue_repository.dart` — live `get_catalogue()` snapshot and `catalogue_revision` stream.
- `apps/customer/lib/domain/repository/catalogue_repository.dart` — customer read-only catalogue capability.
- `apps/customer/lib/domain/model/catalogue_snapshot.dart`, `menu_variant.dart`, `menu_item.dart` — shared catalogue model.
- `apps/customer/lib/application/providers.dart` — Auth/member/catalogue/cart/provider composition.
- `apps/customer/lib/features/menu/` — DB-driven menu/item customization UI.

### Integrated customer order frontend

- `apps/customer/lib/domain/model/order.dart` — typed schedule policy, trusted selection payload, quote lines and persisted order snapshots/statuses.
- `apps/customer/lib/domain/repository/order_repository.dart` and `data/repository/supabase_order_repository.dart` — policy/quote/place/history/detail RPC boundary plus owner-scoped `orders` invalidation stream.
- `apps/customer/lib/application/order_checkout.dart` — timezone-aware slot derivation, UUID generation and retry-stable placement session.
- `apps/customer/lib/application/providers.dart` — Realtime-invalidated authoritative history/detail providers.
- `apps/customer/lib/features/cart/cart_screen.dart` and `order_checkout_sheet.dart` — local selection estimate, server quote, ASAP/scheduled choice, Pay-at-counter placement and clear-on-success behavior.
- `apps/customer/lib/features/cart/order_confirmation_screen.dart` — persisted status timeline with no client progression timer.
- `apps/customer/lib/features/history/order_history_screen.dart`, `order_detail_screen.dart` and `widgets/order_status_pill.dart` — owner history/detail from immutable backend snapshots.
- order-focused tests cover mapping, payload, scheduling, idempotency, Realtime, success-clear and failure-retain behavior.
- existing cart/menu widgets remain useful selection/presentation state but cannot be commercial authority.

### Canonical Supabase ownership

- `supabase/migrations/20260812182212_create_authoritative_orders_and_scheduling.sql` — authoritative order/schedule schema, RPCs, RLS, Realtime publication.
- `supabase/migrations/20260812183029_index_order_foreign_keys.sql` — forward FK index hardening.
- `supabase/tests/order_integration.sql` — canonical transactional pricing/schedule/idempotency/authorization/status regression.
- canonical Auth and order regressions scope assertions to their own synthetic identities and derive expected totals from the live catalogue, so retained approved demo state and legitimate Admin price changes cannot make the tests brittle.
- earlier identity/catalogue migrations remain canonical in this repository only.

### Frontend integration references

- `docs/decisions/ADR-0010-authoritative-ordering-and-scheduled-fulfilment.md`
- `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md`

## Dashboard repository — `Hermann-33/Aida_System-Dashboard`

### Existing trusted server boundaries

- `server/employeeBff.ts` — employee login/session/logout/Admin Members boundary with HttpOnly cookies and caller-JWT semantics.
- `server/catalogueBff.ts` — public/admin catalogue BFF.
- `server/viteBffPlugin.ts` — mounts BFF routes in Vite dev/preview.
- `api/v1/auth/*`, `api/v1/admin/members.ts`, catalogue adapters — production/Vercel route adapters.

### New order backend/BFF

- `server/orderBff.ts` — public schedule-policy plus authenticated employee order queue/detail/quote/place/status/admin-policy handlers.
- `server/orderBff.test.ts` — origin/session/caller-JWT/conflict/admin-policy contract coverage.
- `api/v1/orders/policy.ts` — public schedule policy.
- `api/v1/orders.ts` — employee order queue.
- `api/v1/orders/detail.ts` — employee order detail.
- `api/v1/orders/quote.ts` — authoritative POS quote.
- `api/v1/orders/place.ts` — idempotent POS placement.
- `api/v1/orders/status.ts` — versioned staff status transition.
- `api/v1/admin/orders/policy.ts` — admin-only schedule-policy mutation.

### Existing dashboard frontend that Codex must integrate

- `src/features/catalogue/catalogueClient.ts` and `src/features/pos/posCatalogue.ts` — existing shared catalogue browser contracts.
- `src/features/pos/CounterWorkspace.tsx` / `ModifierSheet.tsx` — POS selection/customization UI; preserve its design and selection ergonomics, but replace preview total/order persistence authority with the order BFF.
- existing Admin/POS navigation, cards, dialogs, badges, table/queue patterns and theme tokens are the visual design source for the live order board.
- existing preview cart/tender/order objects may remain only as temporary UI selection state where needed; they must not be persisted or displayed as trusted server totals/order status.

### Dashboard refresh model

The employee access token remains HttpOnly by design. React therefore must not receive/expose a Supabase staff JWT merely to subscribe directly to Realtime. For the demo order board, use TanStack Query (or the existing query layer) against `/api/v1/orders` with a short safe refetch interval and immediate invalidation after local place/status mutations. Customer Flutter owns the direct owner-scoped `orders` Realtime subscription.

## Shared frontend design constraint

TASK-DEMO-ORDER-001 frontend work is an **integration, not a redesign**. Codex must inspect and reuse each application's existing theme tokens, typography, spacing, radii, shadows, cards, sheets/dialogs, buttons, status pills, responsive patterns and existing golden/UI tests before adding scheduled-pickup or order-status surfaces. Do not introduce a parallel design system or arbitrary styling.
