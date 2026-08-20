# Current Handoff

Updated: 2026-08-21

## Task

`TASK-SCHEDULED-OPS-001 — scheduled-order operational queue + live staff POS entry`

**Verdict:** COMPLETE.

Shared Supabase preparation authority is implemented live, migration history is reconciled with the canonical customer repository, the focused SQL regression passes, the Dashboard/POS implementation is complete on the matching task branch, executable Dashboard gates pass, and the affected mirrored documentation has been reconciled across both repositories.

Detailed implementation contract:

`docs/context/SCHEDULED_ORDER_OPERATIONS_2026-08-20.md`

## Starting state

Customer default `master` began this task at `6e04ac5fdddede5ac4dc5bb22bb0f6eabef7d8c6`.

Dashboard default `main` began this task at `66c9209f656a35d13adcb467a7accaea970abe68`.

Matching branches:

`codex/task-scheduled-ops-001-prep-queue`

The pre-task Dashboard Orders rail used one flat persisted queue. Scheduled orders were real backend rows, but there was no trusted distinction between future scheduled workload, orders due to begin preparation, and orders whose pickup time had already passed.

The staff demo account `staff.nora.demo@aida.test` was verified live as confirmed/active `app_role=staff`; Auth succeeds. Its apparent login failure was caused after Auth because live employee/POS screens required terminal and shift APIs/schema that are not implemented in the accepted backend.

## Backend implementation — complete

Applied live migration:

`20260820151421_add_scheduled_order_preparation_window`

Canonical migration file:

`supabase/migrations/20260820151421_add_scheduled_order_preparation_window.sql`

Changes:

- `order_schedule_settings.preparation_lead_minutes` default/current 15;
- invariant `0 <= preparation_lead_minutes <= minimum_lead_minutes`;
- `orders.prepare_at` for scheduled orders;
- existing scheduled orders backfilled with current preparation lead;
- `prepare_at` protected as immutable placement-time schedule authority;
- order snapshots add `prepareAt`, `serverNow`, `scheduleState`;
- `scheduleState` is server-derived `future | due | overdue | null` and never mutates persisted status;
- `get_ordering_policy()` and Admin/Owner `save_ordering_policy()` expose/accept `preparationLeadMinutes`;
- no automatic `scheduled -> preparing` transition was introduced.

Current live policy remains Malaysia timezone, scheduled enabled, minimum lead 15, preparation lead 15, slot interval 15, horizon 7 days.

Live orders `100007`, `100008`, and `100009` classify as `overdue` while remaining persisted `scheduled` until staff acts.

## Backend verification

Focused canonical regression:

`supabase/tests/scheduled_order_operations_integration.sql`

Live transactional run: PASS.

It proves schema/policy bounds, scheduled `prepareAt`, `scheduleState`, idempotency preserving prepare time, Admin policy mutation, rejection of invalid preparation lead, new scheduled POS placement using current policy, and non-rewriting of existing orders after policy changes.

The pre-existing scheduled lifecycle was also rechecked after migration: `scheduled -> preparing -> ready -> completed` remains valid through the versioned status boundary.

Security advisor: unchanged one WARN only — `auth_leaked_password_protection` / Leaked Password Protection Disabled.

Performance advisor: INFO-only unused-index notices; the new scheduled preparation index is unused on the tiny current dataset, which is expected.

## Dashboard implementation — complete

Codex completed the Dashboard source work from prepared branch head `855424c` to implementation commit `b7b73fe8517625264a7e3f19e59d24325c1cfcc1`.

The Dashboard now strictly parses the trusted preparation fields, presents Active/Scheduled/Ready/History workloads, promotes overdue and due scheduled work without changing persisted status, and keeps **Start preparing** on the existing versioned mutation. Conflict responses invalidate both queue and selected detail before staff may retry.

Live staff authentication reaches `/pos` without terminal enrolment/current-terminal/current-shift requests. Live Sale/Orders operates in the accepted global single-café scope. Terminal, shift and preview-member rails remain isolated to preview mode; staff is still denied Admin and Admin/Owner behavior is unchanged.

No Supabase migration, customer runtime source, RLS, service-role path, browser employee bearer-token persistence or fabricated live terminal/branch/shift authority was introduced by the Dashboard change.

## Dashboard verification

Codex closeout evidence on 2026-08-21:

- `npm ci`: PASS, 0 vulnerabilities;
- lint: PASS with two existing shadcn Fast Refresh warnings;
- typecheck: PASS;
- Vitest: PASS — 27 files / 120 tests;
- production build: PASS with the existing large-chunk advisory only;
- Playwright: PASS — 10/10;
- desktop/mobile visual QA: PASS;
- scheduled-workload browser console: no errors;
- `git diff --check`: PASS;
- secret/browser-token scans: PASS.

Final implementation commit inspection confirmed the 31-file Dashboard delta is bounded to order workload/client integration, POS staff-entry/session presentation, focused tests/E2E, styling, and documentation. No Dashboard backend-authority expansion was present.

## Visual constraints preserved

The implementation reuses existing `src/styles/tokens.css`, Tailwind/shadcn primitives, and current POS components/patterns: Rose palette, Playfair Display headings, Plus Jakarta Sans UI/body, existing rails/cards/status treatments, spacing/radii/touch targets, focus treatment and reduced-motion behavior.

Semantic urgency remains explicit in text as well as color; no second dashboard theme was introduced.

## Cross-repository closeout

The affected canonical mirrored documents were reconciled from the completed Dashboard implementation back into the customer repository on the matching task branch, with repository-local executable backend migration/tests remaining customer-only.

Terminal/branch/sales-point/shift authority remains intentionally deferred. Hosted production deployment also remains deferred and is not a blocker for this task.

No PR was created or merged as part of this task closeout.
