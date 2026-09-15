# Phase 3 — iOS Data and Permission Audit

**Task:** `TASK-PRIVACY-001`  
**Date:** 2026-09-12  
**Verdict:** `COMPLETE` for the Phase 3 code boundary

## Reviewed surfaces

- `apps/customer/ios/Runner/Info.plist`
- `apps/customer/pubspec.yaml`
- Phase 3 customer privacy/account design

## Protected-data permissions

The current iOS `Info.plist` contains no usage-description keys for:

- camera;
- photo library;
- location;
- contacts;
- microphone;
- Bluetooth;
- calendars/reminders;
- tracking/ATT.

Phase 3 does not add any of those permissions.

## Dependency review

The current Flutter dependency set includes application/runtime packages such as Supabase, Riverpod, routing, QR rendering, shared preferences, timezone, video playback and sharing. It does not include a general permission broker, geolocation SDK, camera/image-picker SDK, contacts SDK or tracking/advertising SDK.

`qr_flutter` renders the customer membership QR; it does not require camera access. Phase 3 therefore does not add a camera purpose string merely because QR is present.

## Notifications

Phase 3 adds authoritative notification **preference state only**:

```text
marketing_notifications_enabled       default false
transactional_notifications_enabled   default true
```

No push-notification delivery SDK/provider or iOS notification authorization request is introduced by this phase. Marketing preference state must not be interpreted as device push permission; a future notification-delivery task must request OS permission only when the shipping delivery feature requires it.

## Tracking and advertising

Phase 3 adds no tracking SDK, advertising identifier access or ATT request. Marketing preference state is an account preference, not consent to cross-app tracking.

## Local data

The customer app uses local shared preferences for customer membership cache. Whole-account deletion invokes server deletion first and then removes the active customer cache best-effort during local session cleanup. The customer identity remains server-authoritative; local cache cannot recreate a deleted account.

## App Store impact

- No new protected-data permission disclosure is required by Phase 3 code.
- No ATT prompt is required by Phase 3 code.
- No StoreKit/IAP requirement is introduced; AIDA sells physical café goods.
- App Privacy answers must still be reconciled with the complete release build and all linked SDK manifests at the final release gate.
- If a later phase adds notifications, camera scanning, location, tracking or another protected capability, this audit must be reopened rather than silently inheriting this verdict.
