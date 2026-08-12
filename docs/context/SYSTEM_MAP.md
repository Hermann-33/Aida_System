# System Map

Updated: 2026-08-12

| System | Runtime | Current trusted source |
|---|---|---|
| Customer | Flutter/Riverpod | Supabase Auth/member stack + shared catalogue |
| Admin | React/Vite | same-origin BFF + shared catalogue/member RPCs |
| Backend | Supabase | Auth, Postgres, forced RLS, controlled RPCs |

## Catalogue flow

```text
Admin Menu
 -> same-origin BFF cookie session
 -> admin/owner caller JWT
 -> save_catalogue_* SECURITY INVOKER RPC
 -> catalogue tables + audit + revision bump
 -> Supabase Realtime revision event
 -> Flutter invalidates catalogue snapshot
 -> get_catalogue() under RLS
 -> updated menu shown in app
```

The production customer menu contains no hardcoded catalogue fallback. Initial live seed is the 16 entries formerly hardcoded in the customer app.

POS transaction/checkout preview data is not catalogue authority and remains outside TASK-MENU-001.
