# Active Context

**As of:** 2026-08-14
**Current task:** `TASK-CLOSEOUT-001 — complete and close the current AIDA implementation tranche`
**Current verdict:** PARTIAL pending Dashboard order-frontend and cross-client order evidence

## Current validated reality

AIDA uses one Supabase backend for the Flutter customer app and React Dashboard/Admin/POS. Trusted identity/member, shared catalogue, authoritative ordering/scheduling, customer order UI, and Android release networking are implemented.

User-validated physical Android evidence now closes the prior AUTH-006 gate:

- the fresh release APK installed and connected successfully;
- customer signup created a Supabase Auth user, profile, and member;
- the member appeared in Dashboard Members;
- an Owner catalogue price mutation appeared in the installed customer app;
- the previous `Failed host lookup / SocketException` no longer blocked the app.

## Live baseline

Read-only Supabase evidence collected on 2026-08-14:

- Auth users: 9
- profiles: 9
- members: 6
- owners: 1
- admins: 1
- staff: 1
- orders: 0
- catalogue revision: 15

These counts are a dated operational snapshot, not architectural invariants.

All 14 intended public tables exist with RLS and FORCE RLS. All nine ordering RPC signatures exist. `orders` remains in `supabase_realtime`, and authenticated clients have no direct order insert/update authority.

The Supabase security advisor has one WARN: **Leaked Password Protection Disabled**. This is not fixed by application code and must not be reported as zero lints.

## Closeout changes and validation

Android release configuration is now reproducible from committed Git:

- Android Gradle Plugin 8.9.1
- Gradle wrapper 8.11.1
- Flutter Android migration compatibility properties committed

Flutter 3.44.9 passes `flutter pub get`, zero-issue analysis, 44/44 tests, and release APK build in both the task checkout and an independent clean worktree. The release APK contains `android.permission.INTERNET`.

Canonical Auth/member, catalogue, and order SQL regressions pass transactionally against the live project and leave retained counts unchanged. The tests now scope member-directory assertions to their synthetic rows and derive catalogue prices dynamically, so approved live identities and legitimate Admin price changes do not invalidate the regression harness.

## Remaining closeout gate

Dashboard PR #12 still records the POS authoritative quote/place UI, live order board/status UI, and customer-place → dashboard-transition → customer-authorized-refresh journey as outstanding. Customer PR #13 stays draft and this tranche stays PARTIAL until the Dashboard closeout provides passing toolchain/E2E evidence and its mirrored governance facts agree.

Deferred product domains remain real payment/refunds, loyalty ledger/redemption, inventory, promotions, tax/accounting, reporting, branch-scoped operations/capacity, and delivery.
