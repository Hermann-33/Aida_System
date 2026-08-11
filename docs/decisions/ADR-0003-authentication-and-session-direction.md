# ADR-0003: Authentication and session direction

- **Status:** Accepted direction; implementation pending
- **Date:** 2026-08-11

## Context

Current authentication is a Riverpod boolean in `application/providers.dart`. `MockMemberRepository.logIn` accepts every attempt; the login UI deliberately skips validation for demo access. Sign-up returns success, then the frontend generates a member ID and QR/member code. Password reset always displays success without sending email. No token, persisted session, current-user bootstrap, secure storage, revocation, role authorization, or cache isolation exists.

The membership card comment says its member code comes from local storage, but no local-storage dependency or implementation exists. The QR currently depends on mock/session member state.

## Decision

Treat current auth as mock/session-local only. Real authentication will use Supabase Auth with:

- server-issued identity and a separately modelled profile/member record;
- startup session restoration and verified current-user bootstrap;
- refresh, expiry, revocation, logout, and deleted/disabled-account behavior;
- generic password-reset responses that do not disclose account existence;
- per-user cache isolation and cleanup on logout or user switch;
- durable local access to the minimum member-code material required for the approved offline QR experience;
- RLS/server authorization for profile ownership and operational roles.

Authorization must not rely on hidden UI, a local boolean, QR possession, or user-editable metadata. Staff/admin and verification attributes require trusted storage and freshness rules.

## Consequences

- Frontend-generated member IDs/codes must be removed from the real sign-up path.
- `AuthGate` must represent loading, signed-out, signed-in, and invalid/refresh-failed states rather than a boolean only.
- Logout must clear/isolate sensitive cached member data while respecting an explicitly approved offline QR policy.
- Auth, profile, member-code, verification, and role tests must include shared-device, cross-user, expired/revoked-session, offline, and account-deletion cases.
- Social sign-in buttons remain placeholders until providers, redirects, platform setup, and account-linking behavior are approved.

## Evidence

- `apps/customer/lib/application/providers.dart`
- `apps/customer/lib/data/repository/mock_member_repository.dart`
- `apps/customer/lib/features/auth/login_screen.dart`
- `apps/customer/lib/features/auth/widgets/forgot_password_sheet.dart`
- `apps/customer/lib/features/card/membership_card_screen.dart`
- absence of auth/storage packages in `apps/customer/pubspec.yaml`
