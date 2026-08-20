# Active Context

**As of:** 2026-08-20
**Current task:** `TASK-SCHEDULED-OPS-001 — scheduled-order operational queue + live staff POS entry`
**Current verdict:** PARTIAL — shared Supabase preparation authority is implemented and verified; Dashboard/POS source changes remain pending on the matching task branch.

## Current product reality

AIDA Café still uses one Supabase backend for the Flutter customer app and React Dashboard/Admin/POS. The trusted implemented tranche remains Auth/member provisioning, protected employee/Admin sessions, shared catalogue, authoritative quote/order/scheduling, customer order history/status, Dashboard order BFF/queue/status transitions, and the verified customer redesign.

TASK-SCHEDULED-OPS-001 addresses two operational gaps discovered after real scheduled orders were placed:

1. future scheduled orders were persisted correctly but mixed into one flat Orders table with no trusted future/due/overdue distinction;
2. `staff.nora.demo@aida.test` authenticates successfully, but the live POS entry path then blocks on terminal/shift API state that is not implemented in the accepted backend.

Detailed task contract/handoff:

- `docs/context/SCHEDULED_ORDER_OPERATIONS_2026-08-20.md`

## Shared backend change — implemented live

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

Supabase security advisor remains unchanged with one WARN: `auth_leaked_password_protection` / Leaked Password Protection Disabled. Performance advisor findings are INFO-only unused indexes on the small dataset.

## Staff login diagnosis

The Nora demo staff identity is confirmed, active, trusted `app_role=staff`, and has successfully authenticated. The password/Auth boundary is not the failure.

The failure is post-login Dashboard flow:

- live `/employee` checks terminal enrolment APIs;
- `/pos` checks terminal/current-shift APIs;
- those terminal/shift routes are not mounted by the current Dashboard BFF;
- live Supabase has no authoritative branch/terminal/sales-point/shift schema.

Do not fabricate hardcoded live terminal/branch/shift truth in React.

Until a separate trusted terminal/branch/shift task exists, the accepted single-café/global-staff order scope should allow authenticated staff to use live Sale + Orders without those deferred domains blocking entry. Preview terminal/shift simulation may remain preview-only.

## Required Dashboard implementation

Matching branch:

`codex/task-scheduled-ops-001-prep-queue`

Dashboard source changes are intentionally delegated to Codex per user instruction.

Required outcomes:

- consume `preparationLeadMinutes`, `prepareAt`, `serverNow`, `scheduleState`;
- Orders rail becomes `Active | Scheduled | Ready | History` (or semantically equivalent);
- future scheduled orders stay in Scheduled;
- `due` and `overdue` scheduled orders surface in Active while persisted status remains `scheduled`;
- overdue orders sort/promote ahead of normal active work;
- **Start preparing** explicitly performs the existing legal versioned transition;
- staff live login via `/employee` reaches `/pos` without nonexistent terminal/shift prerequisites;
- Admin login remains Admin/Owner-only;
- preview fixtures never become live authority.

Visual work must reuse the existing AIDA Dashboard/POS design system from `src/styles/tokens.css`, existing Tailwind/shadcn components, Playfair Display + Plus Jakarta Sans, current rails/cards/tables/status-pill patterns and accessibility behavior. No second palette/design language.

## Completion gate

Do not mark this task COMPLETE until Dashboard source integration passes at minimum:

```text
npm run lint
npm run typecheck
npm test
npm run build
```

plus relevant browser/E2E verification, focused scheduled-order/staff-login regressions, final diff review, and mirrored documentation reconciliation.
