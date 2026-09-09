# AIDA Café Current State

**As of:** 2026-09-10

## Product topology

AIDA Café is one product across:

- Customer app: `Hermann-33/Aida_System` — Flutter / Dart / Riverpod — default `master`.
- POS/Admin Dashboard: `Hermann-33/Aida_System-Dashboard` — React / TypeScript / Vite — default `main`.
- Shared Supabase: project `Aida System`, ref `eswovqxqzfevcdwwcmuh`, region `ap-southeast-1`.

Canonical migrations live only in `Hermann-33/Aida_System/supabase/`.

## Latest integrated repository state

Customer default branch includes the audited customer redesign from PR #19, merge commit:

`5dac63de972d9a0761bc817c4ae9ad5079d9385c`

The accepted redesign keeps the AIDA visual system, adds/refines Splash, Home, Menu search, Item Detail, Cart, Order confirmation, Membership QR, Profile, Settings, Rewards and navigation, and removes all demo-only order/status/test tooling.

Useful but unfinished account-deletion/referral work is preserved safely:

- SQL prototypes live under `supabase/drafts/`, not canonical migrations.
- `AIDA_ENABLE_ACCOUNT_DELETION_DRAFT` defaults false.
- `AIDA_ENABLE_REFERRAL_DRAFT` defaults false.
- Dormant referral sharing uses `share_plus 11.1.0` to stay compatible with the current Android toolchain.

Customer release audit passed dependency resolution, Flutter analysis, non-golden regressions, golden regressions, release APK build and artifact upload before merge.

Dashboard default branch includes the validated menu-customization/Admin/POS integration at merge commit:

`b8e4b11dbc093106d4f62383dbb0d13ba85001b8`

## Live shared backend

Implemented live authority includes:

- Supabase Auth/member provisioning;
- trusted staff/admin role boundary;
- shared catalogue;
- catalogue revision invalidation;
- variants;
- per-drink Temperature and Sweetness option groups;
- per-product compatible add-ons;
- server-authoritative quote/order pricing;
- immutable line option/add-on snapshots;
- customer and POS order placement;
- idempotency;
- order history/detail;
- versioned status transitions;
- scheduled pickup policy and preparation window;
- customer owner-scoped order invalidation/refetch.

Customization quote/order contract uses `pricingVersion=2`.

Payment remains Pay at counter / unpaid. Loyalty, inventory, branch/terminal authority, cash shifts, promotions, tax/reporting and delivery remain deferred production domains.

## Backend drafts

`supabase/drafts/` contains preserved future work only. Draft account deletion/referral SQL is not applied migration history and must not be reported as live.

## Security/operations

RLS/FORCE-RLS and server authority remain mandatory.

The last recorded Supabase Security Advisor state has one pre-existing warning: leaked-password protection is disabled. Performance findings were INFO-only unused indexes on the small dataset.

## Current working rule

Before changing any shared concept—identity, member code, catalogue, pricing, modifiers, order lifecycle, payment, loyalty, inventory, branch/terminal scope, reporting, audit or migration behavior—inspect both repositories and the shared backend contract.

When current code/live Supabase evidence conflicts with old task notes, current evidence and accepted ADRs win.
