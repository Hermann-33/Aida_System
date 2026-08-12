# Current Handoff

Updated: 2026-08-13

## Current task

`TASK-AUTH-003 — deployed/device customer Auth and catalogue cross-client E2E`.

**Verdict:** PARTIAL under ADR-0004.

Customer branch: `codex/task-auth-003-deployed-e2e`, stacked on `codex/task-menu-001-shared-catalogue` / draft PR #7, which remains stacked on #6 and #5.

## Completed validation and fixes

- Ran `flutter pub get`; committed source had a stale lockfile that did not resolve the added `supabase_flutter` dependency, so the lockfile is now regenerated from the pinned `2.15.4` constraint.
- `flutter analyze` passes with no issues.
- `flutter test` passes all 32 tests after deliberate review of the four prior golden failures.
- Added the ADR-0003-required durable, user-scoped minimum offline member-code cache and tests. Logout/user switch removes the old user's entry; roles, verification, loyalty and pricing are not cached.
- Added a focused provider regression proving a catalogue revision event triggers a second authoritative snapshot fetch.
- Repaired the explicit test-only catalogue fixture so menu/golden tests represent all 4 categories and 16 seeded items rather than one product and one add-on.
- Proved `item_size.dart` is absent and production Dart has no `ItemSize` reference, migrated menu fixture, seeded catalogue price literal, or static S/M/L price-delta definition.
- Verified source wiring from Supabase `get_catalogue()` through `SupabaseCatalogueRepository` into categories/items/variants/compatible add-ons and UI providers.
- Ran the canonical Auth/member and catalogue SQL regressions verbatim against Supabase; both passed inside rollback transactions.
- Independently verified cleanup: no synthetic users, regression category/item, or regression audit row remains.
- Verified live anonymous catalogue shape: 4 categories, 16 items, 27 variants, 27 compatible add-on links, required Flutter contract fields present.
- Verified revision 1 and exactly one `catalogue_revision` entry in `supabase_realtime`.
- Security advisor: 0 lints. Performance advisor: six unused-index INFO notices only.
- Reconciled all eight current live migration statements to the canonical files. Names and SQL semantics match; only applied timestamp prefixes and non-semantic comments/formatting differ, so no schema mutation or manufactured migration is needed.
- Reconciled the customer mirror to dashboard commit `238e0ff211fe550f42ec4d4423724e3642282295`: lint/typecheck/85 tests/build pass, Playwright 6/6 passes, Admin and POS browse the shared catalogue, preview catalogue fallbacks are absent at runtime, BFF contract/security checks pass, and the dashboard security advisor has 0 lints.

## Remaining blockers

- Flutter 3.44.7 release web starts successfully against live public Supabase configuration and renders the real sign-in UI. Chrome, Edge, and Windows desktop are available; there is no Android emulator/physical device.
- Live Supabase has 0 Auth users, 0 profiles, 0 members, and no customer/admin/owner identity. No approved credentials or mailbox were supplied, so Auth lifecycle and password-reset completion remain blocked.
- Neither GitHub repository has a deployment and the dashboard has no AUTH-003 branch/evidence or deployed URL. Cross-client Admin mutation -> revision -> Flutter Realtime -> UI -> restore therefore remains blocked.
- Baseline evidence: revision 1; SKU `CF-SCL`; item `4287b72b-5c01-4c98-8f7b-2e4babfb1cd4`; base price 1290 sen; available and published. No mutation was performed.
- Anonymous catalogue/admin RPC probes failed closed with HTTP 404. No service-role/secret marker exists in Flutter source/config or its release web build. Customer-session negative checks require the missing approved customer identity.
- Dashboard preview checkout, totals, orders and payments remain untrusted and must not be treated as authoritative because catalogue browsing is shared.

## Git and PR state

- No default branch was changed.
- No migration, deployment, real-user creation, or RLS change was performed during this closeout.
- Customer branch: `codex/task-auth-003-deployed-e2e`, stacked on #7. Existing stack remains #5 `AUTH-001` -> #6 `AUTH-002` -> #7 `TASK-MENU-001` -> TASK-AUTH-003.

## Exact next task

Resume `TASK-AUTH-003`: provision/approve a real customer mailbox identity and trusted admin/owner identity, deploy the dashboard AUTH-003 stack, provide the deployed URL/credentials securely, then run the required lifecycle and cross-client mutation/revision/UI/restore observation without restarting Flutter.

Do not begin `TASK-ORDER-001` release work until these validation debts are explicitly accepted or closed.
