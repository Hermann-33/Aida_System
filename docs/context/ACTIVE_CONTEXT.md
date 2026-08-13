# Active Context

**As of:** 2026-08-14
**Current implementation task:** `TASK-AUTH-006 — Android release APK network/Auth failure`
**Current task verdict:** PARTIAL

## Current product reality

The shared Supabase identity/member, catalogue, ordering and scheduling boundaries remain unchanged. TASK-AUTH-006 is limited to Android release packaging and customer-safe Auth transport diagnostics.

The reported physical-phone release APK failed sign-in and sign-up with `SocketException: Failed host lookup` before any request reached Supabase. Audit proved that debug and profile manifests declared `android.permission.INTERNET`, while the main manifest and generated release merged manifest did not. Release builds do not merge the debug/profile overlays.

## TASK-AUTH-006 fix

Branch: `codex/task-auth-006-android-release-network`, stacked on `codex/task-auth-004-runtime-access-fix`.

- `apps/customer/android/app/src/main/AndroidManifest.xml` now declares `android.permission.INTERNET` before `<application>`.
- Retryable/network Auth failures map to `Unable to reach AIDA. Check your internet connection and try again.` without exposing raw exception, host or upstream details.
- Existing mappings for invalid credentials, unconfirmed email, duplicate signup, rate limits and provisioning remain distinct.
- Focused tests protect the production manifest and transport mapping.

The runtime still targets `https://eswovqxqzfevcdwwcmuh.supabase.co` with a public `sb_publishable_…` client key. No service-role/secret credential, database migration, RLS policy, Auth role or data was changed.

## Validation evidence

- Supabase project status: `ACTIVE_HEALTHY`; live URL matches the Flutter default.
- Pre-fix release merged manifest: INTERNET absent.
- Flutter 3.44.9 analyze: no issues.
- Flutter tests: 44/44 passed.
- Fresh post-fix release APK built and `aapt dump permissions` reports `android.permission.INTERNET`.
- APK: `apps/customer/build/app/outputs/flutter-apk/app-release.apk`, 63,863,395 bytes, SHA-256 `3A7B5F027B846F4BE58865C09ABADBC63DD7B3EAE446331D708EA2FC67AF1201`.
- No physical Android device was connected; only Windows, Chrome and Edge were detected and `adb devices` was empty.

The branch’s existing AGP 8.7.0 cannot package the currently resolved AndroidX artifacts, which require AGP 8.9.1+. The final APK was produced using preserved local build-tool compatibility settings that are not part of this scoped source fix. A separate bounded build-tool task should make fresh release builds reproducible before those settings are removed permanently.

## Remaining gate

Transfer/install the new APK on the reporting Android phone, verify the old host-lookup error does not recur, then use an approved customer identity to prove session establishment, member/profile load and shared catalogue load. Until physical-device Auth succeeds, ADR-0004 keeps TASK-AUTH-006 `PARTIAL`.
