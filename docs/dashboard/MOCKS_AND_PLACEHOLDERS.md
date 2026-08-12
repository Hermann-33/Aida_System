# POS/Admin Mocks and Placeholders Register

Updated: 2026-08-12

## No longer hardcoded in the implemented live auth/member path

- Admin Members does not read `PREVIEW_MEMBERS` and has no fixture fallback.
- Live admin password session source is Supabase Auth through the same-origin BFF.
- Admin member IDs/codes/type/student status/active/joined data come from the shared database RPC.
- Member points/stamps/reward values were removed from the trusted Members table because no loyalty backend exists.

Preview mode may still intentionally exercise preview auth/member UI for design/E2E closure; production builds reject preview mode.

## Still fixture/local until bounded backend tasks

- POS catalogue, prices, modifiers and availability.
- POS cart/order/payment/receipt/shifts/cash operations.
- Loyalty balances/rewards/vouchers and Rewards Activity.
- Employee roster/badge-PIN, branch assignments and manager approval.
- Branches/sales points/terminal enrolment and health.
- Inventory, marketing, reports/audit and most settings/integrations.

Promote none of these values mechanically. Each trusted domain requires a backend contract and authorization model.
