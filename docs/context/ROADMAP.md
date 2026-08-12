# AIDA Café Implementation Roadmap

Updated: 2026-08-12

## Phase 1 — Governance/source baselines

WF-001/002/003/004: COMPLETE.

## Phase 2 — Shared Supabase foundation

Identity/profile/member/student-verification foundation: COMPLETE for scoped foundation. Broader business domains remain.

## Phase 3 — Authentication, membership and staff/admin access

### Implemented source

- Customer Supabase Auth and member/profile bootstrap.
- Server-issued member identity/code and hardened student declaration.
- Admin/owner-only member-directory RPC.
- Admin Members live API client with no fixture fallback.
- Same-origin dashboard BFF for password employee/admin sessions, refresh/logout and member directory.
- HttpOnly token transport, trusted role/disabled checks and caller-JWT RLS preservation.
- Terminal-independent admin login.

### Remaining completion gates

- full repository npm checks blocked by GitHub runner billing condition;
- deploy AIDA dashboard+BFF same-origin;
- create/assign a real trusted admin/owner identity through an approved operator path;
- execute real customer signup -> DB member -> admin login -> Admin Members E2E.

**Status:** PARTIAL under ADR-0004.

## Phase 4 — Catalogue/publication

Not started. Shared published catalogue/modifiers/prices remains the next product domain after auth operational closure.

## Later phases

Quote/order/payment; loyalty/vouchers; operations/inventory; reporting/marketing/hardening remain not started except preview UI.

## Exact next task

`TASK-AUTH-003 — dashboard deployment + admin bootstrap + live auth/member E2E closure`.

After that passes, resume `TASK-DB-002 — shared menu/catalogue foundation`.
