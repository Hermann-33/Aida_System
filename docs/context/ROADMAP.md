# Roadmap

Updated: 2026-08-14

## Completed / validated foundations

The following scoped foundations are implemented and no longer blocked by the old zero-identity/device assumptions:

- governance/import workflow foundations;
- Supabase identity/member schema and trusted role foundation;
- customer Supabase Auth integration;
- trusted customer profile/member provisioning and member-code authority;
- protected Admin/owner member directory;
- same-origin HttpOnly dashboard employee/Admin session boundary;
- shared catalogue authority, Admin mutation and customer/POS reads;
- catalogue revision/audit invalidation model;
- TASK-AUTH-005 preview/live Admin session-loop regression fix;
- Android release INTERNET permission/runtime networking fix;
- authoritative order/scheduling backend;
- customer authoritative quote/place/history/status integration;
- dashboard order BFF/API backend.

Physical/manual validation now proves:

- installed Android signup -> trusted member -> Dashboard Members;
- real Owner catalogue price mutation -> installed customer app refresh.

See `docs/context/CLOSEOUT_EVIDENCE_2026-08-14.md`.

## Current task — TASK-CLOSEOUT-001

Formal tranche status: `PARTIAL` until the remaining engineering/merge gates close.

### 1. Android build reproducibility

The runtime networking fix is validated, but the release APK must build from committed Git in a clean checkout/worktree without local stash/toolchain overrides. Closeout must align AGP/Gradle/Kotlin with Flutter and the resolved AndroidX dependency set.

### 2. Dashboard authoritative order frontend

The existing order BFF must become the production/live React order authority for:

- POS authoritative quote;
- ASAP/scheduled fulfilment selection;
- idempotent POS placement;
- explicit Pay-at-counter/unpaid semantics;
- live order queue;
- versioned legal status transitions;
- short BFF polling/refetch without exposing employee JWTs.

Preview transactions/local receipts must not remain a fallback source of trusted live order state.

### 3. Cross-client order E2E

Prove:

customer authoritative placement
-> persisted order
-> Dashboard queue
-> staff preparing/ready/completed transitions
-> customer owner-scoped authorized refresh/status.

### 4. Final validation / documentation / merge

Run complete Flutter and Dashboard suites, canonical backend/security checks, secret scans, mirrored-doc reconciliation and final diff/PR mergeability review.

## Deployment

A historical Vercel project/deployment exists, but hosted runtime configuration was not completed. For the currently accepted local-PC + cloud-Supabase + installed-phone demo workflow this is **DEFERRED operational work**, not a claim of production deployment and not a closeout blocker unless a later accepted requirement changes the gate.

## After tranche closeout

Do not start these until TASK-CLOSEOUT-001 is complete and merged:

1. loyalty earning/history/redemption;
2. trusted payment/tender/refund lifecycle;
3. sales KPIs/reporting from authoritative orders/payments;
4. inventory depletion and operational stock flows;
5. promotions/discount engine;
6. branch-aware employee/order scope and branch hours/capacity;
7. tax/accounting integrations;
8. delivery.

These domains must consume trusted order/payment state rather than client totals or preview fixtures.
