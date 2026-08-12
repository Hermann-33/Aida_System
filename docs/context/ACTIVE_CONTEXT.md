# Active Context

**As of:** 2026-08-12
**Current implementation task:** `TASK-AUTH-002 — trusted staff/admin session and member-directory API`
**Current task verdict:** PARTIAL
**Exact recommended next task:** `TASK-AUTH-003 — deploy the AIDA dashboard BFF, bootstrap an admin/owner identity, and run live auth/member E2E closure`

## Current product reality

### Customer app

- Repo: `Hermann-33/Aida_System`; default branch `master`.
- TASK-AUTH-001 branch stack wires Supabase Auth sign-up/sign-in/recovery/session restore/logout and owner-scoped profile/member reads.
- Signup no longer generates authoritative member IDs/codes locally. Supabase provisions `user_profiles` + `members` and generates member codes server-side.
- Other customer domains remain preview/mock until their bounded backend tasks.

### POS/Admin dashboard

- Repo: `Hermann-33/Aida_System-Dashboard`; default branch `main`.
- TASK-AUTH-002 branch: `codex/task-auth-002-admin-session-member-api`, stacked on TASK-AUTH-001.
- A same-origin employee/admin BFF now implements password login, session validation/refresh, logout and `GET /api/v1/admin/members`.
- Supabase access/refresh tokens remain in HttpOnly cookies; browser JSON and storage never receive them.
- The BFF validates Supabase Auth plus trusted `user_profiles.app_role`/`disabled_at` and invokes `public.list_admin_members()` with the caller JWT, preserving RLS.
- `/admin/login` is independent of POS terminal enrolment.
- Admin Members has no member-fixture fallback. Non-auth/loyalty/operations domains remain preview until their own tasks.
- The same BFF core is mounted in Vite dev/preview and exposed through root `/api` adapters for same-origin serverless hosting.

### Shared Supabase

Project: **Aida System**, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`.

TASK-AUTH-002 requires no schema migration. Live `list_admin_members()` remains `SECURITY INVOKER`, executable only by `authenticated`, with anon denied. Security advisor is 0 lints. Latest retained counts are 0 Auth users / 0 profiles / 0 members / 0 student verifications.

## Verification state

Passed:

- TASK-AUTH-001 live provisioning/tamper/admin-vs-customer database tests.
- TASK-AUTH-002 BFF core ad-hoc TypeScript compile/runtime checks: login token non-disclosure, HttpOnly cookies, refresh rotation, staff denial, admin caller-JWT RPC, logout cookie clearing.
- Live Supabase RPC posture and security advisor recheck.

Blocked externally:

- GitHub Actions could not start any npm step because the account runner was blocked by a billing/spending-limit condition. The temporary workflow was removed so it does not poison future PRs.
- No AIDA project exists in the connected Vercel account, so no hosted same-origin deployment can be proven here.
- Live Supabase currently has no real admin/owner Auth identity and no real customer rows, so the literal deployed customer-signup -> Admin Members browser flow cannot be exercised yet.

Under ADR-0004 those external gates keep the requested full-stack feature `PARTIAL`; the missing source BFF implementation itself is now present.
