# Active Context

**As of:** 2026-08-20
**Current task:** `TASK-UI-REDESIGN-003 — post-merge customer redesign audit, regression verification and release build`
**Current verdict:** PARTIAL — source/backend audit and documentation reconciliation are complete; fresh Flutter execution and release APK remain blocked by GitHub-hosted Actions failing before runner steps start.

## Current product reality

AIDA Café uses one Supabase backend for the Flutter customer app and the React Dashboard/Admin/POS. The implemented trusted tranche remains Auth/member provisioning, protected employee/Admin sessions, shared catalogue, authoritative ordering/scheduling, customer order history/status, Dashboard POS quote/place/order queue/status transitions, and Android release networking/build reproducibility.

The customer app also carries the merged Menu, Item detail, Cart, Checkout and Rewards presentation redesign. The redesign has now been traced against the implemented backend boundaries and does not transfer authority from Supabase/server contracts to the client.

Detailed redesign documents:

- `docs/frontend/UI_REDESIGN_SPEC.md`
- `docs/frontend/UI_REDESIGN_AUDIT_2026-08-20.md`
- `docs/frontend/UI_SCREEN_MAP.md`
- `docs/frontend/STATE_AND_DATA_FLOW.md`
- `docs/frontend/FRAGILE_BOUNDARIES.md`
- `docs/frontend/MOCKS_AND_PLACEHOLDERS.md`

## Redesign audit result

Source/data-flow review found no redesign regression in these trusted boundaries:

- Supabase Auth/session and customer provisioning;
- owner-scoped profile/member reads and minimum per-user offline member-code cache;
- shared catalogue authority, Realtime invalidation and authoritative refetch;
- server catalogue IDs/prices/availability/variant/add-on compatibility;
- local cart intent versus server quote authority;
- OrderingPolicy-derived scheduling;
- retry-stable customer placement idempotency;
- persisted order number/history/detail/status;
- owner-scoped orders Realtime invalidation/refetch;
- explicit Pay-at-counter/unpaid payment boundary.

The merged redesign specifically preserves live catalogue `imageUrl` as Menu item imagery, uses bundled category art only as presentation fallback, labels cart values as estimates before quote, and populates the checkout wheel exclusively from `derivePickupSlots(OrderingPolicy)`.

Rewards is now documented correctly as a mixed surface: member identity display is based on the real owner-scoped member/profile provider, while points/rewards/vouchers remain preview-backed pending the trusted loyalty task.

Membership QR is indirectly affected only by the shared `AidaLogo` replacement. QR payload, member-code authority and offline cache semantics are unchanged; the logo asset is bundled and therefore offline-safe.

## Audit fixes on the task branch

Branch: `codex/task-ui-redesign-003-post-merge-audit`.

The audit found stale verification assumptions left by the redesign and corrected them without changing backend authority:

- restored stable Menu category automation keys (`menu_cat_all`, `menu_cat_favorites`, `menu_cat_<category-id>`);
- updated the cart-flow regression to use the redesigned CTA/floating-cart affordance;
- added quote-request recording to the test order adapter;
- added a scheduled-checkout regression requiring the selected timestamp to come from `derivePickupSlots(TestOrderRepository.policy)`;
- expanded customer redesign/data-flow/fragile/mock/codebase documentation.

No schema, migration, RPC, RLS, provider binding, repository implementation, Auth lifecycle, order payload/state-machine, payment, loyalty, inventory or reporting authority was modified.

## Fresh execution / APK status

A reusable clean-checkout workflow was added to customer `master` by `TASK-CI-001`:

`.github/workflows/customer-release-audit.yml`

It is configured for Flutter 3.44.9 and performs dependency resolution, static analysis, non-golden regressions, separate golden evidence, and `flutter build apk --release`, then uploads `aida-customer-release-apk`.

PR #16 triggered workflow run `32359646611` on audit head `940074b7ccf1c0ccd875dd1c1109f883bc1a91a3`.

Execution evidence:

- attempt 1: job `96396288072` queued then failed immediately;
- rerun: job `96396949294` queued then failed immediately;
- both attempts expose zero executed step records;
- no job log blob is available;
- no artifacts were produced.

This pattern is an Actions runner/account execution failure before Flutter steps, not evidence of a Flutter analysis/test/build failure. The repository is private and the linked GitHub identity has repository admin permissions, but the available connector does not expose the account Actions billing/runner setting that caused the pre-step rejection.

Therefore there is currently **no fresh APK** and no fresh post-redesign Flutter PASS to claim. The older TASK-CLOSEOUT-001 release APK/build proof predates this redesign and cannot substitute for this gate.

## Prior validated implementation evidence

TASK-CLOSEOUT-001 remains valid for the backend/authority implementation it proved on 2026-08-17:

- physical Android connectivity/signup/member provisioning;
- owner catalogue mutation observed by installed customer app;
- customer authoritative quote/place;
- retained order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`), authoritative total 1,290 sen;
- Dashboard persisted `confirmed` v1 → `preparing` v2 → `ready` v3 → `completed` v4;
- customer-authorized reads observed the persisted transitions;
- canonical Auth/member/catalogue/order SQL regressions passed.

Those results prove the pre-redesign trusted backend implementation, not the new visual regression/build gate.

## Dashboard documentation synchronization

TASK-UI-REDESIGN-003 includes mirroring the updated customer redesign/governance documentation to `Hermann-33/Aida_System-Dashboard` on the matching branch `codex/task-ui-redesign-003-post-merge-audit`. Dashboard runtime/source code is not changed by this task.

## Security and deployment

No redesign change weakens RLS, exposes employee tokens, adds a service-role key, changes public Auth configuration, grants direct order DML, changes member-code trust, introduces client-trusted pricing, or manufactures payment state.

The hosted Supabase Auth warning `auth_leaked_password_protection` / Leaked Password Protection Disabled remains separate operational configuration debt.

Hosted/Vercel deployment remains deferred for the accepted local Dashboard PC → cloud Supabase → installed customer phone topology.

## Deferred product domains

Real payment/refunds, trusted loyalty ledger/redemption, inventory, promotions/discount authority, tax/accounting, trusted reporting, branch-scoped operations/hours/capacity, delivery, notifications, several profile/settings surfaces and hosted production distribution remain future bounded tasks.
