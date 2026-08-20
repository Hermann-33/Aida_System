# AIDA Café Security Review

Updated: 2026-08-20

**Current verdict:** identity, catalogue and order/scheduling authority remain server-controlled. TASK-SCHEDULED-OPS-001 adds scheduled-order preparation authority without moving fulfilment or authorization truth into either frontend.

## Core controls

- Supabase Auth plus trusted `user_profiles`/`members` remain authoritative for identity and membership.
- Public signup cannot self-promote role/member/verification state.
- Catalogue authority remains Supabase Postgres/RLS/RPC; browser/mobile clients do not own catalogue prices or compatibility.
- Dashboard privileged flows retain same-origin HttpOnly employee sessions and caller-JWT Supabase access.
- No service-role key or browser-readable staff bearer token is introduced.

## Order/scheduling controls

All existing order/scheduling tables retain their accepted RLS/FORCE-RLS and bounded RPC model:

- `order_schedule_settings`
- `orders`
- `order_lines`
- `order_line_addons`
- `order_events`

Ordinary authenticated clients still have no direct INSERT/UPDATE authority over order commercial tables. Controlled persistence remains behind trusted RPC helpers with explicit caller/role checks.

### Pricing and identity

- `quote_order(jsonb)` ignores client price/total fields and re-prices from current published/available catalogue data.
- Item/variant/add-on compatibility is revalidated server-side.
- Customer/member identity is derived from `auth.uid()` plus the active member row, never request JSON.
- POS placement requires staff-or-above.
- Order UUID, number, commercial snapshots, totals, initial status, timestamps and events remain server-owned.

### Idempotency

Placement still requires a `clientRequestId` UUID scoped to the authenticated actor.

- identical retry returns the existing order;
- same key + different payload conflicts;
- retry cannot duplicate an order.

TASK-SCHEDULED-OPS-001 also proves an identical retry preserves the original server-owned `prepareAt` even if the scheduling policy later changes.

## Scheduled preparation authority

The backend now owns two distinct schedule concepts:

```text
minimumLeadMinutes      -> earliest permitted pickup selection
preparationLeadMinutes  -> operational lead before pickup
```

Constraint:

```text
0 <= preparationLeadMinutes <= minimumLeadMinutes
```

Only Admin/Owner can change scheduling/preparation policy through the existing trusted mutation boundary.

For a newly accepted scheduled order, the server snapshots:

```text
prepareAt = requestedPickupAt - preparationLeadMinutes
```

`prepareAt` is included in the protected immutable order fields. A later policy change cannot rewrite an accepted order's operational due time.

Clients cannot submit or modify trusted `prepareAt`.

Authorized order snapshots also expose backend-derived:

```text
serverNow
scheduleState = future | due | overdue | null
```

The Dashboard must use backend `scheduleState` for operational queue classification. Device/workstation time is not business authority.

### No automatic fulfilment mutation

Reaching `prepareAt` does not change persisted order status.

The legal state machine remains:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

Only staff-or-above may perform status changes, using expected `statusVersion`. `scheduleState=due|overdue` means work is operationally due, not that a human has started preparation.

This prevents a timer/cron/browser from manufacturing fulfilment truth.

## Realtime / queue boundary

`orders` remains the mutable Realtime signal for customer-owned refresh. Customer visibility remains owner-scoped.

Dashboard staff continues to use same-origin BFF polling/refetch because the employee access token remains HttpOnly.

The current staff queue remains global by accepted single-café limitation; branch-scoped authorization is still deferred.

## Staff login / deferred terminal boundary

Live verification confirms the Nora demo account is a valid confirmed, active `staff` identity and can authenticate through Supabase Auth.

The former post-auth POS failure was caused by Dashboard UI dependencies on terminal/shift endpoints that do not exist in the trusted backend. Supabase still has no authoritative branch/terminal/sales-point/shift schema. TASK-SCHEDULED-OPS-001 removed those calls from live entry and uses the accepted single-café/global order scope; it did not invent the missing authority.

Security rule for the Dashboard fix:

- do not create hardcoded live branch/terminal/shift identities to bypass the gap;
- do not treat preview terminal/shift fixtures as production authorization;
- authenticated staff may use the already-authorized single-café Sale/Orders path;
- `/admin/login` remains Admin/Owner-only;
- terminal/shift/branch authority stays deferred until a separate trusted backend task defines it.

Live employee authentication still uses the same-origin BFF and HttpOnly cookies. Staff receives POS access but remains denied Admin. Preview terminal/shift/member simulations are omitted from the live rail and cannot authorize catalogue, member or order mutations.

Removing an unimplemented UI prerequisite is not authorization weakening because staff order capability is already enforced by the BFF/RPC role boundary.

## TASK-SCHEDULED-OPS-001 live verification

Applied migration:

`20260820151421_add_scheduled_order_preparation_window`

Focused transactional regression:

`supabase/tests/scheduled_order_operations_integration.sql`

Result: PASS against the live project with synthetic data/policy changes rolled back.

The test covers preparation schema/bounds, scheduled placement `prepareAt`, server-derived schedule classification, idempotent preservation, Admin-only policy mutation, invalid policy rejection, scheduled POS placement and non-rewriting of prior orders.

Existing scheduled orders `100007`, `100008`, `100009` were backfilled with `prepareAt` and now classify as `overdue` without any fabricated persisted status change.

## Advisor state

Current Supabase security advisor remains exactly one WARN:

- `auth_leaked_password_protection` — **Leaked Password Protection Disabled**

Remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

TASK-SCHEDULED-OPS-001 introduced no new security advisor finding.

Performance advisor findings are INFO-only unused-index notices on the small dataset, including the new scheduled preparation index immediately after creation.

## Explicitly deferred authority

No trusted implementation currently exists for:

- real payment/refunds;
- loyalty earning/redemption;
- inventory depletion;
- promotions/discounts;
- tax/accounting/reporting;
- branch-scoped staff/order access;
- branch scheduling hours/capacity;
- terminal/sales-point authority;
- shift/cash reconciliation;
- delivery;
- hosted production operations.

Frontend presentation must not imply those domains are authoritative.
