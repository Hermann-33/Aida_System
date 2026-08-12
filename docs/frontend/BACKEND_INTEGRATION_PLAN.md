# Customer Backend Integration Plan

Updated: 2026-08-12

## Implemented auth/member slice

- Supabase Auth sign-up/sign-in/recovery/session restore/logout.
- Auth trigger provisions `user_profiles` + `members`.
- Signed-in customer reads own profile/member under RLS.
- Member code is server-generated; signup cannot self-promote role/verification.
- Student declaration becomes pending until trusted review.
- Dashboard side now has source implementation for an admin/owner authenticated member directory through the same shared backend.

## Remaining customer backend work

- profile writes beyond current narrow read/bootstrap behavior as separately scoped;
- full student verification evidence/review UX;
- catalogue/availability/images;
- authoritative quote/order/payment;
- loyalty ledger/rewards/vouchers;
- promotions/notifications and cache/offline policy.

## Cross-client dependency

Auth/member source is implemented across both clients, but full-stack closure still requires a deployed dashboard BFF plus a trusted admin/owner identity and live customer-signup -> Admin Members E2E proof. Do not replace that with client fixtures or privileged browser credentials.
