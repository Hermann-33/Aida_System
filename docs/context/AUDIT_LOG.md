# Audit Log

This is the mirrored project-level chronology. Historical task verdicts describe the state at that task's completion; later entries supersede earlier open blockers without rewriting history.

## 2026-08-20 — TASK-UI-REDESIGN-002 customer UI redesign integration

**Verdict:** COMPLETE for the mobile repository integration target.

Reviewed `customer-app-redesign` against current `master`. The source branch was not directly merged because it was 140 commits behind `master`, five commits ahead and carried two unrelated July admin-sidebar documentation commits. A clean `codex/ui-redesign-integration` branch was created from current `master` and only the reviewed redesign delta was carried forward.

The visual redesign covers Menu, Item detail, Cart, Checkout sheet, Rewards, the floating cart bar, shared logo presentation and a small reusable control extension. `MenuGridItem` is retired in favor of `MenuListItem`; a bundled `aida_logo.jpg` asset replaces the previous logo placeholder; four repository-local screenshots are retained for Menu, Item detail, Cart and Rewards.

Integration review found and corrected three source-branch regressions before merge:

1. The source checkout wheel offered arbitrary minutes and imposed client-only 8am–5pm hours. The integrated wheel now receives only `derivePickupSlots(OrderingPolicy)` values, preserving schedule enablement, lead time, slot interval, maximum advance horizon and backend timezone/server time.
2. The source Menu list ignored catalogue `imageUrl` and always showed category art. The integrated `MenuListItem` renders the live item image first and uses category art only as fallback.
3. The source branch carried an unrelated `shared_preferences` dependency change. Integration preserves the current `master` pin (`2.5.5`) and adds only the logo asset registration.

No backend schema, RPC, RLS, Auth, role, pricing, payment, loyalty, voucher, inventory, reporting, audit or order-state authority changed. Cart values remain estimates before server quote; order placement/status remain server-owned; Rewards still does not simulate authoritative redemption.

Source-branch verification recorded by the colleague's environment was `flutter analyze` 0 issues and `flutter test` 40/44 passing, with four documented pre-existing golden mismatches and no golden update. This integration environment had no repository-local Flutter/Codex toolchain and the repository has no GitHub Actions workflow, so the corrected clean integration was not independently rerun through Flutter analysis/tests here. Source-level contract and diff review was completed; this limitation is explicitly preserved rather than converted into a false PASS.

Cross-repository documentation sync to `Hermann-33/Aida_System-Dashboard` remains **PENDING by explicit task scope**.

## 2026-08-19 — TASK-UI-REDESIGN-001 customer UI redesign documentation

**Verdict:** COMPLETE for this task's mobile-repository documentation scope.

Inspected a presentation-layer redesign already implemented on branch `customer-app-redesign` (pushed to `Hermann-33/Aida_System`, not yet a PR): Menu, Item detail, Cart, Checkout sheet and Rewards. Compared the branch against `hermann/master` at `fcfb179` (the 2026-08-17 `TASK-CLOSEOUT-001` state) file by file; separated genuine changes from a repository-wide `dart format` pass that also touched several unrelated files with no semantic effect (confirmed by hand for each such file).

Created `docs/frontend/UI_REDESIGN_SPEC.md`: scope, design goals, design system (colors/type/spacing/shape/elevation/iconography/motion, each value cross-checked against source), shared-component inventory (new: `MenuCategoryRail`, `MenuListItem`; changed: `NeumorphicControl`, `FloatingCartBar`, `AidaLogo`; removed: `MenuGridItem`), navigation, a full screen-by-screen specification with visual and behavioral deltas kept explicitly separate, responsive/accessibility findings, known gaps and maintenance rules. Captured five new screenshots (`docs/screenshots/2026-08-19-*-redesign.png`) via a temporary widget test, without overwriting any pre-existing baseline screenshot.

Updated `docs/frontend/UI_SCREEN_MAP.md` (dated note, no table/status changes — all five surfaces' data source and integration status are unchanged), `docs/frontend/FRAGILE_BOUNDARIES.md` (new contract-sensitive-assumption note), `docs/frontend/FRONTEND_AUDIT.md` (one-line scope-note pointer only, no historical finding altered), and this repository's `ACTIVE_CONTEXT.md`/`HANDOFF.md`. Left `STATE_AND_DATA_FLOW.md`, `MOCKS_AND_PLACEHOLDERS.md`, `CODEBASE_MAP.md`, all ADRs, `ARCHITECTURE.md`, `SYSTEM_MAP.md`, `SUPABASE_STATUS.md` and both backend-contract docs unmodified — inspection found no genuine architecture, trust-boundary, or backend-contract change to justify touching them.

One real (not merely visual) finding at that task boundary: the checkout sheet's redesigned pickup-time picker no longer clamped minute selection to `OrderingPolicy.slotIntervalMinutes`, so it could submit a `requestedPickupAt` the backend's existing slot-alignment validation would reject; same-day scheduling also enforced a client-only 8am–5pm window with no `OrderingPolicy` counterpart. Both were documented as open items, not fixed, because TASK-UI-REDESIGN-001 was documentation-only. TASK-UI-REDESIGN-002 on 2026-08-20 subsequently corrected both before integration.

Verification recorded by the source task: `flutter analyze` 0 issues; `flutter test` 40/44 passing on that branch, with the same 4 golden-image failures (`home`, `home scrolled`, `menu with a category selected`, `membership card`) documented as pre-existing. No golden baseline was updated.

Cross-repository documentation sync: **PENDING** — `Hermann-33/Aida_System-Dashboard` was out of scope for the task and was not accessed.

## 2026-08-17 — TASK-CLOSEOUT-001 final cross-client verification

**Verdict:** COMPLETE.

Approved demo credentials were supplied only through process-local environment variables. A real customer authenticated with trusted `app_role=customer` and one active member. The live published Sandwich item was quoted for ASAP pickup at an authoritative total of 1,290 sen. `place_customer_order` persisted order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`) as `confirmed` version 1.

A real Owner authenticated through the Dashboard same-origin HttpOnly BFF. The Dashboard queue observed the exact UUID, order number, total, status and version. Versioned BFF transitions persisted `preparing` version 2, `ready` version 3 and `completed` version 4; customer-authorized `get_order` reads observed each changed state. Independent database verification confirms one retained completed order and an event sequence of created/confirmed → preparing → ready → completed.

Final Dashboard checks passed: lint with two established Fast Refresh warnings, typecheck, 25 Vitest files / 111 tests, production build, Playwright 8/8, `npm audit` 0 vulnerabilities and `git diff --check`. Customer closeout checks already passed Flutter 3.44.9 pub get, zero-issue analyze, 44/44 tests, release build in the task checkout and an independent clean worktree, plus canonical Auth/member, catalogue and order transactional regressions.

No service role, direct SQL order insertion, password reset, browser employee bearer-token persistence, client-trusted price/status or credential-bearing repository file was used. E2E credential variables were removed after authenticated work.

Independent closeout verification rechecked 9 Auth users, 9 profiles, 6 members, roles owner/admin/staff = 1/1/1, catalogue revision 15 and one retained completed order. The current Supabase security advisor has one WARN: `auth_leaked_password_protection` / Leaked Password Protection Disabled.

Customer PR #13 and Dashboard PR #12 were independently mergeable at closeout. TASK-CLOSEOUT-001 had no remaining implementation or applicable ADR-0004 validation blocker. Hosted deployment remains DEFERRED.

## 2026-08-14 — TASK-CLOSEOUT-001 implementation closeout

**Verdict:** PARTIAL pending the final credential-backed live order lifecycle.

Customer closeout made Android release builds reproducible from committed Git by aligning AGP 8.9.1, Gradle 8.11.1 and Flutter compatibility properties. Customer Auth/member, catalogue and authoritative order frontend regressions passed; canonical SQL tests were hardened so approved live identities and legitimate catalogue mutations do not invalidate synthetic regression assumptions.

Dashboard closeout replaced preview/local order authority with the existing order BFF: typed same-origin order client, selection-only payloads, server quote authority, stable idempotent placement, ASAP/server-policy scheduling, explicit Pay-at-counter semantics, live 2.5-second queue polling, legal versioned status controls and 409 conflict refetch. Dashboard lint/typecheck/Vitest/build/Playwright passed and dependency advisories were remediated to `npm audit` 0 vulnerabilities.

Physical evidence already proved Android signup → trusted member → Dashboard Members and Owner catalogue mutation → installed customer refresh.

## 2026-08-14 — TASK-AUTH-006 Android release networking

**Verdict at task completion:** PARTIAL pending physical-device proof; subsequently closed by user validation.

Release audit proved `android.permission.INTERNET` was absent from the main/release manifest while present in debug/profile overlays. The permission was added to the main manifest, transport errors were mapped without leaking raw exception internals, and release/Auth regression tests were added. The later physical APK signup confirmed the old host-lookup defect was closed.

## 2026-08-13 — TASK-AUTH-005 preview/live Dashboard session loop

**Verdict:** COMPLETE.

Audited and fixed the loop caused by mixing preview identity from browser session storage with protected live BFF requests. Preview Members no longer requests privileged member data, preview Menu is public/read-only, preview BFF 401s no longer destroy preview identity, and real session expiry still clears real employee state. Lint/typecheck/Vitest/build/Playwright passed with no RLS or session-boundary weakening.

## 2026-08-13 — TASK-AUTH-004 runtime access

**Verdict at task completion:** PARTIAL; later physical and trusted-identity gates closed.

Customer runtime received safe active Supabase public defaults with override support and improved Auth diagnostics. Dashboard local BFF received matching public configuration defaults and fail-closed Admin login routing. No service-role key, browser employee bearer token or authorization bypass was introduced.

## 2026-08-13 — TASK-AUTH-003 deployment/E2E preflight

**Verdict:** PARTIAL; hosted deployment remains DEFERRED.

A clean Vercel deployment was created but its BFF runtime lacked required public Supabase environment configuration. The accepted demo topology was later clarified as local Dashboard PC → cloud Supabase → installed phone, so hosted deployment is preserved as operational debt rather than a closeout blocker.

## 2026-08-13 — TASK-DEMO-ORDER-001 authoritative ordering

**Verdict at task completion:** PARTIAL under ADR-0004; later fully closed by client integration and final E2E.

Canonical customer-repository migrations added FORCE-RLS order/scheduling tables, server-authoritative quote and placement, immutable commercial snapshots, idempotency, schedule policy, legal versioned fulfilment transitions, append-only events and `orders` Realtime publication. Transactional SQL regression proved forged totals ignored, schedule and compatibility validation, customer ownership, idempotency, direct-DML denial, staff queue/POS capability and legal/stale/terminal status behavior.

Dashboard order BFF/API adapters were added using the existing HttpOnly employee session and caller-JWT boundary. Flutter customer integration then added quote-before-place, server totals, retry-stable UUIDs, ASAP/scheduled pickup, Pay at counter, persisted history/detail/status and owner-scoped Realtime-triggered refetch without fake timers or random order authority.

## 2026-08-12 to 2026-08-13 — TASK-MENU-001 shared catalogue

**Verdict at task completion:** PARTIAL under full-stack gate; later physically validated.

A shared Supabase catalogue replaced customer hardcodes and Dashboard Admin/POS catalogue fixtures. The canonical seed contains 4 categories, 16 items, 27 variants and 27 compatible add-on links. Admin/owner writes use caller identity and RLS; mutations bump an audit/revision signal; Flutter listens for revision changes and re-fetches. The user later proved a real Owner price mutation propagated to the installed Android app.

## 2026-08-12 to 2026-08-13 — TASK-AUTH-001 / TASK-AUTH-002

**Verdict at task completion:** PARTIAL under full-stack gate; later physically validated.

Customer Supabase sign-up/sign-in/session/logout and trusted profile/member reads were integrated. Signup provisioning forces customer role, generates member code server-side and ignores forged trusted metadata. Dashboard protected Members was connected to a same-origin employee BFF using HttpOnly cookies and caller-JWT/RLS semantics; customer identities are denied employee/admin access.

## Foundation/governance tasks

Earlier workflow/database tasks established the dual-repository/single-Supabase topology, canonical migration ownership in the customer repository, mirrored governance/documentation requirements, identity/member schema with forced RLS, accepted ADRs and the full-stack completion discipline used by this closeout.
