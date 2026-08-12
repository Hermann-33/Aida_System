# Active Context

**As of:** 2026-08-13
**Current implementation task:** customer-side validation closeout for `AUTH-001`, `AUTH-002`, and `TASK-MENU-001`
**Current task verdict:** PARTIAL

## Current product reality

The stacked customer source now contains real Supabase Auth/member and shared-catalogue adapters:

- Supabase Auth restores and publishes the customer session; sign-in, sign-up, reset request, sign-out, and owner-scoped member reads use the live client.
- loyalty, rewards, offers, promotions, and profile writes remain preview or unimplemented and are not made authoritative by this validation.
- the minimum offline QR material required by ADR-0003 is now durably cached per Supabase user: only the server member ID/code are retained, stale user entries are removed on logout/user switch, and roles, verification, loyalty, and pricing are never cached as authority.
- Flutter reads `get_catalogue()` and maps categories, items, variants, compatible add-on IDs, prices, publication/availability flags, and merchandising flags from the live response.
- `catalogue_revision` is the only catalogue Realtime publication. Its stream invalidates and re-fetches the full RLS-filtered catalogue snapshot.
- production Dart contains no `item_size.dart`, `ItemSize`, migrated 16-item catalogue fixture, or hardcoded Small/Medium/Large price deltas.
- the full 16-item catalogue exists only in the canonical migration and an explicit test-only repository override.

## Validation completed

- `flutter pub get`: passed and repaired the previously stale lockfile for `supabase_flutter: 2.15.4`.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed 32/32. All four prior golden failures were inspected before the reviewed baselines were updated; the fresh membership QR renders correctly.
- focused Realtime invalidation test: passed and proves a revision event causes a second catalogue fetch.
- canonical live Auth/member SQL regression: passed transactionally.
- canonical live catalogue SQL regression: passed transactionally.
- cleanup proof: zero synthetic Auth users, regression catalogue rows, or regression audit rows remain.
- live anonymous catalogue contract: 4 categories, 16 items, 27 variants, 27 add-on links; required Flutter JSON fields are present.
- Supabase security advisor: 0 lints.
- Supabase performance advisor: six `unused_index` INFO notices on the current low/no-traffic schema; no warning/error finding.
- migration ledger: all eight current live statements match the repository migrations semantically; only historical timestamp prefixes/comments/formatting differ. No schema or reconciliation migration is required.
- dashboard evidence at pushed commit `238e0ff211fe550f42ec4d4423724e3642282295`: lint, typecheck, 85 tests, build, and Playwright preview E2E 6/6 pass; Admin and POS browse the shared catalogue; no runtime `PREVIEW_MENU`, `PREVIEW_CATEGORIES`, or `PREVIEW_MODIFIER_GROUPS` fallback remains; public catalogue BFF returns 4/16/27; anonymous Admin endpoints return 401, cross-origin mutations return 403, authenticated non-admin mutation is rejected, and its Supabase security advisor has 0 lints.

## Remaining gates

- No deployed/device Auth sign-up/sign-in/reset/logout/member-read E2E was run.
- No deployed Admin write -> Realtime -> customer UI E2E was run; the customer invalidation behavior is proven at provider level and the live database publication/contract is verified separately.
- Real test identities and a deployment target are absent, so the remaining Auth/Menu cross-client gate cannot be exercised in this task.
- Dashboard preview checkout, totals, orders, and payments remain client/session-local and untrusted; the shared browsing catalogue does not make those transaction paths authoritative.

## Branch and PR stack

- Customer branch: `codex/task-menu-001-shared-catalogue`.
- Draft PR #7 is stacked on draft PR #6, which is stacked on draft PR #5.
- Merge order remains #5 -> #6 -> #7 after review and required validation.

## Exact next task

`TASK-AUTH-003 — provision approved real test identities and deployment targets, then run deployed customer Auth and Admin-write -> customer-Realtime cross-client E2E`.

After TASK-AUTH-003, the next product task remains `TASK-ORDER-001 — authoritative quote/cart/order foundation`.
