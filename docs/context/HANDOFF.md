# Current Handoff

Updated: 2026-08-20

## Task

`TASK-UI-REDESIGN-002 — review and integrate customer UI redesign`

**Verdict:** COMPLETE for the mobile repository integration target.

## Starting state

The source branch `customer-app-redesign` could not be merged safely as-is:

- it was 140 commits behind current `master` and only 5 commits ahead;
- two of those ahead commits were unrelated July admin-sidebar documentation commits;
- its checkout picker ignored `OrderingPolicy.slotIntervalMinutes`, offered arbitrary minutes, and imposed a client-only 8am–5pm window;
- its Menu list rows discarded live catalogue `imageUrl` values in favor of category art;
- its `pubspec.yaml` carried an unrelated stale `shared_preferences` dependency change.

## Integrated result

A clean branch, `codex/ui-redesign-integration`, was created from current `master` and contains only the reviewed redesign delta.

Integrated presentation changes:

- Menu: vertical category/favorites rail and photo-forward flat list rows;
- Item detail: consolidated quantity + `Add to cart · total` CTA with transient success state;
- Cart: flat photo rows, swipe-to-remove, retained estimate/server-quote boundary;
- Checkout: redesigned wheel-style scheduled selection while retaining authoritative server-policy slots;
- Rewards: dark membership-card-family balance surface and in-page section controls;
- floating cart: animated appearance plus cart-line thumbnails;
- AIDA logo: bundled asset replaces the previous placeholder presentation.

Integration corrections:

1. `order_checkout_sheet.dart` now derives every selectable scheduled value from `derivePickupSlots(OrderingPolicy)`. No local opening-hours constants or arbitrary one-minute values remain.
2. `MenuListItem` now renders each catalogue item's `imageUrl` first and uses the bundled category asset only as fallback.
3. The current `shared_preferences: 2.5.5` dependency pin from `master` is preserved; only the new logo asset is added to `pubspec.yaml`.
4. The unrelated admin-sidebar commits/files from the stale source branch are not integrated.
5. The obsolete `MenuGridItem` is removed because the redesigned Menu uses `MenuListItem`.

## Authority and security

No backend schema, RPC, RLS, Auth, role, pricing, payment, loyalty, voucher, inventory, audit or order-state authority changed.

The following boundaries remain intact:

- Menu values come from the shared Supabase catalogue.
- Cart totals are local estimates only.
- Checkout displays an authoritative server quote before placement.
- Scheduled pickup is constrained by server ordering policy.
- Order persistence/status remains server-owned.
- Reward redemption remains deferred and is not simulated as an authoritative mutation.

## Verification

Source-branch evidence from the colleague's environment:

- `flutter analyze`: 0 issues;
- `flutter test`: 40/44 passing;
- four failures were documented as pre-existing golden mismatches (`home`, `home scrolled`, `menu with a category selected`, `membership card`); no golden baseline was updated.

Integration review performed here:

- compared source branch against current `master` and isolated the actual redesign delta;
- reviewed Menu, Item detail, Cart, Checkout, Rewards, shared control/logo and floating-cart source boundaries;
- removed stale dependency/history changes;
- corrected checkout schedule-policy compliance;
- corrected Menu live-image regression;
- reviewed the final clean branch diff against current `master`.

This repository has no GitHub Actions workflow, and the repository-operation environment used for integration did not expose a usable Flutter/Codex toolchain or local checkout. Therefore the corrected integration commit has **not** been independently rerun through `flutter analyze` or `flutter test` here. Do not record a fresh PASS for those checks without running them in a Flutter-capable environment.

## Documentation

Current redesign documentation:

- `docs/frontend/UI_REDESIGN_SPEC.md`
- `docs/frontend/UI_SCREEN_MAP.md`
- `docs/context/ACTIVE_CONTEXT.md`
- `docs/context/AUDIT_LOG.md`
- this handoff

Repository-local redesign screenshots are retained for Menu, Item detail, Cart and Rewards. The original checkout screenshot from the stale branch is intentionally excluded because it depicts the rejected non-contract-compliant picker.

## Cross-repository sync

`Hermann-33/Aida_System-Dashboard` documentation synchronization is **PENDING by explicit task scope**. This mobile integration does not attempt to access or modify the Dashboard repository.

## Prior closeout evidence

TASK-CLOSEOUT-001 remains the baseline for the previously completed Auth/member/catalogue/order/toolchain tranche, including physical Android validation, live cross-client order E2E, 44/44 customer tests at closeout, Dashboard lint/typecheck/Vitest/build/Playwright validation, canonical SQL regressions and the retained completed order `100006`.
