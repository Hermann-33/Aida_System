# Current Handoff

Updated: 2026-08-17

## Task

`TASK-CLOSEOUT-001 — complete and close the current AIDA implementation tranche`

Coordinated branches:

- customer: `codex/task-closeout-001-tranche-completion`
- dashboard: `codex/task-closeout-001-tranche-completion`

Integration PRs:

- customer PR #13 → `master`
- dashboard PR #12 → `main`

Both are draft and technically mergeable.

**Verdict:** PARTIAL — all implementation/toolchain gates are closed; one live cross-client order E2E gate remains.

## Closed implementation gates

### Customer

- physical Android networking/Auth/signup works;
- trusted profile/member provisioning works and appears in Dashboard Members;
- shared catalogue refresh from a real Owner mutation works on the installed phone;
- authoritative quote/place, ASAP/scheduled pickup, Pay at counter, persisted history/detail/status and owner-scoped status refetch are implemented;
- Android release builds reproducibly from committed Git with AGP 8.9.1 and Gradle 8.11.1;
- Flutter 3.44.9 pub get/analyze/44 tests/release build pass;
- independent clean-worktree release build passes;
- canonical Auth/member, catalogue and order SQL regressions pass transactionally.

### Dashboard

- real employee/Admin same-origin HttpOnly BFF path is implemented;
- protected Members and shared catalogue Admin mutation are implemented and physically validated;
- TASK-AUTH-005 preview/live regression remains fixed;
- authoritative POS quote/place and server-policy scheduling are implemented;
- live order board polls the BFF and has no preview-order fallback;
- legal versioned status transitions and 409 conflict refetch are implemented;
- active order semantics are Pay at counter/unpaid only;
- lint/typecheck/25 Vitest files with 111 tests/build/8 Playwright tests/diff check pass;
- final `npm audit` reports 0 vulnerabilities.

## Last verified backend evidence

Dated 2026-08-14:

- 9 Auth users;
- 9 profiles;
- 6 members;
- 1 owner;
- 1 admin;
- 1 staff;
- 0 retained orders at baseline;
- catalogue revision 15.

Current advisor evidence: one WARN for leaked-password protection being disabled. Hosted deployment remains DEFERRED for the accepted local-PC → cloud-Supabase → installed-phone workflow.

## Only remaining closeout action

Run one credential-backed supported order lifecycle using approved demo accounts supplied ephemerally:

1. authenticate as a real customer/member;
2. place through the supported customer ordering boundary;
3. observe the persisted order in the Dashboard queue;
4. transition it to preparing;
5. confirm the customer authorized read/refetch observes preparing;
6. transition to ready;
7. confirm the customer observes ready;
8. transition to completed;
9. confirm the customer observes completed.

Do not commit credentials, reset durable demo passwords, use service role, or insert an order directly with SQL.

## After that run

- record the order E2E evidence in both mirrored governance sets;
- rerun final diff/status/secret/security and PR mergeability checks;
- change both PR titles from `[PARTIAL]` only if every gate remains green;
- mark both PRs ready for review;
- merge the coordinated integration PRs rather than the old stacked task PRs;
- close/supersede obsolete draft PRs after successful integration.

Do not start the next business-domain feature before this closeout is complete.
