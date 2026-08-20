# Codebase Map

Updated: 2026-08-20

## Customer repository — `Hermann-33/Aida_System`

### Android/runtime configuration

- `apps/customer/android/app/src/main/AndroidManifest.xml` — production Android permissions, including required Internet access.
- `apps/customer/android/settings.gradle.kts` — Android Gradle Plugin configuration; closeout uses AGP 8.9.1.
- `apps/customer/android/gradle/wrapper/gradle-wrapper.properties` — Gradle wrapper; closeout uses Gradle 8.11.1.
- `apps/customer/android/gradle.properties` — Flutter/Gradle compatibility properties.
- `apps/customer/test/android_release_manifest_test.dart` — regression protecting production Internet permission.
- `.github/workflows/customer-release-audit.yml` — clean Flutter 3.44.9 post-redesign analyze/test/release-APK workflow used by TASK-UI-REDESIGN-003.

### Identity/member runtime

- `apps/customer/lib/data/repository/supabase_member_repository.dart` — Supabase Auth plus owner-scoped member/profile reads and Auth error mapping.
- `apps/customer/lib/data/cache/offline_member_cache.dart` — per-user durable minimum member ID/code cache; excludes roles, verification, loyalty and pricing authority.
- `apps/customer/lib/application/providers.dart` — Auth/member/catalogue/cart/order provider composition.
- `apps/customer/lib/features/auth/login_screen.dart` — Supabase-backed sign-in/sign-up UI.
- `apps/customer/lib/features/card/membership_card_screen.dart` — owner/offline-backed member QR; consumes shared bundled `AidaLogo` presentation.
- `apps/customer/lib/core/theme/aida_logo.dart` and `assets/images/aida_logo.jpg` — shared offline-safe logo presentation; not identity authority.
- `apps/customer/test/data/supabase_member_repository_test.dart` and `test/data/offline_member_cache_test.dart` — Auth/cache regressions.

### Shared catalogue runtime

- `apps/customer/lib/data/repository/supabase_catalogue_repository.dart` — `get_catalogue()` snapshot plus `catalogue_revision` stream.
- `apps/customer/lib/domain/repository/catalogue_repository.dart` — customer read-only catalogue capability.
- `apps/customer/lib/domain/model/catalogue_snapshot.dart`, `menu_variant.dart`, `menu_item.dart` — shared catalogue models.
- `apps/customer/lib/features/menu/menu_screen.dart` — redesigned vertical-rail/single-column Menu over the same DB-backed providers.
- `apps/customer/lib/features/menu/widgets/menu_category_rail.dart` — redesigned category/favorites selector with stable automation keys.
- `apps/customer/lib/features/menu/widgets/menu_list_item.dart` — redesigned list row; live `imageUrl` first, bundled category art only as fallback.
- `apps/customer/lib/features/menu/item_detail_screen.dart` — DB-driven customization plus consolidated local-cart CTA.
- `apps/customer/test/support/test_catalogue_repository.dart` — explicit test-only catalogue fixture, not a runtime fallback.

### Customer redesign presentation

- `apps/customer/lib/core/widgets/neumorphic_control.dart` — shared soft-UI control; optional accent gradient used for transient add-to-cart success.
- `apps/customer/lib/features/cart/widgets/floating_cart_bar.dart` — animated local-cart entry point with item thumbnails and local estimate.
- `apps/customer/lib/features/cart/cart_screen.dart` — flat cart rows, swipe removal, estimate-only subtotal and authoritative checkout entry.
- `apps/customer/lib/features/rewards/rewards_screen.dart` — redesigned member balance-card presentation; real member display plus still-mock loyalty providers.
- `docs/frontend/UI_REDESIGN_SPEC.md` — visual/component/screen redesign specification.
- `docs/frontend/UI_REDESIGN_AUDIT_2026-08-20.md` — post-merge backend-impact and verification audit.
- `docs/screenshots/2026-08-19-*-redesign.png` — repository-local redesign evidence; not governance authority.

### Authoritative customer order frontend

- `apps/customer/lib/domain/model/order.dart` — schedule policy, trusted selection payload, quote lines and persisted order snapshots/statuses.
- `apps/customer/lib/domain/repository/order_repository.dart` — customer order repository contract.
- `apps/customer/lib/data/repository/supabase_order_repository.dart` — policy/quote/place/history/detail RPC boundary plus owner-scoped `orders` invalidation stream.
- `apps/customer/lib/application/order_checkout.dart` — timezone-aware slot derivation, UUID generation and retry-stable placement session.
- `apps/customer/lib/features/cart/order_checkout_sheet.dart` — redesigned wheel presentation over `derivePickupSlots(OrderingPolicy)`, authoritative quote and Pay-at-counter placement.
- `apps/customer/lib/features/cart/order_confirmation_screen.dart` — persisted status timeline with no client progression timer.
- `apps/customer/lib/features/history/order_history_screen.dart`, `order_detail_screen.dart`, `widgets/order_status_pill.dart` — owner history/detail from immutable backend snapshots.
- `apps/customer/test/application/order_checkout_test.dart` — slot derivation and placement-idempotency regression.
- `apps/customer/test/widgets/cart_flow_test.dart` — item configuration/cart/quote/place/failure-retain plus post-redesign policy-derived Schedule regression.
- `apps/customer/test/support/test_order_repository.dart` — test-only order adapter, including quote-request recording for UI contract assertions.

### Canonical Supabase ownership

- `supabase/migrations/20260812191500_integrate_customer_auth_member_directory.sql` — customer Auth/member integration.
- `supabase/migrations/20260812192500_fix_signup_member_code_generation.sql` — server member-code generation fix.
- `supabase/migrations/20260812195500_make_admin_member_directory_security_invoker.sql` — Admin member directory execution model.
- `supabase/migrations/20260812231500_create_shared_catalogue.sql` and `20260812235000_harden_catalogue_rls_policies.sql` — shared catalogue authority and RLS hardening.
- `supabase/migrations/20260812182212_create_authoritative_orders_and_scheduling.sql` — authoritative order/schedule schema, RPCs, RLS and Realtime publication.
- `supabase/migrations/20260812183029_index_order_foreign_keys.sql` — order FK index hardening.
- `supabase/tests/auth_membership_integration.sql`, `catalogue_integration.sql`, `order_integration.sql` — canonical transactional backend regressions.

## Dashboard repository — `Hermann-33/Aida_System-Dashboard`

### Trusted employee/Admin server boundary

- `server/employeeBff.ts` — employee login/session/logout/Admin Members boundary with HttpOnly cookies and caller-JWT semantics.
- `server/employeeBff.test.ts` — employee/session authorization coverage.
- `server/catalogueBff.ts` and `server/catalogueBff.test.ts` — public/Admin catalogue BFF and tests.
- `server/viteBffPlugin.ts` — mounts BFF routes in Vite dev/preview.
- `api/v1/auth/*`, `api/v1/admin/members.ts`, `api/v1/catalogue.ts`, `api/v1/admin/catalogue*` — production/Vercel route adapters.
- `src/auth/ProtectedRoute.tsx`, `src/auth/employeeSession.ts` — route/session client coordination; not backend authorization authority.
- `src/pages/AdminLoginPage.tsx` — real Admin login surface.

### Admin/member/catalogue frontend

- `src/features/admin/memberDirectory.ts` — protected member-directory adapter.
- `src/features/admin/AdminMembersLoyaltyReportPage.tsx` — live Members surface with preview-safe behavior.
- `src/features/catalogue/catalogueClient.ts` — public/Admin catalogue client.
- `src/features/admin/AdminMenuPage.tsx` and `AdminMenuEditorPage.tsx` — live shared catalogue management.
- `src/features/pos/posCatalogue.ts` — shared catalogue mapping for POS browsing/customization.

### Authoritative order BFF

- `server/orderBff.ts` — schedule policy, employee queue/detail/quote/place/status/admin-policy handlers.
- `server/orderBff.test.ts` — origin/session/caller-JWT/conflict/admin-policy coverage.
- `api/v1/orders/policy.ts` — schedule policy.
- `api/v1/orders.ts` — employee order queue.
- `api/v1/orders/detail.ts` — order detail.
- `api/v1/orders/quote.ts` — authoritative POS quote.
- `api/v1/orders/place.ts` — idempotent POS placement.
- `api/v1/orders/status.ts` — versioned staff status transition.
- `api/v1/admin/orders/policy.ts` — Admin schedule-policy mutation.

### Authoritative Dashboard order frontend

- `src/features/orders/orderClient.ts` — typed same-origin policy/quote/place/queue/detail/status adapter, strict preparation-field parsing, selection-only payload mapping, schedule-slot generation, polling constants and legal transition table.
- `src/features/orders/orderWorkloads.ts` — pure server-classification-driven Active/Scheduled/Ready/History routing and operational sorting; it does not derive trusted state from the workstation clock.
- `src/features/orders/OrderCheckoutPanel.tsx` — authoritative quote review, ASAP/scheduled selection, stable idempotent placement retry, Pay-at-counter wording and persisted receipt.
- `src/features/orders/OrderBoard.tsx` — live polled operational workload cards/tabs, explicit due/overdue timing, grouped future scheduling, and versioned legal status transitions with conflict refetch.
- `src/features/pos/CounterWorkspace.tsx` and `ModifierSheet.tsx` — shared-catalogue selection UI and local cart estimate; no preview transaction authority in the active placement/Orders rail.
- `src/features/orders/*.test.ts*`, `src/features/pos/CounterWorkspace.test.tsx` — focused authoritative ordering regressions.
- `e2e/preview-closure.spec.ts` — browser coverage including preview/live session and order-flow regressions.

### Live POS entry versus preview operational context

- `src/pages/EmployeeWelcomePage.tsx` — live employee sign-in is independent of terminal enrolment; preview retains the labelled enrolment simulator.
- `src/pages/PosShellPage.tsx` — live authenticated staff enters the single-café Sale/Orders workspace without terminal/shift API calls; preview retains local terminal/shift lifecycle.
- `src/features/pos/CounterWorkspace.tsx` — live rail exposes Sale, Orders and Help; preview-only Member, Shift and Terminal rails require preview operational context.
- `src/components/PosContextBar.tsx` — distinguishes live global order scope from preview terminal/shift context without fabricating IDs.

### Dashboard refresh/security model

The employee access token remains HttpOnly. React does not receive/expose a Supabase staff JWT for Realtime. The order board uses TanStack Query against `/api/v1/orders` at ~2.5-second intervals with immediate invalidation after place/status mutations. Customer Flutter owns the direct owner-scoped `orders` Realtime subscription.

## Shared documentation/contract references

- `docs/decisions/ADR-0008-dashboard-same-origin-bff.md`
- `docs/decisions/ADR-0009-shared-catalogue-and-revision-signal.md`
- `docs/decisions/ADR-0010-authoritative-ordering-and-scheduled-fulfilment.md`
- `docs/contracts/SHARED_BACKEND_CONTRACT.md`
- `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md`
- `docs/frontend/UI_REDESIGN_AUDIT_2026-08-20.md`
- `docs/context/CLOSEOUT_EVIDENCE_2026-08-17.md`

## Current closeout state

TASK-CLOSEOUT-001 implementation and applicable cross-client validation are complete. The retained live proof is order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`), which progressed through confirmed/preparing/ready/completed with customer-authorized reads after each Dashboard transition.

TASK-UI-REDESIGN-003 audits the merged customer redesign against those backend boundaries and adds fresh release verification without changing backend authority.

Deferred payment, loyalty, inventory, reporting, branch-capacity and hosted-production domains remain outside this codebase map's completed tranche.
