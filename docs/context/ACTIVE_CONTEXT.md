# Active Context

**As of:** 2026-08-14
**Current implementation task:** `TASK-CLOSEOUT-001 — current tranche completion`
**Current task verdict:** PARTIAL

## Current product reality

AIDA Café is one product across the Flutter customer repository, React/Vite POS/Admin repository and shared Supabase project `eswovqxqzfevcdwwcmuh`.

The current integration tranche now has live evidence for customer Auth/member provisioning, protected Dashboard member access, shared catalogue administration and customer refresh, Android release networking, and the authoritative order backend/customer order client. The only substantive implementation work still open in this tranche is Android build reproducibility plus Dashboard React order/POS integration and final cross-client order E2E.

Detailed dated evidence is recorded in `docs/context/CLOSEOUT_EVIDENCE_2026-08-14.md`.

## Live closeout baseline

Observed on 2026-08-14:

- Auth users: 9
- profiles: 9
- members: 6
- owner profiles: 1
- admin profiles: 1
- staff profiles: 1
- retained orders: 0
- catalogue revision: 15

These are evidence snapshots, not permanent invariants.

## Proven physical/manual flows

The user installed the fixed Android release APK and successfully created a new customer account. The trusted Auth/profile/member provisioning completed and that member appeared in the Dashboard Members page through the real Admin/owner path.

The user also changed a real catalogue price from Dashboard Admin Menu using a trusted Owner session and observed the changed price in the installed customer app. This closes the previously outstanding customer signup -> Admin Members and Admin mutation -> catalogue revision/refetch -> installed customer UI gates.

TASK-AUTH-006's release transport defect is physically closed: the fixed release application can reach Supabase. The pre-fix cause was missing `android.permission.INTERNET` from the main Android manifest.

## Current implementation status

### Auth/member

Implemented and live-validated. Supabase Auth is authoritative; public signup cannot self-promote; trusted roles live in `user_profiles`; member codes are server-generated; member/profile reads are owner-scoped; Admin/owner member-directory access remains protected.

### Dashboard employee/Admin sessions

Implemented. Privileged browser flows retain same-origin HttpOnly session cookies and caller-JWT Supabase access. TASK-AUTH-005 separated preview identities from live employee session failures and removed the Members/Menu login oscillation without weakening authorization.

### Shared catalogue

Implemented and live-validated across both clients. Admin/owner writes use the protected BFF/RPC path; customer and POS reads use the shared catalogue. Customer invalidates/refetches after `catalogue_revision` changes.

### Ordering/scheduling

Backend and customer Flutter integration are implemented: authoritative quote/place, immutable snapshots, idempotency, ASAP/scheduled pickup, persisted statuses, history/detail and owner-scoped Realtime invalidation. The Dashboard order BFF exists.

Dashboard React still needs to replace preview transaction authority with the order BFF for POS quote/place and the live order board/status transition UI. No retained live order exists at the current baseline.

### Android release build

Runtime networking is fixed and physically validated. Release-build reproducibility is still open because the committed AGP 8.7.0 configuration is incompatible with the currently resolved AndroidX minimum; the prior successful APK depended on local compatibility settings. Closeout must commit the correct supported toolchain and prove a clean build.

## Security status

RLS/trusted-boundary evidence remains intact. No service-role/secret key belongs in customer or browser source.

The current Supabase security advisor reports one hosted Auth warning: leaked-password protection is disabled. Do not retain historical `0 lints` as the current advisor state. This warning is project configuration debt and is not evidence of an RLS regression.

## Deployment status

The accepted current demo workflow is local Dashboard PC -> cloud Supabase -> installed customer phone. Vercel deployment exists historically but its runtime configuration was not completed. Hosted deployment is therefore recorded as deferred operational work, not as a completed production deployment and not as a blocker for the local demo tranche unless a later accepted requirement changes the gate.

## Current branches / integration path

Both repositories use:

`codex/task-closeout-001-tranche-completion`

Integration PRs:

- customer PR #13 -> `master`
- dashboard PR #12 -> `main`

Both remain draft while closeout is `PARTIAL`. Earlier stacked PRs must not be merged individually once the integration PRs are ready; final closeout will reconcile/supersede them.

## Remaining gate

Before merge:

1. make Android release builds reproducible from committed Git;
2. finish Dashboard authoritative POS/order-board frontend integration;
3. prove customer placement -> dashboard fulfilment transition -> customer authorized status refresh;
4. rerun complete client/security checks;
5. synchronize final shared docs after both implementation heads settle;
6. verify clean diffs and PR mergeability.

Do not start the next business-domain feature until these closeout gates are resolved.
