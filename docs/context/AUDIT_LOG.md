# Audit Log

Updated: 2026-08-14

This is the shared cross-repository task ledger. Detailed forensic evidence remains in the task branches, commits and PR discussions; current product truth is governed by `ACTIVE_CONTEXT.md`, accepted ADRs, current repository evidence and live backend evidence.

Historical `PARTIAL` verdicts below describe the gate state at that task's completion time. Later entries may explicitly close those old blockers.

## 2026-08-14 — TASK-CLOSEOUT-001 — tranche reconciliation

**Verdict:** PARTIAL while closeout work is in progress.

Created coordinated `codex/task-closeout-001-tranche-completion` branches and direct integration PRs: customer PR #13 -> `master`, Dashboard PR #12 -> `main`. Created `codex/task-closeout-001-doc-sync` plus customer docs PR #14 and Dashboard docs PR #13 so current evidence could be reconciled without racing active implementation work.

Dated live baseline: 9 shared account identities/profiles, 6 customer members, one owner, one admin, one staff profile, catalogue revision 15 and no retained orders. The current security-advisor state includes one hosted account-security configuration warning rather than the historical zero-finding result.

User physical validation closed three former gates: fixed Android release app reached the backend and created a customer; that member appeared in protected Dashboard Members; and a real Owner catalogue price change propagated to the installed customer app.

Remaining closeout: reproducible Android release build from committed configuration, Dashboard React authoritative order integration, customer placement -> Dashboard fulfilment -> customer refresh E2E, final toolchain/security checks, byte-identical mirrored docs and mergeability review.

## 2026-08-14 — TASK-AUTH-006 — Android release networking

**Historical verdict:** PARTIAL at Codex completion; physical validation subsequently closed by TASK-CLOSEOUT-001 evidence.

Audit proved release builds lacked Android INTERNET permission because only development overlays declared it. Main manifest was fixed, transport failures received bounded user-safe messaging, Flutter analyze passed, 44/44 tests passed, and the resulting release APK declared INTERNET.

The generated APK was 63,863,395 bytes with SHA-256 `3A7B5F027B846F4BE58865C09ABADBC63DD7B3EAE446331D708EA2FC67AF1201`. The user later installed the fixed app and successfully created a live customer, closing the runtime network gate.

Build reproducibility remained separate debt because the successful package used local build-tool compatibility settings while the committed Android plugin version lagged the resolved dependency minimum.

## 2026-08-13 — TASK-AUTH-005 — preview/live Dashboard session separation

**Verdict:** COMPLETE for the bounded regression.

Reproduced the Admin Members/Menu -> management-entry oscillation caused by a local preview identity being mixed with live protected requests. The fix separated preview failure handling from real employee-session handling, kept preview Members non-privileged, made preview Menu public/read-only, and preserved the real protected session boundary.

Dashboard lint/typecheck, 99 unit/component tests, production build and 7 Playwright flows passed. No backend authorization was weakened.

## 2026-08-13 — TASK-AUTH-004 — runtime access/configuration fixes

**Historical verdict:** PARTIAL; later physical/customer/operator evidence closed its main runtime blockers.

Customer app received safe public backend defaults and clearer upstream account/transport diagnostics. Dashboard local BFF received the same public project defaults; protected management routes preserved intended destination and management entry displayed specific access/configuration failure classes.

No member-directory authorization, RLS or protected employee-session architecture was weakened. Later real customer and Owner validation superseded the task's old zero-identity/manual-validation blockers.

## 2026-08-13 — TASK-DEMO-ORDER-001 — customer Flutter order integration

**Historical verdict:** PARTIAL for the full cross-client feature; customer client integration implemented.

Flutter integrated ordering policy, authoritative quote, ASAP/scheduled pickup, idempotent placement, Pay-at-counter semantics, persisted order identity/status, backend history/detail and owner-scoped order invalidation/refetch.

Customer source removed random order-number authority, local historical-order truth and timer-generated fulfilment progress. Flutter 3.44.9 analyze passed and the then-current full suite passed 40/40.

Dashboard React fulfilment/POS transaction integration and cross-client order E2E remained open and are now TASK-CLOSEOUT-001 work.

## 2026-08-13 — TASK-DEMO-ORDER-001 — authoritative order/scheduling backend

**Historical verdict:** PARTIAL for end-user feature; backend scope implemented and live-validated.

Added canonical order/scheduling migrations, FORCE-RLS tables, authoritative quote/customer/POS placement, immutable commercial snapshots, idempotency, scheduling policy, versioned legal fulfilment transitions, append-only events and `orders` Realtime publication.

Canonical transactional order regression passed, including forged-total rejection, catalogue/variant/add-on validation, schedule rejection, trusted customer derivation, idempotency, customer ownership, staff queue/POS access, version conflict/transition rules and management-only policy update. Foreign-key indexes were hardened by forward migration.

Dashboard order BFF/API endpoints were added using the existing protected employee request model. No real payment authority was added.

## 2026-08-13 — TASK-AUTH-003 — deployment/device preflight

**Historical verdict:** PARTIAL.

Customer release web/runtime checks and Dashboard deployment preflight were performed. A Vercel project/deployment was created, but hosted backend runtime configuration was incomplete. At that historical point there were no approved live test identities, so full hosted account/member/catalogue E2E could not be claimed.

The later accepted demo topology became local Dashboard PC + cloud backend + installed Android app. Hosted deployment remains deferred operational work unless a later requirement promotes it into a completion gate.

## 2026-08-13 — AUTH-001/AUTH-002/TASK-MENU-001 — customer validation closeout

**Historical verdict:** PARTIAL pending then-unavailable real-identity/device E2E.

Customer dependency resolution, analyze and 32-test suite passed on the validated toolchain. Minimum per-user offline member-code caching was added and isolated from role/loyalty/pricing authority. Catalogue revision invalidation/refetch was covered. Production hardcoded menu/size-price authority was removed.

Canonical account/member and catalogue SQL regressions passed transactionally with cleanup. Live schema/migration ledger was reconciled and security checks passed at that time.

Later TASK-CLOSEOUT-001 physical evidence closed the old customer-account and Admin-catalogue cross-client gates.

## 2026-08-13 — AUTH-002/TASK-MENU-001 — Dashboard validation closeout

**Historical verdict:** PARTIAL pending then-unavailable real-identity/deployment E2E.

Dashboard POS browsing stopped using preview catalogue authority and switched to the shared published catalogue. Full npm install/lint/typecheck/unit/build/preview-E2E suites passed at the recorded task head. Protected management endpoints failed closed for anonymous/non-management/cross-origin probes.

Later real Owner/customer validation superseded the old zero-identity gate. Preview transaction/payment/reporting domains remained explicitly untrusted.

## 2026-08-12 — TASK-MENU-001 — shared catalogue

**Historical verdict:** PARTIAL under full-stack gate until later client/device validation.

Implemented shared catalogue categories/items/variants/add-on compatibility, integer-sen prices, availability/publication, audit/revision signaling and protected management mutations. Seeded the former 16 customer menu entries, removed customer runtime hardcoded catalogue/size authority, wired Flutter catalogue reads/revision invalidation and replaced Admin Menu fixture authority.

Database regression covered public reads, management create/update, revision/audit, customer write denial and unpublished visibility. Later physical Owner mutation -> installed customer refresh validated the cross-client path.

## 2026-08-12 — TASK-AUTH-002 — trusted Dashboard employee/Admin boundary

**Historical verdict:** PARTIAL until later real-identity validation.

Implemented same-origin employee login/session/logout server boundary, HttpOnly browser session cookies, trusted role/disabled-state checks, protected management member API and caller-scoped backend access. Customer/disabled/ordinary staff access to management member data remained denied.

Later real Owner/Admin identities and physical customer -> Dashboard Members validation closed the main integration gate.

## 2026-08-12 — TASK-AUTH-001 — customer account/member integration

**Historical verdict:** PARTIAL until trusted Dashboard session and later real-device E2E existed.

Wired customer account lifecycle to the shared backend, removed client-generated trusted member identity/code, hardened signup metadata, implemented trusted customer profile/member reads and created protected management member-directory capability. Server-side provisioning ignored forged trusted role/member-code/verification fields.

Later AUTH-002 supplied the management server boundary; TASK-CLOSEOUT-001 evidence subsequently proved physical customer creation -> trusted member -> Dashboard Members.
