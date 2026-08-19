# Active Context

**As of:** 2026-08-20
**Current task:** `TASK-UI-REDESIGN-002 — review and integrate customer UI redesign`
**Current verdict:** COMPLETE for the mobile integration target; Dashboard documentation sync remains a separate follow-up by explicit task scope.

## Current product reality

AIDA Café uses one Supabase backend for the Flutter customer app and the React Dashboard/Admin/POS. The completed implementation tranche has tested authority for customer Auth/member provisioning, protected employee/Admin sessions, shared catalogue, authoritative ordering/scheduling, customer order history/status, Dashboard POS quote/place/order queue/status transitions, and Android release networking/build reproducibility.

The customer app now also carries the reviewed Menu, Item detail, Cart, Checkout and Rewards presentation redesign documented in `docs/frontend/UI_REDESIGN_SPEC.md`. The redesign does not transfer authority from Supabase/server boundaries to the client.

## Validated physical/manual evidence

The user validated on a physical Android phone and local Dashboard:

- release APK installation and Supabase connectivity;
- new customer signup;
- trusted Auth/profile/member provisioning;
- the new member appearing in protected Dashboard Members;
- real Owner Dashboard login;
- Owner catalogue price mutation;
- the installed customer app observing the updated catalogue value.

The previous Android `Failed host lookup / SocketException` release defect is closed.

## Current live Supabase evidence

Independently rechecked on 2026-08-17:

- Auth users: 9
- profiles: 9
- members: 6
- trusted roles: 1 owner, 1 admin, 1 staff
- retained orders: 1
- catalogue revision: 15

These counts are dated operational evidence, not architectural invariants. Employee identities are intentionally separate from customer/member rows.

The retained order is `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`), customer source, authoritative total 1,290 sen, final status `completed`, status version 4. Its event ledger records creation as confirmed followed by preparing, ready and completed transitions.

All intended identity, catalogue and order tables retain RLS/FORCE RLS; the ordering RPC surface exists; `orders` remains published to Realtime; ordinary customer clients do not have direct commercial order DML authority.

## Customer implementation status

COMPLETE for the implemented tranche:

- Supabase Auth/session/signup/logout and trusted profile/member provisioning;
- server-owned member code and student pending declaration boundary;
- minimum per-user offline member-code cache with logout/user-switch isolation;
- shared catalogue, variants/add-ons and revision invalidation/refetch;
- authoritative quote-before-place and server-owned totals;
- retry-stable idempotent customer placement;
- ASAP/scheduled pickup from server policy;
- explicit `Pay at counter`/unpaid semantics;
- persisted server order number/status/history/detail;
- owner-scoped order Realtime invalidation followed by authorized refetch;
- Android production INTERNET permission;
- reproducible Android release build from committed Git;
- reviewed presentation redesign for Menu, Item detail, Cart, Checkout and Rewards.

The redesign integration specifically preserves live catalogue `imageUrl` use in Menu rows, keeps cart totals labelled as estimates before server quote, and derives all selectable scheduled pickup values from `OrderingPolicy` through `derivePickupSlots`.

Baseline customer validation from TASK-CLOSEOUT-001: Flutter 3.44.9, pub get PASS, analyze PASS, 44/44 tests PASS, release APK PASS in the task checkout and an independent clean committed worktree. Canonical Auth/member, catalogue and order SQL regressions pass transactionally.

The historical redesign source branch separately recorded `flutter analyze` 0 issues and `flutter test` 40/44 with four documented pre-existing golden mismatches. The clean integration correction could not be independently re-run in the repository-operation environment because no Flutter toolchain or CI workflow was available; do not reinterpret that limitation as a fresh PASS.

## Dashboard implementation status

COMPLETE for the implemented tranche:

- same-origin employee/Admin BFF with HttpOnly session cookies and caller-JWT Supabase access;
- protected Admin Members;
- shared catalogue reads and protected Admin mutations;
- TASK-AUTH-005 preview/live session separation;
- typed same-origin order client;
- POS cart mapped to server-trusted IDs/quantity/note intent only;
- server quote rendered as commercial authority;
- stable `clientRequestId` for placement retries;
- ASAP/scheduled pickup derived from server policy;
- cart cleared only after persisted placement;
- explicit `Pay at counter`/unpaid semantics;
- live order queue polling every ~2.5 seconds with no preview-order fallback;
- legal versioned status transitions and 409 conflict refetch;
- no browser employee bearer-token persistence.

Dashboard validation from TASK-CLOSEOUT-001: lint PASS with two existing Fast Refresh warnings, typecheck PASS, 25 Vitest files / 111 tests PASS, build PASS, Playwright 8/8 PASS, `git diff --check` PASS, and final `npm audit` 0 vulnerabilities.

## Final live order E2E

Completed on 2026-08-17 through supported customer and Dashboard BFF boundaries using approved demo credentials supplied only as process-local environment variables:

- customer Auth and active-member validation passed;
- live published Sandwich catalogue item quoted for ASAP pickup at an authoritative total of 1,290 sen;
- customer `place_customer_order` persisted order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`) as `confirmed`, version 1;
- the authenticated Owner Dashboard queue observed the same UUID, order number, total, status and version;
- Dashboard transitions persisted `preparing` version 2, `ready` version 3 and `completed` version 4;
- the customer's authorized `get_order` read observed each persisted status;
- the final all-status Dashboard queue contained exactly one retained order, the completed E2E order.

No service role, direct SQL order insertion, password reset, client-trusted price/status or browser employee bearer-token persistence was used. The credential variables were removed after authenticated work and were never committed.

## 2026-08-20 customer redesign integration

The historical `customer-app-redesign` branch was not merged directly. Review found it was 140 commits behind `master`, five commits ahead, and included unrelated July admin-sidebar documentation history.

A clean integration branch was created from current `master` and only the reviewed customer redesign delta was carried forward. Two source-branch regressions were corrected during integration:

1. Checkout scheduling no longer invents a client-only 8am–5pm window or arbitrary minute values. The wheel UI is populated exclusively from `derivePickupSlots(OrderingPolicy)`, preserving `scheduleEnabled`, lead time, slot interval, maximum advance horizon and backend timezone/server time.
2. Menu list rows retain live catalogue `imageUrl` as the primary image source and use bundled category art only as fallback.

A stale `shared_preferences` dependency change from the source branch was also rejected; the current `2.5.5` pin remains intact. The obsolete `MenuGridItem` is removed, the new AIDA logo asset is registered, and repository-local redesign screenshots are retained for Menu, Item detail, Cart and Rewards. The original checkout screenshot is intentionally not integrated because it depicts the rejected non-contract-compliant picker.

Cross-repository documentation sync to `Hermann-33/Aida_System-Dashboard` is **PENDING by explicit task scope** and is not a blocker for this mobile-repository integration.

## Security and deployment

The current Supabase security advisor has one hosted Auth warning: `auth_leaked_password_protection` / **Leaked Password Protection Disabled**. This is operational project configuration debt, not an RLS regression. Remediation: <https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection>.

Hosted/Vercel deployment remains **DEFERRED**. The accepted current demo topology is local Dashboard PC → cloud Supabase → installed customer phone.

## Deferred product domains

Real payment/refunds, loyalty ledger/redemption, inventory, promotions/discount authority, tax/accounting, trusted reporting, branch-scoped operations/capacity, delivery and hosted production deployment/release operations remain future bounded tasks.
