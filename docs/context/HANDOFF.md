# Current Handoff

Updated: 2026-08-14

## Current task

`TASK-CLOSEOUT-001 — current tranche completion`

**Verdict:** PARTIAL

Implementation branch in both repositories:

`codex/task-closeout-001-tranche-completion`

Integration PRs:

- customer PR #13 -> `master`
- dashboard PR #12 -> `main`

Documentation branch in both repositories:

`codex/task-closeout-001-doc-sync`

Documentation PRs:

- customer PR #14 -> customer closeout branch
- dashboard PR #13 -> dashboard closeout branch

These docs must be incorporated into the final closeout heads before merge.

## Proven current behavior

- The fixed Android release app was installed on the physical phone and successfully created a customer against live Supabase.
- Trusted customer profile/member provisioning completed and the new member appeared in protected Dashboard Members.
- A real Owner session changed a catalogue price in Dashboard Admin Menu and the installed customer app observed the updated value.
- Closeout baseline: 9 Auth users/profiles, 6 customer members, one owner, one admin, one staff profile, catalogue revision 15 and no retained orders.
- TASK-AUTH-005 preview/live Dashboard session separation is complete and tested.
- Authoritative order/scheduling backend, customer Flutter ordering integration and Dashboard order BFF are implemented.
- No trusted payment processor exists; the current authoritative demo order semantics are Pay at counter / unpaid.

## Remaining closeout work

Customer repository:

- make Android release builds reproducible from committed build configuration;
- prove a clean-worktree release build;
- rerun final Flutter/backend/security checks.

Dashboard repository:

- replace preview live-order authority with the existing order BFF;
- finish authoritative quote/place, scheduling, live queue and versioned status transitions;
- rerun lint/typecheck/tests/build/Playwright/security checks.

Cross-client:

- prove customer placement -> persisted order -> Dashboard status transition -> customer authorized refresh.

Current Supabase advisor state includes one hosted Auth configuration warning; see `SUPABASE_STATUS.md` and `SECURITY_REVIEW.md` for the exact current finding. Historical zero-finding advisor results must not be treated as the current state.

## Merge policy

Do not merge the old stacked task PRs individually once the integration PRs are ready. The intended final paths are customer PR #13 and Dashboard PR #12.

Hosted Vercel runtime remains deferred operational work for the validated local-PC + cloud-Supabase + installed-phone demo topology.

## Exact next action

Let both Codex closeout runs finish. Incorporate the docs PRs, reconcile any implementation facts that changed during Codex work, compare mirrored governance files, rerun live Supabase/security evidence and inspect both integration PRs. Mark `COMPLETE` only if Android build reproducibility, Dashboard order integration and final cross-client order E2E all pass.
