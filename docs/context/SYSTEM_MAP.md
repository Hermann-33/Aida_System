# AIDA Café System Map

Updated: 2026-08-12

## Source systems

| System | Repository/service | Default | Runtime |
|---|---|---|---|
| Customer app | `Hermann-33/Aida_System` | `master` | Flutter/Dart/Riverpod |
| POS/Admin | `Hermann-33/Aida_System-Dashboard` | `main` | React/TypeScript/Vite |
| Shared backend | Supabase `eswovqxqzfevcdwwcmuh` | managed | Auth/Postgres/RLS |

## Current shared-domain status

| Shared concept | Customer task branch | Dashboard task branch | Trusted authority/status |
|---|---|---|---|
| Customer auth/session | Supabase Auth | n/a | Supabase Auth — integrated customer-side |
| User/member profile | owner-scoped DB read | Members UI calls planned BFF | `user_profiles` + `members` |
| Member code | server-issued DB value | directory contract field | `public.generate_member_code()` |
| Student declaration | signup sends untrusted `is_student` | admin table displays trusted status | signup can create only `pending`; trusted review remains separate |
| Admin member directory | n/a | no fixture fallback; HTTP contract only | `public.list_admin_members()` exists; BFF/session missing |
| Catalogue | preview/mock | preview fixture | not persisted yet |
| Price/modifiers | client preview | client preview | future trusted quote/catalogue |
| Orders/payments | local preview | local/simulated | not persisted yet |
| Loyalty/rewards | mock | rewards preview | not persisted yet |
| Branch/staff/terminal | n/a | preview | trusted model/session not implemented |
| Inventory/reporting/audit | n/a | preview | not persisted yet |

## Auth/member flow now

```text
Customer sign-up intent
  -> Supabase Auth
  -> auth.users trigger
  -> user_profiles(app_role=customer)
  -> members(server member_code; standard/not_submitted or student/pending)

Signed-in customer
  -> owner-scoped user_profiles + members reads under forced RLS

Authorized admin target flow
  -> same-origin HttpOnly staff/admin session [NOT IMPLEMENTED]
  -> GET /api/v1/admin/members [NOT IMPLEMENTED SERVER-SIDE]
  -> public.list_admin_members() as authenticated admin/owner under RLS
  -> Admin Members table [client adapter implemented]
```

## Change-impact rule

Any shared identity/member/role/catalogue/order/payment/loyalty/inventory contract change requires inspection of both repositories. UI fixtures are requirements evidence, never database authority.
