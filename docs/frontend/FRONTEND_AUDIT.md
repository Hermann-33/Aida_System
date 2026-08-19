> Scope note (2026-08-12): this audit describes the customer repository `Hermann-33/Aida_System` and preserves the TASK-WF-001 customer baseline. Project-wide current truth, including the separate POS/Admin repository and later Supabase foundation, is in `docs/context/`, `docs/contracts/`, and ADR-0006/0007. For the 2026-08-19 presentation-layer redesign of Menu/Item detail/Cart/Checkout sheet/Rewards, see `docs/frontend/UI_REDESIGN_SPEC.md`; this file's findings are left as originally written and are not updated by that redesign.

# Frontend Audit

## Executive summary

The repository contains one polished Flutter customer prototype with a coherent visual system, Riverpod state, typed domain models, useful tests, and a repository interface. It does not contain a real backend integration. The only adapter is `MockMemberRepository`; all durable/operational features are absent.

The most important distinction is visual completeness versus system completeness. Sign-in, membership QR, cart, payment selection, tracking, history, and rewards look functional, but identity, data, money, loyalty, payment, and order state are mock or process-local. No POS/staff/admin application exists to fulfill the flows.

## Framework and runtime

| Area | Finding | Evidence |
|---|---|---|
| Framework | Flutter 3.44.7 audit toolchain; Dart 3.12.2 | command output, `apps/customer/pubspec.yaml` |
| UI | Material 3 with custom AIDA Rose theme | `lib/main.dart`, `lib/core/theme/` |
| State | Riverpod 3 | `pubspec.yaml`, `lib/application/providers.dart` |
| Routing | `AuthGate`, tab `IndexedStack`, imperative `Navigator` routes | `main.dart`, `features/shell/app_shell.dart`, screen files |
| Targets | Android, iOS, web source | committed platform folders |
| Desktop | No committed Windows runner | repository inventory |
| Backend | None in repository | inventory/search |
| Supabase | No package/client/config/migration | `pubspec.yaml`, inventory/search |

`go_router` is a declared but unused dependency.

## Active modules

- Unified auth/sign-up and password-reset sheet.
- Five-tab customer shell: Home, Rewards, My QR, Menu, Profile.
- Menu item customization, favorites, cart, payment-method sheet, mock order tracking.
- Session order history and receipt detail.
- Profile and session edit form.
- Shared theme, product-image fallback, interaction animation, category, ticket, QR, and status widgets.

There is no active staff/POS/admin module in the customer repository.

## Screen inventory

The inspected UI contains 17 screen/modal surfaces plus the shell/navigation frame. See `UI_SCREEN_MAP.md`.

## Data-flow summary

```text
screen/widget
  -> Riverpod provider or local State
  -> MemberRepository (reads/auth only)
  -> MockMemberRepository
  -> hardcoded Dart values

cart/order/profile/favorites/check-in writes
  -> Riverpod/widget memory only
  -> no repository/API/database
```

The repository abstraction is helpful but incomplete. It has no profile update, redemption, quote, order create/history/status, favorite persistence, check-in, or voucher-use operations.

## Mock/local/session-only behavior

- Any sign-in attempt succeeds; no credential validation/session token.
- Sign-up generates member ID/member code in the client.
- Password reset waits and displays success without sending email.
- Member, menu, images, prices, ratings, loyalty, vouchers, offers, and promotions are demo data.
- Profile edits, favorites, cart, and history are process-local.
- Daily check-in is widget-local and pre-seeded from the weekday.
- Cart price and order total are computed locally.
- Payment methods record a label only; no processor/POS interaction.
- Order number is random; tracking advances every two seconds; stored orders are always `ready`.
- Rewards redemption and apply actions display messages only.

See `MOCKS_AND_PLACEHOLDERS.md`.

## Integration readiness

Helpful foundations include integer-sen `Money`, Flutter-independent models, typed failures, overridable repository binding, async provider states, and tests for cart/navigation/QR/UI. Gaps include DTO/serialization, auth/session/cache, authoritative quote/order/loyalty operations, offline member-code storage, real adapter errors and large coupled provider/screen files.

## Verification result

- Static analysis: one warning (`_stockChocolate` unused).
- Non-golden tests: 24/24 passed.
- Full test suite: four golden failures.
- No automated fixes or golden updates were made.

The later project-level next tasks are governed by `docs/context/ROADMAP.md`, not this historical recommendation.