# Current Handoff

Updated: 2026-08-20

## Task

`TASK-UI-REDESIGN-003 — post-merge customer redesign audit, regression verification and release build`

**Verdict:** COMPLETE.

Source/backend audit, local executable verification, deliberate golden review, release APK production and mirrored documentation reconciliation are complete. GitHub-hosted Actions still fails before runner steps start, but the exact accepted Flutter 3.44.9 gate now passes locally and supplies the required artifact evidence.

## Starting state

Customer PR #15 had already merged the reviewed redesign onto `master` as merge commit `dcc97c481ae446d76b25bf8f91850e1d829c56f5`.

Directly redesigned surfaces:

- Menu;
- Item detail;
- Cart;
- Checkout sheet;
- Rewards;
- floating cart.

Shared presentation changes include `NeumorphicControl` and `AidaLogo`; Membership QR is indirectly affected visually because it already consumes the shared logo widget.

## Backend-impact audit

No regression was found in the implemented trusted backend features.

Preserved boundaries:

- Auth/session and customer provisioning remain in Supabase Auth/member flows;
- member code and QR remain server-owned identifiers with the existing minimum per-user offline cache;
- catalogue values remain `get_catalogue()`/Realtime-refetch data;
- Menu keeps live `imageUrl` primary and category art fallback-only;
- variants/add-ons remain server catalogue data;
- Cart remains local intent/estimate state;
- Checkout renders a server quote before placement;
- scheduled times come only from `derivePickupSlots(OrderingPolicy)` and are revalidated by the server;
- `OrderCheckoutSession` idempotency behavior is unchanged;
- history/detail/status remain persisted backend snapshots;
- customer status refresh remains owner-scoped orders Realtime followed by authorized refetch;
- payment remains explicit Pay at counter/unpaid;
- loyalty remains deferred and preview-backed.

Detailed evidence: `docs/frontend/UI_REDESIGN_AUDIT_2026-08-20.md`.

## Audit findings fixed on the task branch

Customer branch: `codex/task-ui-redesign-003-post-merge-audit`.

The redesign left stale test/testability assumptions:

1. Menu category rail no longer exposed the stable category keys used by golden/interaction coverage.
2. Cart-flow tests still expected the pre-redesign `Add to order` semantics and `2 items` floating-cart text.
3. There was no UI-level regression proving the redesigned Schedule interaction still submitted a server-policy-derived slot.

Fixes:

- restored `menu_cat_all`, `menu_cat_favorites`, `menu_cat_<category-id>` keys;
- rewrote cart flow assertions against `Add to cart · total` and `floating_cart_bar`;
- test order adapter records quote requests;
- new Schedule test requires `requestedPickupAt` to be one of `derivePickupSlots(TestOrderRepository.policy)`.

These are regression/testability changes only. No production backend adapter/model/provider contract was changed.

Local execution found three additional bounded issues and fixed them:

1. Flutter 3.44.9 deprecated `SizeTransition.axisAlignment`; Checkout now uses the behavior-equivalent `AlignmentDirectional.topStart` and analysis is clean.
2. The sold-out detail test expected one label even though the redesign intentionally exposes both an unavailable badge and disabled action label.
3. The cart-flow test restored a global test-only image client too late for Flutter's painting invariant; it now restores it in `finally` before the test body exits.

## Documentation gaps fixed

Updated/created customer docs:

- `docs/frontend/UI_REDESIGN_SPEC.md`;
- `docs/frontend/UI_REDESIGN_AUDIT_2026-08-20.md`;
- `docs/frontend/UI_SCREEN_MAP.md`;
- `docs/frontend/STATE_AND_DATA_FLOW.md`;
- `docs/frontend/FRAGILE_BOUNDARIES.md`;
- `docs/frontend/MOCKS_AND_PLACEHOLDERS.md`;
- `docs/context/CODEBASE_MAP.md`;
- `docs/context/ACTIVE_CONTEXT.md`;
- `docs/context/AUDIT_LOG.md`;
- this handoff.

Key corrections include:

- Rewards is mixed real-member/mock-loyalty, not wholly mock;
- Membership QR inherits the shared bundled-logo visual change but not a QR/member trust change;
- live catalogue imagery remains primary;
- category art/logo files are presentation assets only;
- the checkout wheel is presentation over authoritative policy slots;
- stale golden/test selectors are documented as verification debt, not backend failures.

## CI bootstrap

Because the repository previously had no executable default-branch workflow, `TASK-CI-001` added and merged one isolated file:

`.github/workflows/customer-release-audit.yml`

Customer `master` now contains that reusable workflow at commit `92cdbd5c2b4a7fc66a565f4de88b77bf25e953e7`.

The workflow is intended to run:

- Flutter 3.44.9;
- `flutter pub get`;
- `flutter analyze`;
- non-golden regression tests;
- golden tests as separately retained visual evidence;
- `flutter build apk --release`;
- artifact upload `aida-customer-release-apk`.

## Hosted Actions history

PR #16 triggered workflow run `32359646611` on head `940074b7ccf1c0ccd875dd1c1109f883bc1a91a3`.

Attempt 1:

- job `96396288072`;
- queued then immediately failed;
- no executed steps returned;
- no usable logs;
- no artifacts.

Explicit rerun:

- job `96396949294`;
- same pre-step failure;
- no artifacts.

This does not establish a Flutter failure because the runner never produced Flutter-step evidence. The repository is private and the GitHub connector does not expose the user/account Actions billing/hosted-runner setting required to resolve this pre-step failure. The failure remains CI operational debt, but it is no longer the task verification blocker.

## Local executable evidence

Environment:

- Flutter 3.44.9;
- Dart 3.12.2;
- JDK 21.0.12;
- Android SDK/platform/build-tools 36.

Results:

- `flutter pub get`: PASS;
- `flutter analyze`: PASS, no issues;
- non-golden suite: 41/41 PASS;
- full Flutter suite: 45/45 PASS;
- release build: PASS;
- package: `com.aidacafe.aida_customer`;
- APK: `apps/customer/build/app/outputs/flutter-apk/app-release.apk`;
- size: 64,197,534 bytes;
- build timestamp: 2026-08-20 19:45:12 +08:00;
- SHA-256: `9C36394EA0469F74F36B6908B6148A69263612D1F99ADB9C7EFCFB4724449B75`;
- APK Internet permission: present;
- production/decompressed-app secret marker scan: no service-role/secret marker.

Golden evidence was reviewed deliberately. Home and Home-scrolled pass unchanged. Menu-selected was updated for the accepted grid-to-vertical-rail/list redesign. Membership-card was updated only for the placeholder-to-bundled-logo change; QR/layout/member identity remained intact. The rerun passes 4/4 goldens.

No Android device was connected, so device smoke was not performed or claimed. This was an optional gate; existing physical Auth/member/catalogue evidence remains separate and valid.

## Dashboard documentation sync

Matching Dashboard branch already exists:

`codex/task-ui-redesign-003-post-merge-audit`

The customer redesign/governance documents are mirrored there without Dashboard runtime changes. Repository-local customer screenshots are not mirrored. Final executable/golden/APK wording must remain content-equivalent before the dashboard docs PR is marked ready.

## Prior implementation evidence

TASK-CLOSEOUT-001 remains valid evidence for the trusted pre-redesign Auth/member/catalogue/order implementation and the retained live order `100006`. It does not replace the missing fresh post-redesign Flutter build gate.

## Exact remaining actions

1. Commit and push the bounded local fixes, reviewed goldens and final evidence to customer PR #16.
2. Synchronize the same canonical evidence wording to Dashboard PR #14 without runtime changes.
3. Mark both PRs ready for review.
4. Preserve merge order: customer PR #16 first, Dashboard docs PR #14 second.
5. Do not merge automatically; hosted Actions runner failure remains operational CI debt, and an Android device smoke test may be performed later as extra evidence but is not required for this completed local gate.
