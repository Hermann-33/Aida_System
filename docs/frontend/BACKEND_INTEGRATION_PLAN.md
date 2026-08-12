> Scope note: this is the customer-app backend-needs map. POS/Admin needs are in `docs/dashboard/BACKEND_INTEGRATION_PLAN.md`; shared rules are in `docs/contracts/SHARED_BACKEND_CONTRACT.md`.

# Customer Backend Integration Plan

This is a needs map, not a schema prescription.

| Area | Required backend behavior | Priority |
|---|---|---|
| Customer auth | sign-up/sign-in/recovery/session restore-refresh-revoke | MVP |
| Profile/member | owner-scoped profile, server-issued member code, verification workflow | MVP |
| QR | durable member-code display + authorized POS lookup | MVP |
| Catalogue | published categories/items/variants/modifiers/prices/availability/images | MVP |
| Quote | validate IDs/configuration and return authoritative totals/expiry | MVP |
| Orders | idempotent create, owner history, staff-driven status, receipt snapshot | MVP |
| Payments | trusted method/status/reference under approved provider/POS model | Needs decision/MVP |
| Loyalty | ledger balances, rewards/vouchers, atomic redemption/consumption | MVP |
| Promotions | published campaigns/eligibility/terms | Important |
| Notifications | consent/preferences and delivery/deep-link contract | Future |
| Storage | product/promo media; optional owner-scoped avatar | Important/Future |
| Errors | typed safe validation/auth/network/conflict/domain error mapping | MVP |
| Cache/offline | per-user member-code cache, catalogue cache, stale indicators; never authorize stale value | MVP/Important |

## Cross-client dependencies

Real customer ordering requires the separate POS/Admin system to read the same orders and perform authorized fulfilment transitions. QR/voucher use requires dashboard/POS member lookup and staff-authorized consumption. Catalogue IDs/prices must be exactly the same contract used by POS and admin editing.

## Sequence

Follow the project roadmap: shared database/security foundation -> auth/role/access -> catalogue -> quote/order/payment -> loyalty -> operations/hardening. Avoid a single “replace mock repository” change that crosses all trust boundaries at once.