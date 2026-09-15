# Customer Mocks and Placeholders Register

Updated: 2026-09-15

This register distinguishes production data paths from intentional visual/sample content. Production must fail closed rather than silently substitute mock commercial/customer authority.

## Live production authority through Phase 7

The following are **not mocks** in production:

- Supabase Auth session and member/profile state;
- privacy preferences and whole-account deletion;
- shared catalogue, variants/options/add-ons and server prices;
- branch scheduling/pickup policy/capacity;
- authoritative quote/place and order history/status;
- inventory/recipe availability and placement-time depletion;
- loyalty points/stamps, rewards and vouchers through `SupabaseLoyaltyRepository`;
- voucher validation/discount/consumption;
- Phase 7 automatic promotion eligibility, promotion discount and immutable accepted promotion snapshots.

## Legacy/sample member content

Legacy preview/sample values may remain in mock repositories for previews/tests. The production providers are explicitly wired to Supabase repositories and must not fall back to mock member/loyalty data if the backend is unavailable.

## Marketing offers and promo cards

Home offer/promo presentation can contain curated or preview marketing content. Such cards are not proof of commercial eligibility and are not accepted discount authority. The only authoritative Phase 7 promotion outcome is returned by the order quote/place backend.

## Referral

Referral is intentionally preserved as a future draft surface. `AIDA_ENABLE_REFERRAL_DRAFT` defaults to false. It must not be exposed as a live production capability until its backend/privacy/abuse model is explicitly implemented and approved.

## Payments

Current customer orders do not have external processor capture/settlement authority. Any processor-like sample/placeholder must not imply a successful payment. External payment/refund UX is Phase 9.

## Legal/support/release presentation

In-app legal/support presentation exists, but final hosted public Privacy/Support URLs, App Privacy metadata, manifests, screenshots/review metadata and submission status are Phase 10 release work. Sample URLs or preview metadata must not be represented as production submission evidence.

## Removed stale deferrals

The following older placeholder labels are obsolete and must not be reintroduced:

- loyalty/rewards/vouchers as mock-only;
- account deletion as unavailable/draft-only;
- branch pickup policy/capacity as unmodeled;
- inventory/recipe enforcement as deferred;
- generalized order promotions as a future Phase 7 capability.

Those capabilities are implemented in the Phase 1–7 backend/runtime boundary.

## Governance

Historical redesign/audit documents may preserve the state at their original date. Current runtime truth is defined by this register, `STATE_AND_DATA_FLOW.md`, `UI_SCREEN_MAP.md`, `ACTIVE_CONTEXT.md`, shared contracts and current phase closeouts.
