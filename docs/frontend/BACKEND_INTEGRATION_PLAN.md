# Customer Backend Integration Plan

Updated: 2026-08-14

## Customer account/member — integrated and validated

The customer app uses the shared Supabase project for customer session creation/restoration and trusted profile/member provisioning. Member codes are server-owned; customer reads remain owner-scoped; the minimum offline cache is limited to member-code material.

TASK-AUTH-006 fixed Android release networking. The user installed the fixed release app, created a real customer and observed the resulting member in Dashboard Members.

## Catalogue — integrated and validated

Customer menu data comes from the shared catalogue snapshot. Publication, availability, prices, variants and compatible add-ons are backend data. `catalogue_revision` invalidates/refetches the snapshot.

The user validated a real Owner catalogue price change in Dashboard Admin Menu and observed the updated value in the installed customer app.

## Ordering — customer integration implemented

Customer Flutter uses the authoritative order policy/quote/place/history/detail boundaries and owner-scoped order invalidation.

Current rules:

- cart is selection intent, not commercial authority;
- backend quote totals win;
- customer/member identity derives server-side;
- ASAP and scheduled pickup follow server policy;
- one `clientRequestId` is reused for retries of the same placement intent;
- cart clears only after successful persisted placement;
- server order number/schedule/status replace local authority;
- history/detail come from backend snapshots;
- no local timer creates fulfilment status;
- payment presentation is Pay at counter / unpaid only.

Current scheduling defaults are Asia/Kuala_Lumpur, 15-minute minimum lead, 15-minute slots and 7-day maximum advance. Branch hours/capacity are not modeled.

## Android build closeout

The fixed APK physically reaches Supabase, but the release build still needs to become reproducible from committed build configuration. TASK-CLOSEOUT-001 must align the Android build toolchain and prove a clean-worktree release build.

## Existing validation

- Flutter analyze and full tests passed on TASK-AUTH-006.
- Final APK declared Android INTERNET permission.
- Physical Android customer creation succeeded.
- New customer appeared in protected Dashboard Members.
- Dashboard catalogue mutation propagated to the installed customer app.
- Customer order-focused tests previously covered quote/schedule/idempotency/cart/history/status/invalidation behavior.

See `docs/context/CLOSEOUT_EVIDENCE_2026-08-14.md` for dated evidence.

## Remaining customer closeout gates

1. Reproducible clean-worktree Android release build.
2. Final Flutter/backend/security checks on the closeout head.
3. Dashboard order frontend completion.
4. Customer placement -> Dashboard status transition -> customer authorized refresh E2E.
5. Final mirrored documentation reconciliation.

Deferred domains remain loyalty, trusted payment/refunds, inventory, reporting, branch-specific scheduling/capacity and other roadmap work.
