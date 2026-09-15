# Active Context

**As of:** 2026-09-16  
**Current boundary:** Phase 8 — reporting, accounting and audit  
**Current verdict:** `PARTIAL` — active implementation. Phase 7 is `COMPLETE`; Phase 9–10 remain frozen.

## Product topology

- customer/backend: `Hermann-33/Aida_System`
- Dashboard/Admin/POS: `Hermann-33/Aida_System-Dashboard`
- shared Supabase project: `Aida System`, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`
- canonical executable migrations: `Hermann-33/Aida_System/supabase/migrations/` only

## Completed authority through Phase 7

```text
Phase 1 COMPLETE  branch -> sales point -> terminal -> employee branch scope -> POS attribution
Phase 2 COMPLETE  terminal + employee -> shift -> POS order / cash ledger
Phase 3 COMPLETE  customer -> privacy/account deletion -> anonymized retained history
Phase 4 COMPLETE  branch calendar/policy -> pickup capacity -> authoritative quote/place
Phase 5 COMPLETE  recipe -> branch inventory -> transactional depletion/reversal
Phase 6 COMPLETE  member -> loyalty -> reward/voucher -> authoritative voucher discount/consumption
Phase 7 COMPLETE  promotion config -> server evaluation -> locked placement -> immutable promotion snapshots
Phase 8 PARTIAL   trusted Phase 1–7 facts -> read-only operational reports/audit projections
```

## Phase 7 closure baseline

```text
Aida_System             8f37d838fc4659a1e1d3a5dcae43887a796ca2be
Aida_System-Dashboard   c70fc8cd39f447eb68a0470e657d121db5c0f90f
Backend database audit #234   COMPLETE
Customer release audit #314   COMPLETE
Dashboard CI #149             COMPLETE
```

The Phase 7 live promotion deployment remains valid. Do not rewrite its migration-service timestamps to match canonical repository filenames.

## Phase 8 authority boundary

Phase 8 replaces fixture-derived production reports with source-backed operational reporting and reconciliation. It must remain read-only with respect to Phase 1–7 authority.

Trusted report inputs include accepted order/commercial snapshots, order events, topology attribution, shift/cash ledgers, loyalty ledgers/application snapshots, promotion applications and inventory movement ledgers.

Production reports must not invent:

- tax/VAT/SST or statutory accounting treatment;
- general-ledger entries or financial statements;
- profit/COGS without trusted historical cost basis;
- processor capture/refund/settlement truth before Phase 9;
- synthetic production trends, fake refund reasons or fixture payment facts.

Branch/time reporting must use authoritative scope and timezone semantics. Customer PII is not part of the reporting contract unless explicitly necessary and authorized.

## Dashboard boundary

The current production-reporting targets are:

- `AdminOverviewPage`;
- `AdminSalesPerformancePage`;
- `AdminTransactionsPage`;
- `AdminAuditPage`.

Outside preview mode these pages must move to same-origin BFF reporting endpoints forwarding the caller JWT to narrow Supabase reporting RPCs. Preview remains fixture-only and must not contact privileged reporting endpoints.

## Phase 8 branch state

```text
Aida_System             codex/phase-8-reporting-accounting-audit
Aida_System-Dashboard   codex/phase-8-reporting-accounting-audit
```

Phase 8 implementation starts from the exact Phase 7 closure heads above.

## Live backend rule

No Phase 8 migration is considered deployed merely because it exists in the repository. Deploy only after local/CI regression coverage is green, then verify live migration history, grants/schema and fresh Supabase security/performance advisors.

## PR / merge governance

Phase 7 PRs remain draft/unmerged. Phase 8 work also remains draft/unmerged until explicitly authorized. Completion of Phase 8 does not authorize merge or Phase 9.

## Next action

Implement the Phase 8 read-only reporting/audit RPC contract and blocking SQL regression coverage first. Only after that contract is green should Dashboard production reporting pages be wired to it.