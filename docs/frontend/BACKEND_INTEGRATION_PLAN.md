> Scope note: this is the customer-app backend-needs map. POS/Admin needs are in `docs/dashboard/BACKEND_INTEGRATION_PLAN.md`; shared rules are in `docs/contracts/SHARED_BACKEND_CONTRACT.md`.

# Customer Backend Integration Plan

This is a needs map, not a schema prescription.

| Area | Current verified state | Remaining backend behavior | Priority |
|---|---|---|---|
| Customer auth | TASK-AUTH-001 task branch uses Supabase sign-up/sign-in/recovery/session restore/logout | Flutter toolchain + real-device/browser smoke proof; cache/revocation hardening | MVP |
| Profile/member | owner-scoped DB reads; server-issued member code; signup provisioning live | durable profile edits; complete admin visibility through staff BFF | MVP |
| Student status | signup declaration creates only `pending` | evidence submission/review/expiry policy | MVP |
| QR | customer displays server member code after member read | authorized POS lookup, rate limits/audit | MVP |
| Catalogue | preview/mock | published categories/items/variants/modifiers/prices/availability/images | MVP |
| Quote/orders/payments | preview/local | authoritative quote, order lifecycle and approved payment boundary | MVP |
| Loyalty/vouchers | preview/mock | ledger balances and atomic redemption/consumption | MVP |
| Promotions/storage/notifications | preview/placeholder | bounded publication/storage/delivery contracts | Important/Future |

## TASK-AUTH-001 boundary

`SupabaseMemberRepository` is now the auth/member implementation. It deliberately delegates catalogue, loyalty, rewards, offers, promos and menu reads to preview data until those feature tasks replace them. This is not permission to treat preview data as trusted; it prevents one auth task from silently inventing other backend domains.

Signup no longer creates local member IDs/codes. The client submits email/password plus display name and student declaration; Supabase Auth and the database trigger own persisted identity/membership outcomes.

## Cross-client dependency

The database admin member-directory capability exists, but production Admin visibility requires `TASK-AUTH-002` to implement trusted staff/admin sessions and the same-origin member API. Do not make the customer app or dashboard browser privileged to close that gap.
