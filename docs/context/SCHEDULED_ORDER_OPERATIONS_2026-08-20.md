# Scheduled Order Operations — 2026-08-20

**Task:** `TASK-SCHEDULED-OPS-001`

**Current verdict:** PARTIAL — shared Supabase preparation authority is implemented and verified; Dashboard/POS integration and the live staff-entry repair remain to be implemented on the matching Dashboard branch.

## Problem

AIDA already accepts and persists scheduled customer/POS orders, but the Dashboard Orders rail currently mixes future scheduled work into one flat queue. Persisted `scheduled` status by itself does not tell staff whether an order is still future work, is due to start preparation, or is already late. Historic live orders `100007`, `100008`, and `100009` demonstrated the failure mode: their fulfilment state remained `scheduled` after their pickup time, with no operational exception classification.

The staff demo account `staff.nora.demo@aida.test` is a valid confirmed Supabase Auth user with trusted `app_role=staff` and is not disabled/banned/deleted. Authentication succeeds. The apparent login failure happens after Auth because the live POS screens require terminal/shift API state that does not exist in the accepted live backend. Current Supabase has no trusted branch/terminal/sales-point/shift tables, and the Dashboard Vite BFF does not mount the terminal/shift routes referenced by the live screens.

## Operational model

Industry practice across established restaurant POS/KDS systems separates **future workload** from **work due now**. A future order should be visible to operations immediately, but it should not compete with tickets that should be made now. When the preparation window arrives, it becomes operationally due; that does not prove a staff member has actually started making it.

AIDA therefore keeps fulfilment state and operational schedule state separate:

```text
persisted status = scheduled
         |
         +-- scheduleState=future   -> visible in Scheduled/Future
         +-- scheduleState=due      -> visible in Active / due for prep
         +-- scheduleState=overdue  -> visible at highest urgency

staff explicitly presses Start preparing
         -> persisted status becomes preparing
```

There is no database timer that silently changes `scheduled -> preparing`. Staff action remains authoritative for the fulfilment transition.

## Live backend implementation

Applied Supabase migration:

`20260820151421_add_scheduled_order_preparation_window`

Canonical repository file:

`Aida_System/supabase/migrations/20260820151421_add_scheduled_order_preparation_window.sql`

### Ordering policy

`order_schedule_settings` now includes:

```text
preparation_lead_minutes integer default 15
```

This is distinct from `minimum_lead_minutes`:

- `minimumLeadMinutes` = earliest pickup time a customer may request.
- `preparationLeadMinutes` = operational time before pickup when staff should begin preparation.

Invariant:

```text
0 <= preparationLeadMinutes <= minimumLeadMinutes
```

Current live policy:

```text
timezone: Asia/Kuala_Lumpur
scheduleEnabled: true
minimumLeadMinutes: 15
preparationLeadMinutes: 15
slotIntervalMinutes: 15
maximumAdvanceDays: 7
```

`get_ordering_policy()` and `save_ordering_policy(jsonb)` now expose/accept `preparationLeadMinutes`. Only Admin/Owner may mutate policy through the existing trusted boundary.

### Per-order preparation authority

`orders` now includes:

```text
prepare_at timestamptz
```

For a new scheduled order:

```text
prepareAt = requestedPickupAt - preparationLeadMinutes
```

`prepare_at` is snapshotted at placement and protected by the existing commercial-field immutability trigger. A later policy change does not rewrite already accepted orders.

ASAP orders keep `prepare_at = null`.

Existing scheduled orders were backfilled from the current policy without changing their persisted fulfilment status.

### Order snapshot contract

Authorized order snapshots now additionally expose:

```text
prepareAt
serverNow
scheduleState = future | due | overdue | null
```

For `fulfillmentType=scheduled` and persisted `status=scheduled`:

```text
requestedPickupAt < serverNow  -> overdue
prepareAt <= serverNow          -> due
otherwise                       -> future
```

For non-scheduled or already-transitioned orders, `scheduleState` is null.

The Dashboard must use `scheduleState` returned by the backend for authoritative queue classification. It must not decide future/due/overdue from the workstation clock alone. Client time may be used only for presentation countdown text between server refreshes.

### Live proof

After migration, the live stale orders classify as:

```text
#100008  pickup 2026-08-18 16:45 MYT  prepare 16:30  overdue
#100007  pickup 2026-08-18 18:00 MYT  prepare 17:45  overdue
#100009  pickup 2026-08-20 22:30 MYT  prepare 22:15  overdue
```

No order status was fabricated or automatically advanced.

## Backend verification

`supabase/tests/scheduled_order_operations_integration.sql` covers:

- required schema fields;
- preparation lead bounds;
- scheduled placement snapshots `prepareAt`;
- server-derived `scheduleState`;
- idempotent retry preserving the original `prepareAt`;
- Admin preparation-policy mutation;
- rejection when preparation lead exceeds customer minimum lead;
- new scheduled POS placement using the updated policy;
- later policy changes not rewriting existing scheduled orders.

The regression passes transactionally against the live project and rolls back all synthetic data/policy changes.

Security advisor remains unchanged with one existing WARN only: `auth_leaked_password_protection` / Leaked Password Protection Disabled. Performance advisor reports INFO-only unused indexes, including the new scheduled-preparation index on the tiny current dataset.

## Required Dashboard/POS integration

Dashboard branch:

`codex/task-scheduled-ops-001-prep-queue`

### Order client

Extend the Dashboard order snapshot/policy types and parsing to consume:

```text
OrderingPolicy.preparationLeadMinutes
OrderSnapshot.prepareAt
OrderSnapshot.serverNow
OrderSnapshot.scheduleState
```

Do not manufacture these values in React.

### Orders rail

Replace the single flat operational view with clear workload groups/tabs:

```text
Active | Scheduled | Ready | History
```

Recommended classification:

**Active**
- `confirmed`
- `preparing`
- scheduled orders with `scheduleState=due`
- scheduled orders with `scheduleState=overdue` (first/highest urgency)

**Scheduled**
- persisted `scheduled` + `scheduleState=future`
- group at minimum into Today / Tomorrow / Later when useful
- sort by `prepareAt`, then `requestedPickupAt`

**Ready**
- `ready`

**History**
- `completed`
- `cancelled`

A due/overdue scheduled order remains persisted `scheduled` until staff explicitly chooses **Start preparing**. That action must keep using `transition_order_status(... expectedVersion ...)` and the existing legal transition/state-version conflict handling.

Overdue presentation must be prominent and sort before ordinary active work. Show pickup time, preparation due time, source/customer indicator, item count, total, persisted status, and the legal next action. Do not silently auto-fire the persisted state.

### Staff live entry repair

The live `/employee` -> `/pos` path must stop requiring fake/nonexistent terminal and shift backend authority.

Required behavior:

```text
valid live staff Auth
 -> trusted employee BFF session
 -> role=staff
 -> /pos
 -> shared catalogue + quote/place + Orders available
```

Do not create hardcoded authoritative `Main Café`, terminal, branch, or shift records in React to make the page open.

Until a separate trusted branch/terminal/shift task exists:

- live staff POS operates in the already accepted single-café/global-staff scope;
- Sale and Orders remain usable;
- terminal/shift-dependent live controls must be removed, hidden, disabled, or explicitly marked deferred rather than blocking POS entry;
- preview mode may retain its preview terminal/shift simulation, clearly separated from live mode;
- `/admin/login` remains Admin/Owner-only; a staff account should use `/employee` and must not gain Admin access.

## Dashboard visual constraints

The new order-management UI must look native to the existing AIDA Dashboard/POS, not like a second design system.

Use the existing design tokens and components from `src/styles/tokens.css`, Tailwind/shadcn primitives, and existing POS patterns.

Key tokens:

```text
--aida-ivory      #fdf6f7
--aida-surface    #ffffff
--aida-espresso   #27121a
--aida-burgundy   #c13a52
--aida-rose       #af2626
--aida-floral-pink #de8d9d
--aida-blush      #f7dee3
--aida-gold       #c9a24e
--aida-success    #4f6b4a
--aida-warning    #b7782f
--aida-error      #8c3a2e
--aida-outline    #e8d5d0
```

Typography remains Playfair Display for display headings and Plus Jakarta Sans for body/UI. Keep current radii, spacing, touch targets, status pills, rail treatment, tables/cards, and accessibility behavior. Do not introduce arbitrary colors, gradients, typefaces, shadows, or generic SaaS-dashboard styling.

Use existing semantic status styles where possible:

- normal/info -> burgundy/blush
- due/warning -> `--aida-warning`
- overdue/error -> `--aida-error`
- ready/success -> `--aida-success`

Color must not be the only status signal; use labels/icons/text.

## Required Dashboard verification

At minimum:

```text
npm run lint
npm run typecheck
npm test
npm run build
```

Run relevant browser/E2E verification when available.

Add focused regression coverage for:

- backend snapshot parsing (`prepareAt`, `serverNow`, `scheduleState`);
- future scheduled order appears only in Scheduled workload;
- due scheduled order appears in Active but remains persisted status `scheduled`;
- overdue scheduled order is elevated/sorted before normal active work;
- Start preparing submits current `statusVersion` and uses existing conflict recovery;
- Ready/History classification;
- valid staff login routes to POS without live terminal/shift prerequisite;
- staff cannot enter Admin;
- preview terminal/shift simulator remains preview-only and cannot become live authority.

## Documentation closeout

When Dashboard integration is complete, update and mirror the affected canonical documents, including at minimum:

- `docs/context/ACTIVE_CONTEXT.md`
- `docs/context/HANDOFF.md`
- `docs/context/AUDIT_LOG.md`
- `docs/context/SUPABASE_STATUS.md`
- `docs/context/CODEBASE_MAP.md`
- `docs/context/ARCHITECTURE.md` / `SYSTEM_MAP.md` if flow descriptions change
- `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md`
- `docs/contracts/SHARED_BACKEND_CONTRACT.md`
- `docs/dashboard/UI_SCREEN_MAP.md`
- `docs/dashboard/STATE_AND_DATA_FLOW.md`
- `docs/dashboard/FRAGILE_BOUNDARIES.md`
- `docs/dashboard/MOCKS_AND_PLACEHOLDERS.md`
- `docs/security/SECURITY_REVIEW.md`

Do not mark `TASK-SCHEDULED-OPS-001` COMPLETE until the Dashboard implementation, tests, and mirrored documentation pass.