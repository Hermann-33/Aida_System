# TASK-UI-REDESIGN-004 — Customer UI redesign audit

**Date:** 2026-09-09  
**Source branch:** `customer-app-redesign`  
**Integration branch:** `codex/task-ui-redesign-004-audit-integration`  
**Default branch:** `master`

## Integration decision

The source branch mixed production-ready UI work with useful but unfinished backend/domain work and developer demo tooling. The final integration therefore preserves all work that has credible future value, but separates **presence in source control** from **production activation**.

Three rules govern the merge:

1. accepted customer UI/branding changes are active normally;
2. future backend-dependent client paths are compile-time gated off by default;
3. developer/demo order tooling is retained under `kDebugMode` and is isolated from real persisted orders.

Unfinished SQL is preserved under `supabase/drafts/`, not `supabase/migrations/`, so normal migration replay/push tooling cannot silently deploy it.

## Accepted active UI changes

### Branding/startup

- refreshed Android and iOS launcher artwork;
- bundled AIDA splash video with tap-to-skip/fail-through;
- Splash receives the existing `AuthGate` as its destination and owns no auth state.

### Shared feedback

- `AidaPopup` provides a consistent top-overlay feedback treatment using existing AIDA colors/type.

### Home / Menu

- refreshed hierarchy, spacing and presentation;
- Menu search is local filtering over the authoritative catalogue snapshot;
- add-on catalogue rows remain excluded from ordinary product browsing.

### Item detail

- unified rounded-card language for Size, Temperature and Sweetness;
- Hot/Iced contextual icons where appropriate;
- availability/defaults/pricing remain catalogue-owned;
- compatible add-ons remain per-line;
- configured total is local estimate only;
- Add to cart still returns immediately to Menu.

### Cart / Checkout

- presentation refinements retained;
- authoritative quote-before-place remains unchanged;
- Schedule remains the accepted policy-derived wheel;
- no local opening-hours/capacity authority was introduced.

### Membership QR

- refreshed ticket/hero treatment;
- QR still encodes the trusted member code;
- default production action copies the member code;
- referral sharing is present but hidden unless `AIDA_ENABLE_REFERRAL_DRAFT=true`.

### Order confirmation

- refreshed image/background and liquid stage tracker;
- production order status still comes only from persisted backend snapshots + invalidation/refetch;
- demo status never overrides a real order.

### Profile / Settings / Rewards / Shell

- collapsing Profile header and bento actions;
- new Settings visual surface;
- refreshed Rewards ticket/voucher presentation;
- bottom navigation labels and safe-area spacing;
- Privacy and Terms remain explicitly unavailable until real destinations exist.

## Preserved future work

### Account deletion

Preserved prototype SQL:

`supabase/drafts/20260826120000_add_customer_account_deletion.sql`

Preserved prototype regression:

`supabase/drafts/tests/account_deletion_integration.sql`

The customer repository also retains the account-deletion repository/Auth/UI path behind:

`AIDA_ENABLE_ACCOUNT_DELETION_DRAFT=true`

Default production builds keep it disabled.

Before activation, the draft must be promoted through a dedicated privacy task with a new canonical migration timestamp, RLS/security review, executable regression, live advisor checks, anonymisation/retention review and deployed-backend validation.

### Referral / real points

Preserved prototype SQL:

`supabase/drafts/20260828120000_add_referral_program.sql`

Client signup metadata, referral field, referral sharing and real `points_balance` read are retained behind:

`AIDA_ENABLE_REFERRAL_DRAFT=true`

When enabled, failure to read the real balance produces an error; it does not silently substitute mock points.

The referral draft should still be reworked around the eventual authoritative loyalty ledger before production activation.

### iOS migration evidence

Potentially useful generated/toolchain observations from the source branch are recorded in:

`docs/frontend/IOS_TOOLCHAIN_DRAFT_2026-08-29.md`

The AppIcon artwork is accepted now. Generated Xcode/CocoaPods state is not copied blindly and must be regenerated/validated during the dedicated iOS/App Store release task.

## Preserved developer/demo work

The following are retained because they are useful for development and UI demonstrations:

- `DemoOrderProgress`;
- `OrderProgressCapsule`;
- `StaffDemoScreen`;
- Profile actions for Staff demo / Test error / Test popup.

They are exposed only when `kDebugMode` is true.

The demo provider creates synthetic `demo-test-*` orders only. The real cart placement flow does not inject persisted orders into the demo provider, and the production order confirmation screen does not consume demo state.

Therefore:

```text
real order
 -> Supabase status
 -> invalidation/refetch
 -> production UI
```

and separately:

```text
debug synthetic order
 -> DemoOrderProgress
 -> debug capsule/staff demo
```

The two state machines do not cross.

## Not carried forward as runtime changes

- deprecated Checkout animation regression;
- unrelated Dashboard sidebar documents in the customer runtime task;
- stale/generated iOS project state from a different toolchain;
- direct canonical deployment of the unfinished account/referral SQL.

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

## Validation and merge gate

PR #19 runs `.github/workflows/customer-release-audit.yml` against the final integration head.

Required before merge:

- dependency resolution PASS;
- Flutter analyze PASS;
- non-golden regressions PASS;
- golden suite/evidence reviewed;
- release APK build PASS;
- final diff contains no new canonical Supabase migration;
- future flags default false;
- demo tooling remains debug-only;
- real order state remains backend-authoritative.

## Merge strategy

The source history contains mixed/unaccepted commits. PR #19 must therefore be **squash-merged**, so `master` receives the final audited tree rather than the source branch's mixed commit ancestry.
