# AIDA Café Implementation Roadmap

Updated: 2026-08-12

Statuses describe verified system reality, not UI polish.

## Phase 1 — Governance and source baselines

`TASK-WF-001` through `TASK-WF-004`: COMPLETE and merged.

## Phase 2 — Shared Supabase foundation

`TASK-DB-001`: identity/profile/member/student-verification foundation with forced RLS — COMPLETE for its bounded scope.

Broader domain persistence remains PARTIAL/not started.

## Phase 3 — Authentication, membership and staff access integration

### `TASK-AUTH-001 — customer auth + member integration`

Status: **PARTIAL**.

Implemented:

- real customer Supabase Auth sign-up/sign-in/recovery/session/logout wiring on task branch;
- owner-scoped member/profile reads;
- server-owned signup provisioning and member codes;
- student declaration constrained to pending;
- admin/owner DB member-directory capability;
- dashboard Members fixture removed and replaced with a same-origin API client contract.

Missing completion gate:

- production staff/admin BFF + HttpOnly session;
- server implementation of `GET /api/v1/admin/members`;
- end-to-end signup -> DB member -> Admin Members proof;
- local Flutter/dashboard toolchain checks.

### `TASK-AUTH-002 — trusted staff/admin session and member-directory API`

Status: **recommended next task**.

Must establish trusted staff/admin authentication/session/revocation, implement the member-directory API against the shared backend, and complete the cross-client membership visibility path without browser privileged secrets.

## Phase 4 — Catalogue and publication

`TASK-DB-002: shared menu/catalogue foundation` remains the next major database-domain task after the auth/member access path is closed.

Status: not started.

## Phase 5 — Quote, order, fulfilment and payment

Status: not started; both clients simulate these flows.

## Phase 6 — Loyalty, rewards, vouchers and promotions

Status: not started; current values remain preview-only.

## Phase 7 — Operations and inventory

Status: not started; dashboard previews exist.

## Phase 8 — Reporting, marketing, hardening and release

Status: not started.

## Exact recommended next task

`TASK-AUTH-002: trusted staff/admin session and member-directory API`.
