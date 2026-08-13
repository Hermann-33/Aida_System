# Auth signup diagnostic

Status: `PARTIAL`

## Observed symptom

The customer Flutter signup flow returned the generic message `Authentication failed` while the live Supabase project still contained zero Auth users, profiles, and members.

## Verified backend evidence

- Supabase project: `eswovqxqzfevcdwwcmuh` (`Aida System`), `ACTIVE_HEALTHY`.
- `auth.users` -> `public.handle_new_auth_user()` trigger exists and is enabled.
- `public.handle_new_auth_user()` is `SECURITY DEFINER`, owned by `postgres`, and forces new public signups to the `customer` application role.
- `public.generate_member_code()` exists.
- The failed signup left zero Auth users and did not produce a corresponding provisioning-trigger Postgres error.

This points to an Auth-layer rejection occurring before the profile/member trigger rather than an RLS/provisioning failure.

## Client fix

`SupabaseMemberRepository` no longer collapses common Supabase Auth signup failures into the single generic `Authentication failed` message. It now maps common cases including:

- email address not authorized by the current Auth email configuration;
- signups disabled;
- invalid email;
- Auth rate limiting;
- CAPTCHA/verification failure;
- database user-provisioning errors;
- duplicate account;
- password policy failure;
- unconfirmed email.

No service-role/secret credential was added and no Auth/RLS policy was weakened.

## Hosted Auth configuration requirement

The currently available Supabase connector does not expose project Auth email-confirmation/SMTP mutation controls, so this repository change does not silently alter hosted Auth settings.

For a local demo, one of these must be true before arbitrary customer email signup can be expected to work:

1. configure a working custom SMTP/email confirmation path; or
2. explicitly disable Confirm Email in the Supabase Authentication email provider for the demo environment.

This is a project-configuration action, not a database migration.

## Validation still required locally

After pulling this branch, run the Flutter checks and retry signup on the actual phone. The new message should expose the concrete Auth-layer rejection if project email configuration is still blocking signup.
