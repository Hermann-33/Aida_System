# Current Handoff

Updated: 2026-08-13

## Current task

`TASK-AUTH-004 — customer Auth runtime + dashboard protected Admin access`

**Overall verdict:** PARTIAL.

Shared branch in both repositories:

`codex/task-auth-004-runtime-access-fix`

Stack:

`codex/task-demo-order-001-order-scheduling-backend`
→ `codex/fix-auth-signup-diagnostics`
→ `codex/task-auth-004-runtime-access-fix`

Do not merge the stack out of order.

## Problem reproduced from current evidence

### Customer

The installed phone app still showed the generic Auth fallback. Fresh Supabase checks showed zero Auth users and no corresponding live identity/member row. The connector Auth log did not provide a recent signup event to correlate, so the old binary could not reveal the actual hosted Auth reason.

### Dashboard

Members/Menu are protected Admin routes. `ProtectedRoute` performs a server session refresh; with no authenticated Admin session it correctly redirects away after the initial loading state. The live project currently has zero Auth users and zero trusted admin/owner profiles, so there is no valid identity that can satisfy that route today.

This is not a reason to make Members public or bypass the route guard.

## Changes on this branch

### Customer repo

- `apps/customer/lib/main.dart`
  - active AIDA Supabase URL remains the default;
  - active AIDA **publishable** key is now also a safe public default;
  - explicit `--dart-define` values can still override both;
  - no service-role/secret key is present.
- `apps/customer/lib/data/repository/supabase_member_repository.dart`
  - known Auth errors retain explicit mapping;
  - unknown `AuthException` messages are normalized/capped and shown so the next physical-device attempt exposes the real upstream reason.

### Dashboard repo

- `vite.config.ts`
  - local BFF receives the active AIDA URL/publishable key by default;
  - explicit env values override defaults;
  - no service-role/secret key.
- `src/auth/ProtectedRoute.tsx`
  - still fail-closed;
  - redirects unauthenticated Admin navigation to `/admin/login` with selected destination + session error context.
- `src/pages/AdminLoginPage.tsx`
  - tells the operator why Members/Menu require Admin sign-in;
  - returns to the originally selected Admin route after successful login;
  - distinguishes credentials, authorization, disabled-account, local BFF config and network errors.

## Supabase status

Fresh live state on 2026-08-13:

- Auth users: 0
- admin/owner profiles: 0
- security advisor: 0 lints
- provisioning trigger/function/member-code authority unchanged

No direct `auth.users` SQL insert was used.

A temporary exact-account Admin-API bootstrap Edge Function was deployed for investigation, but the tool environment could not invoke the public function URL. No user was created. The function was immediately superseded by a disabled HTTP-410 version.

## Required local validation

### Customer

From the customer checkout:

1. fetch/switch/pull `codex/task-auth-004-runtime-access-fix`;
2. `cd apps/customer`;
3. run `flutter pub get`, `flutter analyze`, `flutter test`;
4. rebuild/install the app on the physical Android phone;
5. attempt signup again.

If signup still fails, report the **new exact Auth text**. Do not report only the old generic message; that means the phone is still running an older binary.

### Dashboard

From the dashboard checkout:

1. fetch/switch/pull `codex/task-auth-004-runtime-access-fix`;
2. `npm ci`;
3. `npm run lint`, `npm run typecheck`, `npm test`, `npm run build`;
4. restart `npm run dev`;
5. select Members or Menu.

Expected behavior without an identity: explicit redirect to Admin sign-in, not an unexplained disappearing tab.

Expected behavior after a trusted Admin/owner identity exists: sign in once, then return to the selected Members/Menu route and load through the existing caller-JWT BFF/RLS path.

## Identity bootstrap gate

The remaining blocker is a real Auth identity. Once customer signup succeeds (or an Auth user is created through the Supabase Auth Admin surface), the intended operator can be promoted through the trusted DB/operator boundary to `admin`/`owner`. Do not allow public signup metadata or a browser request to self-assign that role.

## Next product task after AUTH-004 validation

Resume the dashboard half of `TASK-DEMO-ORDER-001`: authoritative POS quote/place plus the live Scheduled/Confirmed/Preparing/Ready order board and status transitions. Keep payment, loyalty, inventory and reporting authority out of scope until the order flow closes end to end.
