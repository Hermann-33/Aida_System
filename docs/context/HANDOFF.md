# Current Handoff

Updated: 2026-08-20

## Task

`TASK-UI-REDESIGN-003 — post-merge customer redesign audit, regression verification and release build`

**Verdict:** PARTIAL.

Source/backend audit, test-gap fixes and documentation reconciliation are complete. Fresh Flutter execution and APK production are blocked by GitHub-hosted Actions failing before any runner step starts.

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

## Execution result / blocker

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

This does not establish a Flutter failure because the runner never produced Flutter-step evidence. The repository is private and the GitHub connector does not expose the user/account Actions billing/hosted-runner setting required to resolve this pre-step failure.

The local execution environment also has no Flutter/Dart/Codex binary and outbound package/network access is blocked, so it cannot serve as a fallback build machine.

**APK status: NOT PRODUCED.** Do not use the older closeout APK as redesign verification.

## Dashboard documentation sync

Matching Dashboard branch already exists:

`codex/task-ui-redesign-003-post-merge-audit`

The customer redesign/governance documents are to be mirrored there without Dashboard runtime changes. Repository-local customer screenshots do not need mirroring.

## Prior implementation evidence

TASK-CLOSEOUT-001 remains valid evidence for the trusted pre-redesign Auth/member/catalogue/order implementation and the retained live order `100006`. It does not replace the missing fresh post-redesign Flutter build gate.

## Exact remaining actions

1. Restore GitHub-hosted Actions execution for the private customer repository/account, or run the same workflow commands on a Flutter 3.44.9-capable machine.
2. Re-run PR #16 until `flutter analyze`, non-golden tests and release APK build pass.
3. Review golden candidates separately; update only after deliberate visual approval if required.
4. Download/install the resulting APK and smoke-test the redesigned flows on the phone.
5. Update this task's verification evidence with the actual run/artifact.
6. Merge PR #16 only after those gates pass.
7. Merge the Dashboard documentation PR after verifying mirrored shared docs.
