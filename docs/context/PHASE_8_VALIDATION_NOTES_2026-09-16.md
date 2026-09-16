# Phase 8 Validation Notes — 2026-09-16

Status: `PARTIAL`

The first clean Phase 8 backend database audit reached the new reporting/reconciliation regression after all Phase 1–7 SQL regressions passed, then failed because the clean canonical database intentionally contains no active inventory administration rows. The reporting test attempted to resolve an inventory item that did not exist.

Backend remediation and validation:

- added `supabase/tests/reporting_accounting_audit_fixture.sql` as a disposable local-CI fixture;
- the fixture seeds one synthetic inventory item only inside the ephemeral local Supabase database;
- the actual Phase 8 inventory source fact remains authored through the trusted Phase 5 `record_inventory_movement(...)` RPC;
- `.github/workflows/backend-database-audit.yml` runs the fixture immediately before the Phase 8 reporting regression;
- no production migration, live Supabase data, authority boundary, or Phase 1–7 behavior was changed by this test-fixture correction;
- clean Backend database audit #239 passed the complete Phase 1–8 regression chain at backend head `273898f5835b19819153e6fa75ee6026ca9c6aea`;
- the later exact Phase 8 backend documentation head also passed Backend database audit #243.

Dashboard validation and implementation:

- Dashboard CI #154 failed at Typecheck after Lint passed; inspection found the reporting BFF handlers were not mounted in the shared Vite dev/preview BFF router;
- `server/viteBffPlugin.ts` now mounts the reporting summary, transaction and audit handlers at the same same-origin paths used by production;
- Dashboard CI #156 at head `d2d7b35b31b8838d8aee2d0dbaa97ffaff64dd52` then reached Typecheck and failed only because `reportingClient.test.ts` inferred its `fetchMock` as a zero-argument function while the test inspected the first two recorded call arguments;
- the test mock is explicitly declared with `(RequestInfo | URL, RequestInit?)` parameters in Dashboard commit `ec2cf3d04ecaec777d2498439943ceb385bbcdd3`;
- `src/features/reporting/reportingClient.ts` is now a strict typed parser contract for Phase 8 summary, transaction and audit responses in Dashboard commit `13cece551c0dc4916714795801d95f06f0b79519`; it validates the commercial-value semantics, voucher/promotion components, shift/cash values, transaction pagination/details and audit coverage/items before UI consumption;
- no browser-side pricing, settlement, refund or reporting authority is introduced; the client only validates and presents caller-bound BFF/RPC output;
- exact-head Dashboard CI must pass after the production reporting pages are converted.

Phase 8 remains `PARTIAL` until the four production reporting pages replace fixture authority, exact-head Dashboard validation is green, the canonical Phase 8 migration is deployed live, fresh security/performance advisors are checked, synchronized closeout evidence is recorded, and the Phase 8 audit boundary is accepted before Phase 9.

Phase 9 and Phase 10 remain blocked by Phase 8 completion.
