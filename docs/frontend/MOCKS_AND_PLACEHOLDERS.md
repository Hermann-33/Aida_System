> Scope note: customer Flutter mock register. Dashboard mocks are separately documented under `docs/dashboard/MOCKS_AND_PLACEHOLDERS.md`.

# Mocks and Placeholders Register

`MockMemberRepository` is the active customer adapter and supplies synthetic latency plus hardcoded identity, menu, pricing, loyalty, rewards, vouchers, offers and promotions.

## Customer mock authority that must move server-side

- authentication/session and sign-up member provisioning;
- member IDs/member codes and student verification;
- menu/category/size/add-on data, availability, ratings and prices;
- points/stamps/reward costs/voucher state/offer eligibility;
- cart quote/line/subtotal/total;
- order number/timestamp/status/receipt/history;
- payment acceptance/status;
- reward/voucher issue/use/expiry decisions.

## Local/session-only behavior

Auth boolean, profile edits, selected navigation/filter state, favourites, cart, order history, item configuration, payment selection and daily check-in. Logout does not explicitly clear all stores.

## Visible placeholders

Social login, notifications, reward redeem, voucher apply, profile photo, stats/settings/invite/help, final logo, web scaffold metadata and Android release signing remain incomplete/placeholder areas.

## Important UI-shaped assumptions

Current customer prototype uses fixed categories, add-ons as menu items, uniform size deltas, narrow reward ladder, permanent displayable member code, limited student/order status models and temporary Unsplash images. Do not map these mechanically to database tables/enums.

UI correlation/idempotency/cache metadata may remain client-generated only where the shared contract explicitly allows it.