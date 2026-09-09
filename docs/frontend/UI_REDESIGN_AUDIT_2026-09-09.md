# TASK-UI-REDESIGN-004 — Customer UI redesign audit

**Date:** 2026-09-09  
**Source branch:** `customer-app-redesign`  
**Integration branch:** `codex/task-ui-redesign-004-audit-integration`  
**Default branch:** `master`

## Final integration decision

The source branch mixed three categories of work:

1. production customer UI/branding changes;
2. useful but unfinished privacy/referral/loyalty backend work;
3. developer/demo order-progress and test tooling.

The final integration policy is:

- **merge the reviewed UI/branding work;**
- **preserve useful future backend/client work in a dormant, non-deployed form;**
- **drop all demo-only order/status/test tooling.**

No unfinished SQL is placed in canonical `supabase/migrations/`.

## Accepted active UI changes

### Branding/startup

- refreshed Android and iOS launcher artwork;
- bundled AIDA splash video with tap-to-skip/fail-through;
- Splash receives the existing `AuthGate` as its destination and owns no Auth state.

### Shared feedback

- `AidaPopup` provides consistent AIDA-styled transient customer feedback.

### Home / Menu

- refreshed hierarchy, spacing and presentation;
- Menu search is local filtering over the authoritative catalogue snapshot;
- add-on catalogue rows remain excluded from normal product browsing.

### Item detail

- unified rounded-card language for Size, Temperature and Sweetness;
- contextual Hot/Iced iconography where appropriate;
- availability/defaults/pricing remain catalogue-owned;
- compatible add-ons remain per-line;
- configured totals remain estimates;
- successful Add to cart still returns immediately to Menu.

### Cart / Checkout

- presentation refinements retained;
- authoritative quote-before-place remains unchanged;
- Schedule remains the accepted policy-derived wheel;
- no local opening-hours/capacity authority is introduced.

### Membership QR

- refreshed ticket/hero treatment;
- QR still encodes the trusted server-owned member code;
- normal production behavior copies the member code;
- referral sharing exists only behind the dormant referral feature flag.

### Order confirmation

- refreshed background and liquid-stage tracker;
- status is driven exclusively by persisted backend order snapshots and normal invalidation/refetch;
- no local demo order-state provider exists in the final integration.

### Profile / Settings / Rewards / Shell

- collapsing Profile header and bento actions;
- new Settings visual surface;
- refreshed Rewards ticket/voucher presentation;
- bottom-navigation labels and safe-area spacing;
- Privacy and Terms remain explicitly unavailable until real destinations exist.

## Preserved useful future work

### Account deletion

Prototype SQL:

- `supabase/drafts/20260826120000_add_customer_account_deletion.sql`
- `supabase/drafts/tests/account_deletion_integration.sql`

The customer repository also preserves the account-deletion repository/Auth/Settings path behind:

`AIDA_ENABLE_ACCOUNT_DELETION_DRAFT=true`

The flag defaults to false.

Before production activation, the SQL must be promoted in a dedicated privacy task with a new canonical migration timestamp, migration replay/regression validation, RLS/security review, retention/anonymisation review, live advisor checks and deployed-backend validation.

### Referral / real points

Prototype SQL:

- `supabase/drafts/20260828120000_add_referral_program.sql`

Signup referral metadata, referral-code UI/sharing and the real `points_balance` read are preserved behind:

`AIDA_ENABLE_REFERRAL_DRAFT=true`

The flag defaults to false.

When the real-points path is enabled, backend failure produces an explicit error rather than silently substituting mock points.

The referral draft should still be reworked around the eventual authoritative loyalty ledger before production activation.

### iOS migration evidence

Potentially useful generated/toolchain observations from the source branch are preserved in:

`docs/frontend/IOS_TOOLCHAIN_DRAFT_2026-08-29.md`

The AppIcon artwork is accepted now. Generated Xcode/CocoaPods state must be regenerated and validated from current `master` during the dedicated iOS/App Store release task.

## Demo work deliberately dropped

The final integration does **not** contain:

- `DemoOrderProgress`;
- `OrderProgressCapsule`;
- `StaffDemoScreen`;
- Staff demo / Test error / Test popup Profile controls;
- demo capsule artwork;
- any path that manufactures customer order status locally.

Production order state remains:

```text
real order
 -> Supabase persisted status
 -> owner-scoped invalidation/refetch
 -> customer UI
```

## Other rejected runtime changes

- deprecated Checkout animation regression;
- unrelated Dashboard sidebar documents;
- stale/generated iOS project state from a different toolchain;
- direct canonical deployment of unfinished account/referral SQL;
- generated golden failure artifacts.

## Theme audit

The active redesign remains within the AIDA customer language:

- cream/ivory background;
- coffee/burgundy accent;
- espresso text;
- blush/latte secondary surfaces;
- Playfair Display hierarchy;
- Plus Jakarta Sans UI/body;
- rounded cards and tactile/neumorphic primary controls.

Settings uses a scoped low-saturation pastel utility palette while remaining inside the cream/coffee shell.

The source branch's bright-blue membership action was replaced by AIDA coffee/latte/caramel styling.

## Trust-boundary result

The final active production path changes no canonical Supabase migration, RLS policy, order-pricing authority, scheduling authority or persisted-status authority.

Draft privacy/referral work is present in source control but cannot be deployed by normal migration replay/push because it is outside `supabase/migrations/`. Related client surfaces default off through compile-time environment gates.

## Validation and merge gate

PR #19 runs `.github/workflows/customer-release-audit.yml` against the final integration head.

Required before merge:

- dependency resolution PASS;
- Flutter analyze PASS;
- non-golden regressions PASS;
- golden suite/evidence reviewed;
- release APK build PASS;
- no new canonical Supabase migration;
- future backend feature flags default false;
- no demo order/status/test tooling;
- real order status remains backend-authoritative.

## Merge strategy

PR #19 must be **squash-merged**. The original source history contains mixed UI/backend/demo commits; squash merge gives `master` only the final audited tree.
