# TASK-CLOSEOUT-001 evidence — 2026-08-14

This file is a dated evidence record for the current AIDA Café integration tranche. Counts and revision numbers below are observations from 2026-08-14, not permanent architectural invariants.

## Integration branches and PRs

- Customer repository: `Hermann-33/Aida_System`
  - integration branch: `codex/task-closeout-001-tranche-completion`
  - integration PR: #13 -> `master`
- Dashboard repository: `Hermann-33/Aida_System-Dashboard`
  - integration branch: `codex/task-closeout-001-tranche-completion`
  - integration PR: #12 -> `main`

These integration PRs supersede the need to merge the earlier stacked task PRs individually once the closeout gates pass. They remain draft while the tranche verdict is `PARTIAL`.

## Live Supabase baseline

Project: **Aida System**

- project ref: `eswovqxqzfevcdwwcmuh`
- region: `ap-southeast-1`
- project state: active/healthy at closeout audit
- Auth users: 9
- `user_profiles`: 9
- active customer/member rows: 6
- trusted owner profiles: 1
- trusted admin profiles: 1
- trusted staff profiles: 1
- retained orders: 0
- catalogue revision: 15

The three employee identities are not customer/member rows. Trusted employee authority is `user_profiles.app_role` plus `disabled_at`; customer membership authority is `members`.

## Physical/manual E2E evidence supplied by the user

The user completed the following validation against the real local-dashboard/cloud-Supabase/installed-phone setup:

1. Installed the rebuilt Android release APK containing the TASK-AUTH-006 networking fix.
2. Signed up as a new customer from the physical phone successfully.
3. The signup provisioned a real Supabase Auth identity, trusted customer profile and member row.
4. The new customer appeared in Dashboard Members through the protected Admin/owner path.
5. A real Owner account changed a catalogue price in Dashboard Admin Menu.
6. The installed customer app observed the changed catalogue price.

This closes the previously open physical Android transport/Auth gate and the customer-signup -> Dashboard Members and Admin catalogue mutation -> customer refresh gates.

No test password is stored in repository documentation. Demo/test passwords remain operator-held test credentials and must not be committed.

## Android release networking evidence

TASK-AUTH-006 proved that `android.permission.INTERNET` was absent from the pre-fix release merged manifest because only debug/profile manifests declared it. The main manifest now declares INTERNET.

Validated artifact from TASK-AUTH-006 before the physical user test:

- APK path: `apps/customer/build/app/outputs/flutter-apk/app-release.apk`
- size: 63,863,395 bytes
- SHA-256: `3A7B5F027B846F4BE58865C09ABADBC63DD7B3EAE446331D708EA2FC67AF1201`
- final APK permission check: `android.permission.INTERNET` present
- Flutter analyze: pass
- Flutter tests: 44/44 pass

The user subsequently installed that fixed release path and successfully reached Supabase signup. The old host-resolution failure is therefore no longer an open product-runtime gate.

One build-engineering issue remains during closeout: the committed Android configuration still pins AGP 8.7.0 while the currently resolved AndroidX dependency set requires AGP 8.9.1+. The successful TASK-AUTH-006 APK used preserved local compatibility settings. TASK-CLOSEOUT-001 must make release APK production reproducible from committed Git without stash/local-only overrides before merge.

## Auth/member state

Implemented and validated:

- Supabase Auth is identity authority.
- Public signup is forced to customer role.
- User-editable metadata cannot self-grant staff/admin/owner, member code or verified student state.
- Member codes are generated server-side.
- Student self-declaration can create pending status only.
- Customer member/profile reads are owner-scoped.
- Admin/owner member-directory access uses trusted role checks and caller identity.
- Dashboard privileged browser sessions remain same-origin HttpOnly sessions; staff bearer tokens are not exposed to React.
- TASK-AUTH-005 preview/live Admin session-loop regression is fixed and fully tested on the dashboard branch.

## Catalogue state

Implemented and validated:

- shared catalogue authority is Supabase;
- customer and Dashboard POS browse the same published catalogue;
- Admin mutations use protected BFF + caller JWT + RLS/RPC boundaries;
- variants/add-ons/prices/availability/publication are backend-driven;
- `catalogue_revision` is the invalidation signal;
- customer runtime has no hardcoded production menu fallback;
- the latest closeout baseline was revision 15;
- live catalogue audit evidence includes a real Owner mutation.

The physical user test proved Dashboard price mutation -> Supabase -> installed customer app refresh.

## Ordering/scheduling state

Implemented before closeout:

- authoritative quote engine;
- customer and POS placement RPCs;
- immutable commercial snapshots;
- idempotent placement;
- ASAP/scheduled pickup policy;
- persisted fulfilment state machine;
- order audit events;
- customer owner-scoped order reads and Realtime invalidation;
- customer Flutter quote/place/history/detail/status integration;
- dashboard same-origin order BFF/API endpoints.

At the 2026-08-14 baseline, retained live order count was 0. The missing tranche work is Dashboard React authoritative POS quote/place/order-board/status integration plus the final customer placement -> staff transition -> customer authorized refresh E2E proof.

## Security evidence

The current security advisor no longer has a zero-finding result. It reports one hosted Auth configuration warning:

- `auth_leaked_password_protection` — leaked-password protection disabled.

This is project-level Auth configuration debt, not an RLS/schema regression. Source code must not weaken Auth to work around it. Remediation is to enable Supabase leaked-password protection in the hosted Auth settings when appropriate.

Current implementation still prohibits:

- service-role/secret keys in browser/mobile code;
- browser-readable employee bearer-token persistence;
- client authority for roles/member codes/prices/totals/order numbers/status/payment/loyalty/inventory;
- direct customer order-table DML;
- frontend-only authorization in place of server/RLS checks.

## Remaining closeout gates

TASK-CLOSEOUT-001 remains `PARTIAL` until:

1. Android release builds reproducibly from committed Git in a clean checkout/worktree.
2. Dashboard React uses the authoritative order BFF for POS quote/place and live order queue/status transitions.
3. The customer-place -> staff-status -> customer authorized refresh path is proven end-to-end.
4. Full customer/dashboard toolchains pass on the final integration heads.
5. Shared mirrored documentation is reconciled after the implementation commits land.
6. Final diffs, mergeability and security/secret scans pass.

Hosted Vercel deployment is separate operational debt for this local-PC + cloud-Supabase + installed-phone demo workflow unless a later accepted requirement makes hosted deployment part of the completion gate.
