# Phase 8 Validation Notes — 2026-09-16

Status: `PARTIAL`

## Backend authority and regression status

The first clean Phase 8 backend database audit reached the new reporting/reconciliation regression after all Phase 1–7 SQL regressions passed, then failed because the clean canonical database intentionally contains no active inventory administration rows. The reporting test attempted to resolve an inventory item that did not exist.

Remediation and validation:

- added `supabase/tests/reporting_accounting_audit_fixture.sql` as a disposable local-CI fixture;
- the fixture seeds one synthetic inventory item only inside the ephemeral local Supabase database;
- the actual Phase 8 inventory source fact remains authored through the trusted Phase 5 `record_inventory_movement(...)` RPC;
- `.github/workflows/backend-database-audit.yml` runs the fixture immediately before the Phase 8 reporting regression;
- no production migration, live Supabase data, authority boundary, or Phase 1–7 behavior was changed by this test-fixture correction;
- Backend database audit #239 passed the complete Phase 1–8 regression chain at backend head `273898f5835b19819153e6fa75ee6026ca9c6aea`;
- the later exact Phase 8 backend documentation head passed Backend database audit #243.

The canonical Phase 8 migration is `supabase/migrations/20260916100000_create_reporting_audit_authority.sql`. It exposes caller-bound read-only Admin/Owner summary, transaction and source-backed audit RPCs. It does not claim statutory accounting, processor settlement or refund truth.

## Dashboard reporting implementation

Earlier CI findings:

- Dashboard CI #154 failed at Typecheck after Lint passed because production Phase 8 reporting BFF handlers were not mounted in the shared Vite dev/preview BFF router;
- `server/viteBffPlugin.ts` now mounts the reporting summary, transaction and audit handlers at the same same-origin paths used by production;
- Dashboard CI #156 at head `d2d7b35b31b8838d8aee2d0dbaa97ffaff64dd52` then failed only because `reportingClient.test.ts` inferred its `fetchMock` as a zero-argument function while the test inspected recorded call arguments;
- Dashboard commit `ec2cf3d04ecaec777d2498439943ceb385bbcdd3` fixes that test-only typing defect.

Current implementation batch:

- `13cece551c0dc4916714795801d95f06f0b79519` — strict typed Phase 8 summary/transaction/audit parser contract;
- `782d9bac687241f5c298cf1ec73930f2c56a74e7` — Transactions production page moved from fixture authority to paginated source-backed transaction reporting; refund values are explicitly unavailable until Phase 9;
- `bbedd3be563be946cd94920c6735b53386535168` — Audit production page moved from static invented rows to source-backed audit events and explicit coverage notes;
- `59013f77720735d8bffb06ba1f1c5925fbcfba96` — Executive Dashboard moved to authoritative accepted-order-value, discount, paid-POS-cash, shift and branch/sales-point reporting;
- `39f35b5fb6918f6181c674aec2975009d01fd5de` — Sales & Performance moved to authoritative summary/product/branch reporting and removed production claims for synthetic payment mix, refunds and staff leaderboard data;
- `1ed51f6bc7826f26630a61f1ec675f85190348f8` — reporting client parser tests now use a valid strict summary contract and fail closed on malformed money/pagination/coverage;
- `404d60c41a31826a5605edd3310177c772198cf3` — dedicated Playwright preview-isolation regression visits all four Phase 8 reporting surfaces and asserts zero `/api/v1/admin/reporting/*` requests;
- `c9355880395d5c087df7e30874eab8601a95336e` — the new Phase 8 preview spec is included in the blocking `test:e2e:preview` CI command.

Dashboard CI #170 on documentation head `159512205bfcc4b18b0f3389ea1717e37f6aa17b` passed Lint and then failed Typecheck because the preceding `package.json` rewrite had accidentally omitted the existing `@vitejs/plugin-react` devDependency. This was a validation/configuration regression, not a reporting-contract failure.

Remediation after #170:

- `bfd321a9510e556f78368669ab1a507e7f4e9020` restores `@vitejs/plugin-react` at the prior `^6.0.3` constraint while retaining the Phase 8 preview E2E command;
- `1abda7d8f121453956024e2a5eb0827c1cacac37` stabilizes the Audit page source-row memoization and removes the new hook-dependency warning introduced by the reporting conversion;
- a fresh exact-head Dashboard CI pass is required before the reporting UI batch is accepted.

Production reporting semantics are intentionally conservative:

- commercial totals are **accepted order value**, not processor settlement;
- voucher and promotion discounts remain separate;
- paid POS cash is reported only from persisted paid-cash facts;
- processor authorization/capture/settlement and refund amounts remain unavailable until Phase 9;
- preview fixtures remain presentation-only and are prohibited from privileged reporting requests.

## Remaining Phase 8 closure gates

Phase 8 remains `PARTIAL` until:

1. the current Dashboard reporting batch passes exact-head lint/typecheck/unit/browser/build CI;
2. affected backend/customer exact-head gates remain green after final documentation changes;
3. the canonical Phase 8 migration is deployed to live AIDA Supabase;
4. live migration/function/grant state is verified;
5. fresh live security and performance advisors are reviewed and any Phase 8-created actionable findings are resolved;
6. synchronized closeout evidence is written in both repositories;
7. the required Phase 8 independent/Astra audit boundary is completed or explicitly accepted before Phase 9.

Phase 9 and Phase 10 remain frozen until Phase 8 reaches `COMPLETE`.
