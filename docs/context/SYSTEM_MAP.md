# AIDA Café System Map

Updated: 2026-08-12

## Source systems

| System | Repository/runtime | Current auth/member source |
|---|---|---|
| Customer | `Hermann-33/Aida_System` — Flutter | Supabase Auth + owner-scoped `user_profiles`/`members` on TASK-AUTH-001 stack |
| POS/Admin | `Hermann-33/Aida_System-Dashboard` — React/Vite | same-origin BFF cookie session + live admin-member API on TASK-AUTH-002 stack |
| Shared backend | Supabase `eswovqxqzfevcdwwcmuh` | Auth/Postgres/forced RLS/RPC |

## Auth/member flow

```text
Customer sign-up
  -> Supabase Auth
  -> Auth trigger
  -> user_profiles + members
  -> server-issued member_code

Admin browser
  -> POST /api/v1/auth/employee/login
  -> dashboard BFF
  -> Supabase Auth + own user_profiles role/disabled check
  -> HttpOnly session cookies
  -> GET /api/v1/admin/members
  -> BFF calls list_admin_members() with caller JWT
  -> Admin Members renders trusted rows
```

No member fixture fallback exists in the implemented Admin Members path.

## Still preview/not authoritative

Catalogue/pricing, quote/order/payment, loyalty/rewards/vouchers, branch/terminal/employee administration, POS operational state, inventory, marketing, reporting and audit remain future backend domains unless separately documented as implemented.

## Change-impact rule

Shared identity/member/role changes require both clients plus Supabase/BFF authorization to be reviewed together. A browser screen compiling does not prove backend completion.
