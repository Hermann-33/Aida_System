# Active Context

**As of:** 2026-08-21
**Current task:** `TASK-SCHEDULED-OPS-001 — scheduled-order operational queue + live staff POS entry`
**Current verdict:** COMPLETE — shared Supabase preparation authority is live and verified; Dashboard/POS scheduled-workload and staff-entry integration is complete; executable Dashboard gates pass; affected canonical documentation is reconciled across both repositories.

## Current product reality

AIDA Café still uses one Supabase backend for the Flutter customer app and React Dashboard/Admin/POS. The trusted implemented tranche remains Auth/member provisioning, protected employee/Admin sessions, shared catalogue, authoritative quote/order/scheduling, customer order history/status, Dashboard order BFF/queue/status transitions, and the verified customer redesign.

TASK-SCHEDULED-OPS-001 closed two operational gaps discovered after real scheduled orders were placed:

1. future scheduled orders were persisted correctly but mixed into one flat Orders table with no trusted future/due/overdue distinction;
2. `staff.nora.demo@aida.test` authenticated successfully, but the live POS entry path then blocked on terminal/shift API state that is not implemented in the accepted backend.

Detailed task contract/handoff:

- `docs/context/SCHEDULED_ORDER_OPERATIONS_2026-08-20.md`

## Shared backend change — complete and live

Applied migration:

`20260820151421_add_scheduled_order_preparation_window`

Canonical customer-repository migration:

`supabase/migrations/20260820151421_add_scheduled_order_preparation_window.sql`

The backend now owns:

- `order_schedule_settings.preparation_lead_minutes` (default/current 15);
- immutable per-order `orders.prepare_at` for scheduled orders;
- `prepareAt`, `serverNow`, and `scheduleState` on authorized order snapshots;
- `scheduleState = future | due | overdue | null`, derived from server time without changing persisted fulfilment status.

`preparationLeadMinutes` is distinct from customer `minimumLeadMinutes` and is constrained to `0 <= preparationLeadMinutes <= minimumLeadMinutes`.

New scheduled placement snapshots:

`prepareAt = requestedPickupAt - preparationLeadMinutes`.

A later policy edit does not rewrite an already accepted order's `prepareAt`.

No timer or migration auto-transitions `scheduled -> preparing`. Staff action remains authoritative through the existing versioned `transition_order_status` boundary.

## Live evidence

Current live policy:

```text
timezone                 Asia/Kuala_Lumpur
schedule_enabled         true
minimum_lead_minutes     15
preparation_lead_minutes 15
slot_interval_minutes    15
maximum_advance_days     7
```

Existing scheduled orders were backfilled without changing status. The previously stale live orders now classify operationally as `overdue`:

- `100007`
- `100008`
- `100009`

This exposes the exception to staff clients while preserving the persisted `scheduled` state until an authorized staff transition occurs.

Focused backend regression:

`supabase/tests/scheduled_order_operations_integration.sql`

Result: PASS transactionally against live Supabase; synthetic data and temporary policy changes rolled back.

The existing scheduled lifecycle was rechecked after migration and remains valid: `scheduled -> preparing -> ready -> completed` through the versioned trusted status boundary.

Supabase security advisor remains unchanged with one WARN: `auth_leaked_password_protection` / Leaked Password Protection Disabled. Performance advisor findings are INFO-only unused indexes on the small dataset.

## Staff login resolution

The Nora demo staff identity is confirmed, active, trusted `app_role=staff`, and successfully authenticates. The password/Auth boundary was never the failure.

The pre-task failure was post-login Dashboard flow:

- live `/employee` checked terminal enrolment APIs;
- `/pos` checked terminal/current-shift APIs;
- those terminal/shift routes were not mounted by the current Dashboard BFF;
- live Supabase has no authoritative branch/terminal/sales-point/shift schema.

The completed Dashboard implementation does not fabricate hardcoded live terminal/branch/shift truth. Until a separate trusted terminal/branch/shift task exists, the accepted single-café/global-staff order scope allows authenticated staff to use live Sale + Orders without those deferred domains blocking entry. Preview terminal/shift simulation remains preview-only.

## Dashboard implementation — complete

Matching branch:

`codex/task-scheduled-ops-001-prep-queue`

Codex implementation commit:

`b7b73fe8517625264a7e3f19e59d24325c1cfcc1`

Implemented outcomes:

- strict consumption of `preparationLeadMinutes`, `prepareAt`, `serverNow`, `scheduleState`;
- Orders rail uses `Active | Scheduled | Ready | History` workloads;
- future scheduled orders stay in Scheduled;
- `due` and `overdue` scheduled orders surface in Active while persisted status remains `scheduled`;
- overdue orders promote ahead of normal active work;
- **Start preparing** explicitly performs the existing legal versioned transition;
- staff live login via `/employee` reaches `/pos` without nonexistent terminal/shift prerequisites;
- Admin login remains Admin/Owner-only;
- preview fixtures never become live authority.

`orderClient.ts` rejects malformed/missing preparation/schedule projection fields rather than manufacturing plausible defaults. The workload projection consumes backend classification and does not use the workstation clock as business authority or auto-mutate scheduled orders.

Live `/employee` authentication is independent of terminal enrolment. Live `/pos` enters the accepted global single-café Sale/Orders workspace without terminal/current-shift calls; terminal, shift and preview-member rails remain preview-only. Staff permission remains POS-only and `/admin/login` remains Admin/Owner-only.

The implementation preserves the existing AIDA Dashboard/POS design system from `src/styles/tokens.css`, Tailwind/shadcn components, Playfair Display + Plus Jakarta Sans, existing rails/cards/status patterns and accessibility behavior.

## Completion evidence

Backend:

- live migration applied and migration history reconciled;
- focused scheduled-order operations SQL regression: PASS;
- existing scheduled lifecycle regression: PASS;
- security advisor: no new finding.

Dashboard evidence on 2026-08-21:

- `npm ci`: PASS, 0 vulnerabilities;
- lint: PASS with two existing shadcn Fast Refresh warnings;
- typecheck: PASS;
- Vitest: PASS — 27 files / 120 tests;
- production build: PASS with existing large-chunk advisory only;
- Playwright: PASS — 10/10;
- desktop/mobile visual QA: PASS;
- scheduled-workload browser console: no errors;
- `git diff --check`: PASS;
- secret/browser-token scans: PASS.

Final commit inspection confirms the Dashboard delta is bounded to the required workload/client, POS staff-entry/session presentation, tests/E2E, styling and documentation surfaces. Affected canonical mirrored documents have been reconciled into the customer task branch.

No PR has been created or merged for this task. Terminal/branch/sales-point/shift authority and hosted production deployment remain explicitly deferred.
