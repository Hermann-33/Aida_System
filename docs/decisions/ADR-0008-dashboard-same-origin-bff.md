# ADR-0008 — Dashboard same-origin BFF for privileged sessions

**Status:** Accepted
**Date:** 2026-08-12

## Context

The POS/Admin browser needs privileged employee/admin capabilities, but accepted security rules prohibit shipping Supabase service-role keys, database credentials or long-lived privileged bearer tokens in the Vite bundle. TASK-AUTH-001 created an admin-only member-directory database capability and a browser contract at `/api/v1/admin/members`, but no trusted same-origin server runtime existed to authenticate the browser and execute that capability.

Admin browser access also must not depend on POS terminal enrolment. Terminal identity and employee identity are separate trust boundaries.

## Decision

Use a same-origin backend-for-frontend (BFF) alongside the dashboard for privileged employee/admin HTTP capabilities.

For TASK-AUTH-002:

- Supabase Auth remains the identity provider.
- Password login is performed by the BFF against Supabase Auth using only the project publishable key.
- Supabase access and refresh tokens are stored in `HttpOnly`, `SameSite=Lax` cookies and are never returned in browser JSON or persisted by application JavaScript.
- The BFF revalidates the access token with Supabase Auth and reads the caller's own trusted `user_profiles` record under RLS.
- `disabled_at` blocks employee access immediately on the next authenticated request.
- `customer` identities are rejected from employee/admin sessions.
- `admin` and `owner` may access the member directory; `staff` may authenticate but may not list all members.
- The member-directory BFF calls `public.list_admin_members()` using the caller's Supabase JWT. It does not use a service-role bypass, so the RPC's role check and RLS remain active.
- State-changing cookie endpoints enforce same-origin requests.
- Responses carrying authenticated data use `Cache-Control: no-store`.
- Admin login has its own browser route and does not require POS terminal enrolment.

The BFF core uses standard Web `Request`/`Response` primitives. The initial thin deployment adapters live under dashboard `/api` and are compatible with same-origin serverless-function hosting such as Vercel. Hosting is not backend authority; Supabase Auth/Postgres/RLS remain authoritative.

## Consequences

- The dashboard browser never receives privileged backend credentials.
- Session refresh and revocation are centralized server-side.
- Existing `credentials: include` dashboard clients become executable without weakening RLS.
- A hosting environment must provide `AIDA_SUPABASE_URL` and `AIDA_SUPABASE_PUBLISHABLE_KEY` to the server runtime.
- Live badge/PIN auth, POS terminal enrolment backend, branch assignment and employee-role administration remain separate tasks.
- A real admin/owner Auth identity must exist before production Admin login can succeed; public customer signup never self-promotes.

## Rejected alternatives

### Supabase service-role key in Vite

Rejected. Any browser user could extract the credential and bypass intended authorization boundaries.

### Anonymous or staff-wide member-table policy

Rejected. The requested Admin Members screen does not justify broad customer-data disclosure.

### Browser-stored staff access token

Rejected. It regresses the accepted HttpOnly employee-session boundary and increases token theft exposure.

### Treat terminal enrolment as admin authentication

Rejected. A POS device credential is not a manager identity and must not gate ordinary browser administration.
