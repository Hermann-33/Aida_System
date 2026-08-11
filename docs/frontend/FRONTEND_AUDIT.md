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

There is no active staff/POS/admin module.

## Screen inventory

The inspected UI contains 17 screen/modal surfaces plus the shell/navigation frame. See `UI_SCREEN_MAP.md`. The older design spec’s 23-screen plan is not the current implementation: splash/bootstrap, verification pending, offer detail, redeem confirmation, separate voucher/stamp detail, change password, delete account, points ledger, and settings screens are absent or consolidated/placeholders.

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

### Helpful foundations

- `Money` uses integer sen.
- models avoid Flutter dependencies.
- `Result`/typed failures establish an error vocabulary.
- repository binding can be overridden in tests.
- async providers expose loading/data/error surfaces.
- tests cover cart arithmetic, navigation, checkout UI flow, categories, QR semantics, and visual baselines.

### Gaps before real integration

- Repository is too broad for reads yet too narrow for real writes.
- No DTO/serialization/client/cache/session layer.
- No centralized route/guard/deep-link model.
- No authoritative quote/order/loyalty operations.
- Offline QR comments promise storage that does not exist.
- Most typed failures are not produced/tested through an adapter.
- Large screens and the provider file couple navigation, presentation, and local business simulation.

## Blockers

1. Verified Supabase project/schema/migration/RLS foundation.
2. Identity/profile/member-code and role/verification decisions.
3. Approved menu, variant/modifier, price, reward, expiry, scheduling, and payment rules.
4. Staff/POS fulfillment and voucher-use workflow for customer ordering/loyalty completion.
5. Cache/offline and session-security design.
6. Golden-test review; current visual baselines fail on the audit toolchain.
7. Production assets, branding, signing, platform/toolchain, privacy/retention, and deployment decisions.

## Key risks

- UI models becoming an accidental database schema.
- Client-side price/order/loyalty trust and fraud.
- QR screenshot sharing and unverified staff handling.
- Shared-device data leakage after persistence is added.
- “Replace one repository class” underestimating missing write contracts and local calculations.
- Temporary content reaching production.
- PRD legacy claims being mistaken for current systems.

## Verification result

- Static analysis: one warning (`_stockChocolate` unused).
- Non-golden tests: 24/24 passed.
- Full test suite: four golden failures, with 4.13%–12.12% pixel differences.
- No automated fixes or golden updates were made.

## Recommended next task

After reviewing and accepting this documentation diff, run a dedicated **Supabase/database foundation audit and baseline**: verify the reset project, select migration workflow, establish initial identity/profile/member concepts, define RLS test conventions, and commit reproducible schema/config documentation. Do not wire customer features in the same task.
