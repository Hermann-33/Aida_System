# Current Handoff

Updated: 2026-08-14

## Current task

`TASK-AUTH-006 — Android release APK network/Auth failure`

**Verdict:** PARTIAL pending physical-device validation.

Branch: `codex/task-auth-006-android-release-network`

Stack base: `codex/task-auth-004-runtime-access-fix`

Do not merge the stack out of order.

## Proven root cause and fix

The phone’s release APK could not resolve the Supabase hostname because the production Android manifest omitted `android.permission.INTERNET`. Debug/profile declared it only in their development overlays. The pre-fix Gradle release merged manifest independently proved the permission absent.

The main manifest now declares INTERNET before `<application>`. Auth retryable/socket/client/host-resolution failures now show a bounded connection message rather than raw exception/URL details, while genuine credential, email-confirmation, duplicate-signup, rate-limit and provisioning responses remain distinct.

No Supabase schema, RLS, identity, role, catalogue/order data or credential was changed. The Flutter client continues using the active project URL and public publishable key only.

## Validation

- Flutter 3.44.9
- `flutter pub get`: passed
- `flutter analyze`: no issues
- `flutter test`: 44/44 passed
- `flutter build apk --release`: passed with preserved local AGP/Gradle compatibility settings
- final `aapt dump permissions`: `android.permission.INTERNET` present
- APK path: `apps/customer/build/app/outputs/flutter-apk/app-release.apk`
- APK size: 63,863,395 bytes
- SHA-256: `3A7B5F027B846F4BE58865C09ABADBC63DD7B3EAE446331D708EA2FC67AF1201`

The repository currently pins AGP 8.7.0, while the resolved AndroidX artifacts require 8.9.1+. Preserved local compatibility settings were used only to package the APK and are deliberately excluded from this network-fix change. Reproducible release-toolchain alignment remains a separate bounded task.

## Exact next action

Manually transfer and install the recorded APK on the reporting Android phone. With an approved customer account, verify sign-in/session, member/profile and shared catalogue loading; then log out and perform a disposable customer signup if appropriate. Confirm specifically that `SocketException / Failed host lookup` no longer appears. Do not use employee demo identities as customer/member evidence and do not bypass email confirmation.

After device proof, mirror these shared task facts into the dashboard repository. Customer-only checkout scope prevented byte-for-byte mirrored documentation in this task.
