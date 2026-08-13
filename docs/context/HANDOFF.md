# Current Handoff

Updated: 2026-08-14

## Current task

`TASK-CLOSEOUT-001 — current tranche completion`

**Verdict:** PARTIAL

Coordinated implementation branch in both repositories:

`codex/task-closeout-001-tranche-completion`

Integration PRs:

- customer: PR #13 -> `master`
- dashboard: PR #12 -> `main`

Both PRs remain draft until all closeout gates pass.

A parallel documentation-only reconciliation branch exists in both repos:

`codex/task-closeout-001-doc-reconciliation`

It exists to capture the already-proven evidence without racing Codex implementation edits. Its documentation must be incorporated/reconciled into the final closeout heads before merge.

## What is already proven

### Android customer Auth/member

The rebuilt release APK was installed on the user's physical phone. Customer signup succeeded against live Supabase. Trusted Auth/profile/member provisioning succeeded and the new member appeared in Dashboard Members.

Therefore the old `SocketException / Failed host lookup` runtime blocker and the old `physical device pending` / `zero identities` statements are closed/stale.

### Shared catalogue

A real Owner signed into the live local Admin path and changed a catalogue price. The installed customer app observed the updated value. This proves protected Admin mutation -> Supabase revision/data -> customer invalidation/refetch in the real local-demo topology.

Closeout baseline observed catalogue revision 15.

### Identity/role state

Dated closeout baseline:

- 9 Auth users/profiles;
- 6 customer members;
- 1 owner;
- 1 admin;
- 1 staff.

Employee identities are intentionally not members.

### Auth/session security

Dashboard employee/Admin sessions remain same-origin HttpOnly/caller-JWT. TASK-AUTH-005 preview/live session separation is complete and tested; preview 401s no longer destroy preview identity, and preview Members/Menu do not fabricate privileged data or writes.

### Order backend/customer client

Authoritative order/scheduling schema/RPC/RLS, Dashboard order BFF and Flutter customer quote/place/history/status integration are implemented. No real payment authority exists; current order demo semantics are Pay at counter/unpaid.

## Remaining closeout work

### Customer repository

- commit a supported Android build-tool configuration instead of relying on local AGP/Gradle compatibility settings;
- prove a clean-worktree release APK build;
- rerun Flutter/customer/backend/security checks;
- incorporate final mirrored docs.

### Dashboard repository

- replace preview transaction/order authority with the existing order BFF in live POS/order surfaces;
- implement authoritative quote/place, server-policy scheduling, Pay-at-counter semantics, live queue and versioned status transitions;
- retain HttpOnly employee token boundary and use BFF polling/refetch;
- rerun lint/typecheck/Vitest/build/Playwright/security checks;
- incorporate final mirrored docs.

### Cross-client

Prove customer place -> persisted order -> Dashboard transition -> customer authorized status refresh. The closeout baseline currently has 0 retained orders.

## Current security advisor

Supabase security advisor currently reports one WARN: leaked-password protection disabled. Historical `0 lints` results remain valid historical evidence for their dates but are not the current advisor state.

Do not commit passwords, service-role keys, employee bearer tokens or other secrets while closing the tranche.

## Merge policy

Do not merge the old stacked PRs individually once the integration PRs are ready. The intended merge path is the final complete integration PR in each repo:

1. customer PR #13 -> `master`;
2. dashboard PR #12 -> `main`;

The exact order can be chosen at final closeout if both are compatible, but neither should merge while the other still depends on unresolved shared-contract work.

After successful integration merges, close/supersede obsolete stacked draft PRs rather than leaving ambiguous merge paths.

## Deployment note

The current user-validated demo topology is local Dashboard PC -> cloud Supabase -> installed Android phone. Vercel deployment/runtime configuration remains deferred operational work and must not be described as production-complete.

## Exact next action

Let the two Codex closeout runs finish their bounded customer/dashboard work. Then reconcile this documentation into their final heads, compare mirrored governance files, rerun live Supabase/security evidence, inspect PR mergeability and only mark TASK-CLOSEOUT-001 `COMPLETE` if Android build reproducibility, Dashboard order integration and cross-client order E2E all pass.
