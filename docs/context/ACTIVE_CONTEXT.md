# Active Context

**As of:** 2026-08-13
**Current implementation task:** `TASK-AUTH-004 — customer Auth runtime + dashboard protected Admin access`
**Current task verdict:** PARTIAL

## Current product reality

The shared Supabase identity/member, catalogue, ordering and scheduling foundations remain live and authoritative. Customer ordering frontend integration is implemented on the current stack; dashboard order-board/POS transaction frontend integration remains a later task.

TASK-AUTH-004 addresses two local-demo failures reported against the current stack:

1. customer signup rendered a generic Auth failure and recent attempts could not be correlated to a created live Auth identity;
2. Dashboard Members/Menu briefly rendered a loading state and then disappeared because the protected route correctly resolved the browser as anonymous and redirected away without preserving useful destination/diagnostic context.

## Live Supabase evidence

Project: `Aida System` / `eswovqxqzfevcdwwcmuh` / `ap-southeast-1`.

Fresh live checks on 2026-08-13 show:

- Auth users: **0**;
- trusted admin/owner profiles: **0**;
- no profile/member exists for an Auth identity because no Auth identity currently exists;
- existing `auth.users` provisioning trigger remains enabled;
- `handle_new_auth_user()` remains a `SECURITY DEFINER` function owned by `postgres`;
- member-code generation remains server-owned;
- Supabase security advisor remains at **0 lints**.

Therefore Members/Menu cannot be authorized until a real Supabase Auth identity exists and its trusted `user_profiles.app_role` is `admin` or `owner`. The fix must not make member data anonymous, bypass `ProtectedRoute`, expose a staff bearer token, or use a service-role key in browser/mobile code.

## TASK-AUTH-004 source fixes

Shared branch in both repositories:

`codex/task-auth-004-runtime-access-fix`

It is stacked on `codex/fix-auth-signup-diagnostics`, which is stacked on the current order-task branch.

### Customer Flutter

`apps/customer/lib/main.dart` now has the active AIDA project URL and **publishable** Supabase key as safe public defaults. `--dart-define` remains an override, but installed demo builds no longer depend on a fragile missing/stale build-time key. No service-role/secret key is embedded.

`SupabaseMemberRepository` continues mapping common Auth failures to user-safe messages. Unrecognized `AuthException` messages are now normalized, capped, and surfaced in the UI instead of being erased behind the generic `Authentication failed / check account settings` message. This is intentionally diagnostic until the real hosted Auth response is observed on the rebuilt phone app.

### Dashboard

`vite.config.ts` now supplies the same AIDA project URL and publishable key as local BFF defaults, with explicit environment values taking precedence. This removes `.env` presence as an unnecessary local-demo dependency while preserving the same-origin BFF and caller-JWT model.

`ProtectedRoute` still fails closed. When an Admin page is selected without a valid employee session it now redirects to `/admin/login` with the intended Admin destination and the session error code.

`AdminLoginPage` now:

- explains that Members/Menu require an Admin/owner sign-in;
- preserves the selected Admin destination and returns there after successful authentication;
- surfaces configuration/network/access/disabled/credential failures distinctly instead of always showing `Invalid administrator credentials`.

No member/catalogue RLS policy or privileged BFF authorization check was weakened.

## Bootstrap attempt

A narrowly scoped temporary Edge Function was deployed only to investigate supported server-side Auth Admin bootstrapping. The available tool runtime could deploy but could not invoke arbitrary function URLs, so **no user was created**. The function was immediately replaced by a disabled version returning HTTP 410. It is not an active bootstrap capability.

No direct SQL insert into `auth.users` was performed.

## Existing trusted order/catalogue state

The shared catalogue remains 4 categories / 16 items / 27 variants / 27 compatible add-on links. Authoritative ordering/scheduling remains live under ADR-0010, with customer quote/place/history/status integration already present in Flutter. Dashboard order BFF endpoints remain available; React order-board/POS transaction integration is still pending.

## Required validation / remaining gate

Source changes cannot prove the phone/device path from this connector-only runtime. The next validation must use the actual local checkouts:

1. pull `codex/task-auth-004-runtime-access-fix` in both repos;
2. rebuild/install the Flutter app from `apps/customer` so the new public config and diagnostic mapper are definitely in the binary;
3. attempt signup and capture the exact Supabase Auth reason if it still fails;
4. once a real Auth identity exists, promote only the intended operator identity to trusted `admin`/`owner` through the database/operator boundary;
5. log into `/admin/login`, then verify Members and Menu return to the originally selected route and load through the caller-JWT BFF/RLS path.

Until a real identity exists and these local-device flows pass, TASK-AUTH-004 remains `PARTIAL`.
