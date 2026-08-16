# Auth signup diagnostic

Updated: 2026-08-17

Status: `COMPLETE` for the investigated signup/runtime incident.

## Historical symptom

During the Auth integration stack, the customer Flutter signup flow initially returned the generic message `Authentication failed`. A later physical release APK exposed a more specific transport failure: `SocketException / Failed host lookup` for the Supabase project hostname.

At the earlier diagnostic point the live project had no approved real identities, so backend provisioning and client transport had to be separated rather than treating every failure as an RLS/member-trigger defect.

## Verified trusted provisioning boundary

- Supabase project: `eswovqxqzfevcdwwcmuh` (`Aida System`).
- `auth.users` -> `public.handle_new_auth_user()` trigger is the trusted signup provisioning path.
- The provisioning function forces public signups to the `customer` application role.
- `public.generate_member_code()` owns member-code generation.
- Public signup cannot self-assign employee/admin roles, trusted verification outcomes or member codes.

## Client diagnostic improvement

`SupabaseMemberRepository` maps common Auth failures instead of collapsing them all into a generic message. Covered classes include invalid credentials/email, disabled signup, rate limiting, duplicate accounts, password-policy/confirmation/provisioning failures and transport/network failures.

Transport failures are presented without exposing raw stack traces, tokens or upstream internals.

No service-role/secret credential or Auth/RLS bypass was added.

## Android release root cause

TASK-AUTH-006 independently proved that the production/main Android manifest omitted `android.permission.INTERNET` while debug/profile overlays declared it. The release APK therefore could fail before any request reached Supabase.

The fix moved the required permission into the main manifest and added a regression test. The committed Android toolchain was later made reproducible with AGP 8.9.1 and Gradle 8.11.1.

## Final validation

The user installed the corrected release APK on a physical Android phone and successfully created a new customer account. Supabase provisioned Auth/profile/member state and the new member appeared in protected Dashboard Members. The previous host-lookup failure did not recur.

Current closeout evidence has 9 Auth users, 9 profiles, 6 members and trusted employee roles owner/admin/staff = 1/1/1. A real Owner can sign into the Dashboard protected Admin path.

The final TASK-CLOSEOUT-001 live order E2E also authenticated a real customer normally through Supabase Auth, confirming the customer Auth/session boundary is operational.

## Hosted Auth configuration note

Email-confirmation/SMTP behavior remains hosted Supabase Auth configuration and is not a database migration. The current security advisor also reports `auth_leaked_password_protection` because leaked-password protection is disabled; that operational warning is tracked separately in `docs/security/SECURITY_REVIEW.md` and `docs/context/SUPABASE_STATUS.md`.

This diagnostic should no longer be used as evidence that signup, real identities or protected Dashboard access are pending. Current truth is in `ACTIVE_CONTEXT.md` and `CLOSEOUT_EVIDENCE_2026-08-17.md`.
