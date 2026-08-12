> Scope note: customer Flutter mock register. Dashboard mocks are separately documented under `docs/dashboard/MOCKS_AND_PLACEHOLDERS.md`.

# Mocks and Placeholders Register

## No longer mock authority on TASK-AUTH-001 branch

The implemented auth/member path no longer uses `MockMemberRepository` as authority for:

- email/password sign-up/sign-in;
- password reset request;
- persisted auth session gate/logout;
- signed-in member ID/member code;
- member display name/email/student status.

These now come from Supabase Auth plus `user_profiles`/`members` under RLS. Signup no longer generates `m_<timestamp>` IDs or random member codes in Flutter.

## Still preview/mock authority

`MockMemberRepository` remains a deliberate temporary source for feature families outside TASK-AUTH-001:

- menu/category/size/add-on data, ratings, availability and prices;
- points/stamps/reward costs/reward catalogue;
- vouchers, offers, promos and related eligibility/display data.

Other local-only behavior still includes cart, order history, item configuration, payment selection, favourites and some profile-edit overlay state.

These values are not production authority. Each bounded backend task must remove the relevant preview source from the feature it implements.

## Visible placeholders

Social login, notifications, reward redeem, voucher apply, profile photo, full profile persistence, final production payment/order flows and authorized POS QR/member lookup remain incomplete.
