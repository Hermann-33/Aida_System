# Customer UI Screen Map

Updated: 2026-09-15

**Current customer runtime boundary:** integrated through Phase 7.

| Surface | Auth | Current source / authority |
|---|---|---|
| Home | public + personalized elements | live shared catalogue; marketing offer/promo presentation is not accepted discount authority |
| Rewards | authenticated | live `SupabaseLoyaltyRepository` points, stamps, rewards and vouchers |
| Membership QR | authenticated | live member identity/presentation; QR rendering does not require camera permission |
| Menu / item detail | public | live shared catalogue, variants/options/add-ons |
| Cart / checkout | ordering identity as required | authoritative order quote for catalogue price, scheduling/capacity, inventory, voucher and automatic Phase 7 promotions |
| Order confirmation/history | authenticated | trusted placed-order snapshots and status/history |
| Profile / edit profile | authenticated | live member repository |
| Privacy settings | authenticated | live caller-bound privacy preferences |
| Settings | authenticated | profile, loyalty summary, orders, password reset, privacy, legal/support and whole-account deletion |
| Delete Account | authenticated | live caller-bound whole-account deletion; not feature-flagged |
| Terms / Support | public or reachable without unnecessary account creation | legal/support presentation; final hosted production URLs remain Phase 10 |

## Ordering UI contract

The customer UI may send item/variant/add-on choices, quantity/note, fulfilment/pickup intent, a client request ID and optional voucher intent. It does not send authoritative item prices, accepted promotion IDs, discount amounts, total, stock result or slot capacity.

Checkout trusts only the server quote. Through Phase 7 it presents separate voucher and promotion discount components and server-selected promotion snapshots. The accepted placed-order response remains authoritative even when promotion availability changed between quote and placement.

## Rewards and vouchers

Rewards are no longer a mock-only surface. Production providers load points, stamps, rewards and vouchers from caller-bound Supabase loyalty authority. Voucher use remains client intent; validation and one-time consumption occur server-side.

## Promotions

There is no requirement for the customer to manually select an accepted commercial promotion. Eligible active offers are resolved automatically by `quote_order` and revalidated at placement. Existing marketing promo/offer cards are presentation content and must not be treated as proof that a discount will apply.

## Scheduling and stock

Pickup timing/capacity is backend-owned. The UI presents authoritative scheduling results and does not infer branch capacity locally. Inventory/recipe availability is checked server-side; the customer has no stock mutation controls.

## Privacy / App Store account deletion

Settings contains an explicit Delete Account tile and confirmation flow. The action invokes the live deletion repository path and signs the app out/invalidates personalized providers after success. Historical café transactions may be retained only under the documented anonymised audit/accounting boundary.

## Current placeholders / later phases

- Referral remains draft-gated by `AIDA_ENABLE_REFERRAL_DRAFT` and defaults off.
- External processor payment/refund UX remains Phase 9.
- Final public legal/support URL verification, privacy manifests/labels, review metadata/screenshots/demo path and App Store submission are Phase 10.

Do not use older dated redesign/audit documents as current screen truth when they conflict with this map and the latest phase closeouts.
