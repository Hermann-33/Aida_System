# POS/Admin State and Data Flow

Updated: 2026-08-12

## Employee/admin auth path

```text
AdminLoginPage / existing employee client
  -> employeeFetch(credentials: include)
  -> same-origin dashboard BFF
  -> Supabase Auth
  -> caller-owned user_profiles role/disabled check under RLS
  -> HttpOnly access/refresh cookies
```

Session restore uses `GET /api/v1/auth/employee/session`; invalid access may be refreshed server-side and cookies rotated. Logout revokes the local Supabase Auth session when possible and expires both cookies.

## Admin Members

```text
Admin Members
  -> fetchAdminMembers -> employeeFetch
  -> GET /api/v1/admin/members
  -> BFF authenticates admin/owner
  -> list_admin_members() with caller JWT
  -> trusted member/profile rows
  -> TanStack Query cache/UI
```

There is no member-fixture fallback in this path. Loyalty activity on the combined page remains explicitly preview-only because the loyalty backend does not exist yet.

## Development/hosting

`server/viteBffPlugin.ts` mounts the same BFF core in Vite dev/preview. Production-compatible root `/api` adapters use the same handlers; the browser contract does not change between environments.

## Remaining dashboard state

Most POS, catalogue, order/payment, employee/terminal, inventory, loyalty, marketing/reporting and audit workflows still rely on React/module/preview state and are not durable authority.
