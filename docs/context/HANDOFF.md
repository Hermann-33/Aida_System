# Current Handoff

Updated: 2026-08-20

## Task

`TASK-SCHEDULED-OPS-001 — scheduled-order operational queue + live staff POS entry`

**Verdict:** PARTIAL.

Shared Supabase preparation authority is implemented live, migration history is reconciled with the canonical customer repository, and focused SQL regression passes. Dashboard/POS source changes are intentionally pending for Codex on the matching branch.

Detailed implementation contract:

`docs/context/SCHEDULED_ORDER_OPERATIONS_2026-08-20.md`

## Starting state

Customer default `master` began this task at `6e04ac5fdddede5ac4dc5bb22bb0f6eabef7d8c6`.

Dashboard default `main` began this task at `66c9209f656a35d13adcb467a7accaea970abe68`.

Matching branches:

`codex/task-scheduled-ops-001-prep-queue`

The pre-task Dashboard Orders rail used one flat persisted queue. Scheduled orders were real backend rows, but there was no trusted distinction between future scheduled workload, orders due to begin preparation, and orders whose pickup time had already passed.

The staff demo account `staff.nora.demo@aida.test` was verified live as confirmed/active `app_role=staff`; Auth succeeds. Its apparent login failure is caused after Auth because live employee/POS screens require terminal and shift APIs/schema that are not implemented in the accepted backend.

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
- `get_ordering_policy()` and Admin/Owner `save_ordering_policy()` now expose/accept `preparationLeadMinutes`;
- no automatic `scheduled -> preparing` transition was introduced.

Current live policy remains Malaysia timezone, scheduled enabled, minimum lead 15, preparation lead 15, slot interval 15, horizon 7 days.

Live orders `100007`, `100008`, and `100009` now classify as `overdue` while remaining persisted `scheduled` until staff acts.

## Verification

Focused canonical regression added:

`supabase/tests/scheduled_order_operations_integration.sql`

Live transactional run: PASS.

It proves schema/policy bounds, scheduled `prepareAt`, `scheduleState`, idempotency preserving prepare time, Admin policy mutation, rejection of invalid preparation lead, new scheduled POS placement using current policy, and non-rewriting of existing orders after policy changes.

Security advisor: unchanged one WARN only — `auth_leaked_password_protection` / Leaked Password Protection Disabled.

Performance advisor: INFO-only unused-index notices; the new scheduled preparation index is unused on the tiny current dataset, which is expected.

## Dashboard implementation still required

Do not edit the shared backend contract again unless the current live fields prove insufficient.

Codex must implement on the existing Dashboard task branch:

1. Parse/use `preparationLeadMinutes`, `prepareAt`, `serverNow`, `scheduleState`.
2. Replace the flat Orders workload with `Active | Scheduled | Ready | History` or an equivalent semantic structure.
3. Keep `future` scheduled orders out of Active.
4. Put `due` and `overdue` scheduled orders in Active while persisted status remains `scheduled`.
5. Promote overdue work before ordinary active orders.
6. Keep **Start preparing** as the explicit existing versioned `scheduled -> preparing` transition.
7. Repair live staff entry so authenticated `staff` reaches `/pos` without nonexistent live terminal/shift authority blocking Sale/Orders.
8. Keep `/admin/login` Admin/Owner-only.
9. Preserve preview-only terminal/shift simulation without promoting it to live truth.
10. Preserve the existing AIDA Dashboard/POS visual system and accessibility patterns.

## Visual constraints

Use existing `src/styles/tokens.css`, Tailwind/shadcn primitives, and current POS components/patterns. Preserve the Rose palette, Playfair Display headings, Plus Jakarta Sans UI/body, existing rail/cards/tables/status pills, spacing/radii/touch targets, focus treatment and reduced-motion behavior.

Semantic colors already exist:

- normal/info: burgundy/blush;
- due/warning: `--aida-warning`;
- overdue/error: `--aida-error`;
- ready/success: `--aida-success`.

Do not introduce a new dashboard theme or arbitrary visual language.

## Required closeout checks

Dashboard minimum:

```text
npm run lint
npm run typecheck
npm test
npm run build
```

Run relevant browser/E2E verification and add focused regressions for scheduled queue classification and staff login/route behavior.

Then inspect and synchronize the canonical mirrored docs listed in `docs/context/SCHEDULED_ORDER_OPERATIONS_2026-08-20.md`.

Do not mark the task COMPLETE until Dashboard source integration, executable checks and mirrored documentation pass.
