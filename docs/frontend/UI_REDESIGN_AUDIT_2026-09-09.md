# TASK-UI-REDESIGN-004 — Customer UI redesign audit

**Date:** 2026-09-09  
**Source branch:** `customer-app-redesign`  
**Integration branch:** `codex/task-ui-redesign-004-audit-integration`  
**Default branch:** `master`  
**Scope:** customer Flutter presentation only

## Audit verdict

The source branch was **not merge-safe as-is** even though its primary intent was a customer UI refresh.

Relative to `master`, it also contained:

- unapplied customer-account-deletion and referral Supabase migrations;
- referral/points client integration coupled to those unapplied migrations;
- a local demo order-progress provider that could override the real persisted order status;
- a customer-visible Staff demo and developer test controls;
- unrelated iOS toolchain/generated-project churn;
- unrelated Dashboard sidebar planning documents;
- a regression from the accepted checkout animation implementation.

Those changes were excluded from this UI integration.

The integration branch retains only the reviewed presentation delta plus tests/assets needed by that presentation.

## Accepted presentation changes

### App startup and branding

- bundled AIDA splash video with fail-through/tap-to-skip behavior;
- refreshed Android/iOS launcher artwork;
- startup still hands off to the existing `AuthGate`; Splash owns no authentication state.

### Shared feedback

- new `AidaPopup` top overlay replaces scattered customer SnackBar presentation;
- popup uses the existing cream/coffee/espresso/gold type and surface language;
- popup state is transient UI only.

### Home

- refreshed layout/spacing and visual hierarchy;
- existing catalogue and loyalty/provider boundaries are unchanged;
- favorites remain local presentation state.

### Menu

- search field added as local filtering over the already-authoritative catalogue snapshot;
- category/favorites browsing remains catalogue/local presentation;
- add-on catalogue rows remain excluded from normal product browsing.

### Item detail

- Size, Temperature and Sweetness use one consistent rounded choice-card language;
- Hot/Iced may show context icons; availability/default/pricing still comes from the catalogue;
- add-ons remain per-line catalogue compatibility;
- local configured total remains an estimate;
- successful Add to cart still returns immediately to Menu.

### Cart

- presentation/spacing refinements retained;
- line identity, option/add-on state and quote-before-place behavior are unchanged;
- cart still clears only after persisted placement succeeds.

### Membership QR

- refreshed ticket/hero treatment;
- QR payload remains the server-owned member code and continues to support the existing offline-critical path;
- the new corner action copies the existing member code to the clipboard; it does **not** claim or implement a referral program.

### Order confirmation

- refreshed background and liquid-stage tracker presentation;
- the tracker consumes the real persisted `OrderSnapshot.status`;
- no local timer/provider can manufacture Preparing/Ready/Completed.

### Profile and Settings

- Profile receives a collapsing header/bento presentation and clearer Settings entry;
- developer-only Staff demo/Test error/Test popup rows from the source branch are excluded;
- Settings is presentation over existing providers/actions;
- Privacy and Terms are explicitly disabled as `Coming soon`;
- no account-deletion action is included until the backend deletion contract is separately approved and implemented.

### Rewards

- refreshed voucher/ticket presentation;
- existing mixed-data boundary remains explicit: trusted member identity plus deferred/mock loyalty surfaces where already documented;
- redemption does not become authoritative through the redesign.

### Shell/navigation

- existing five-tab architecture remains;
- nav buttons gain visible text labels and improved safe-area clearance;
- floating cart remains local intent/estimate presentation;
- the source branch's demo order-progress capsule is excluded.

## Explicitly rejected from the source branch

The audited integration does **not** include:

- `20260826120000_add_customer_account_deletion.sql`;
- `20260828120000_add_referral_program.sql`;
- `account_deletion_integration.sql`;
- referral-code signup UI;
- real `points_balance` reads/fallback logic introduced by the referral draft;
- customer account deletion RPC/UI;
- `DemoOrderProgress`, `OrderProgressCapsule`, or `StaffDemoScreen`;
- developer-only Profile test controls;
- the bright-blue referral/share action;
- unrelated Dashboard sidebar docs;
- unrelated iOS generated/toolchain changes;
- the deprecated checkout `axisAlignment` regression.

## Trust-boundary result

The integration branch changes no canonical Supabase migration, RPC, RLS policy, customer Auth repository contract, order repository contract, pricing authority, scheduling authority, or persisted status authority.

The accepted order boundary remains:

```text
customer selection
 -> authoritative quote
 -> persisted placement
 -> backend order status
 -> owner-scoped invalidation/refetch
 -> customer UI
```

No client-only substitute is permitted in that chain.

## Theme review

The accepted delta continues to use the AIDA customer language:

- cream/ivory page surfaces;
- coffee/burgundy primary accent;
- espresso text;
- blush/latte secondary surfaces;
- Playfair Display for display hierarchy;
- Plus Jakarta Sans for interface/body copy;
- rounded cards/controls and soft shadows;
- existing tactile/neumorphic primary controls.

The redesigned Settings surface introduces a scoped muted pastel utility palette (lavender/tan/mauve/sage/mustard). It remains low-saturation and subordinate to AIDA's cream/coffee shell rather than becoming a competing app-wide theme.

A bright blue membership action present in the source branch was rejected and replaced with AIDA coffee/latte/caramel tokens.

## Validation

Final executable validation is performed by `.github/workflows/customer-release-audit.yml` against the PR head.

**Final run:** pending at time of initial audit write.

The merge gate is:

- dependency resolution PASS;
- Flutter analyze PASS;
- non-golden regressions PASS;
- golden differences deliberately reviewed;
- release APK build PASS;
- no backend/trust-boundary regression in final diff.

## Merge strategy

Because the source branch history contains unrelated/non-accepted backend commits, the audited PR must be **squash-merged**.

This ensures `master` receives only the final reviewed UI diff, not the source branch's rejected commit ancestry.
