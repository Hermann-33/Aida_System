# POS/Admin Backend Integration Plan

This is a needs map, not a table-by-table schema prescription.

| Area | Current verified state | Remaining trusted behavior | Priority |
|---|---|---|---|
| Employee/admin auth | browser-side session contract expects same-origin HttpOnly runtime; server absent | authenticate/revoke staff/admin, disabled state, trusted roles | MVP |
| Member directory | DB admin RPC exists; Members UI targets `/api/v1/admin/members` with no fixture fallback | implement trusted BFF endpoint/session and E2E proof | MVP |
| Branch/role scope | preview | assignments/global-manager/server authorization | MVP |
| Terminals/shifts/cash | preview | secure enrolment/session/branch binding and audited operations | MVP POS |
| Catalogue | preview | same published IDs/prices as customer; privileged edits | MVP |
| Quote/orders/payments | preview/simulated | authoritative totals/lifecycle/provider/reconciliation | MVP |
| Member QR lookup | preview | bounded staff lookup, minimal disclosure, rate limits/audit | MVP |
| Loyalty/vouchers | preview | current trusted balance/eligibility and atomic consume/redeem | MVP |
| Inventory/reporting/audit | preview | durable trusted models and scoped queries | Important/MVP foundation |

## Immediate next integration

`TASK-AUTH-002` must implement the production same-origin employee/admin session plus `GET /api/v1/admin/members`. The endpoint must authenticate the HttpOnly session, enforce admin/owner authorization, call the shared backend capability and serialize only required directory fields.

No Supabase service-role key, private database credential or privileged long-lived token may be shipped to the Vite browser bundle.

## Shared-contract rule

Do not implement dashboard-only identity, catalogue, order or loyalty authority. Shared concepts must align with the customer requirements and `docs/contracts/SHARED_BACKEND_CONTRACT.md`.
