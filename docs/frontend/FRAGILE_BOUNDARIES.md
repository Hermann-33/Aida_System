> Scope note: customer Flutter fragile boundaries. Dashboard boundaries are under `docs/dashboard/FRAGILE_BOUNDARIES.md` when present.

# Fragile Boundaries

Updated: 2026-08-20

## Highest-risk customer areas

- `lib/application/providers.dart`: Auth/member/catalogue/order repository bindings and session-scoped invalidation converge here.
- `lib/domain/repository/member_repository.dart`: Auth and member identity port; never expand cached member material into role, verification, loyalty or price authority.
- `lib/data/repository/mock_member_repository.dart`: remaining loyalty/presentation demo values must never be wired as production identity, catalogue or order fallbacks.
- `lib/main.dart`: root Auth lifecycle and public Supabase client initialization.
- `features/shell/app_shell.dart`: indexed tab lifetime/floating cart.
- `domain/model/cart.dart` and `features/cart/cart_screen.dart`: local selection/estimate state must remain distinct from server quote and placement authority.
- order checkout/history/confirmation: idempotency keys, schedule-policy interpretation, immutable snapshots and persisted status must stay server-backed.
- membership-card cache: only minimum member identity material may restore offline, isolated by Supabase user ID and cleared on logout/user switch.
- Android main manifest/toolchain: production networking and clean-checkout release compatibility are regression-protected boundaries.
- large Home and item-detail screens: local state/calculation/navigation coupling.
- golden baselines: review visual differences before updating.

## Redesign-specific regression boundaries

### Menu catalogue authority

The redesigned Menu may change layout/components but must continue to consume the shared Supabase catalogue. `MenuListItem` must prefer the server-provided `MenuItem.imageUrl` and use bundled category artwork only as fallback. Category artwork must never become a substitute source for product identity, availability or pricing.

Stable Menu automation keys are intentionally retained on `MenuCategoryRail` (`menu_cat_all`, `menu_cat_favorites`, `menu_cat_<category-id>`). Removing them silently weakens golden/interaction coverage.

### Cart and quote authority

The item-detail running total, floating-cart amount and Cart subtotal are local estimates only. Visual prominence must not turn them into placement authority. Checkout must continue to render a server quote before placement, and the cart clears only after a persisted `OrderSnapshot` success.

Swipe-to-remove is local cart interaction only. It must not introduce an order-delete/cancel API side effect.

### Scheduling

The wheel selector is presentation over `derivePickupSlots(OrderingPolicy)`. Do not add local opening-hours constants, arbitrary minute values, branch-capacity guesses or device-clock-only eligibility. `quote_order` remains the server validator even for a value shown by the client.

### Rewards

The redesigned balance card displays real member identity through `displayedMemberProvider`, but points/rewards/vouchers are still preview-backed through `MockMemberRepository`. Do not infer or implement loyalty authority merely because the screen now mixes real member identity with polished loyalty presentation.

### Membership QR and shared assets

`AidaLogo` is shared presentation and is already consumed by Membership QR. Logo changes therefore affect an offline-critical surface even when `membership_card_screen.dart` itself is untouched. Keep logo assets bundled/offline-safe and never alter the QR payload from the server-owned member code for visual reasons.

### Visual tests

Redesign work commonly invalidates pixel baselines and selector assumptions. Fix stale selectors/testability first. Golden files may be updated only after deliberate inspection of the candidate render; never replace them merely to turn CI green.

## Contract-sensitive assumptions

Reward ladder, narrow student states and payment-method labels must not become shared schema by accident. Catalogue identifiers/variants/add-ons, permanent member code, ordering policy, trusted totals and order status already have accepted server contracts and must not be shadowed by client constants.

The completed live order E2E does not relax these boundaries: customer payloads remain intent-only, server totals/status remain authoritative and customer status changes arrive through authorized backend state.

## Cross-repo rule

Any change to member code, verification, catalogue IDs/pricing/modifiers, order status, payment semantics, rewards/vouchers or promotions must be reviewed against the POS/Admin consumer before completion.

See `UI_REDESIGN_AUDIT_2026-08-20.md` for the redesign-specific backend-impact matrix.

## 2026-09-09 preserved future-work boundaries

- `core/config/feature_flags.dart`: account-deletion/referral client paths must stay disabled by default until their backend tasks are deployed and validated.
- `supabase/drafts/`: prototype/reference SQL only. Never promote a draft into canonical migrations without a dedicated task, fresh timestamp and full migration/security validation.
- `features/cart/order_confirmation_screen.dart`: persisted backend status remains authoritative; no demo/local status substitute exists.
- Membership referral sharing must remain gated until the referral/loyalty backend is deployed.
- Account deletion UI must remain gated until the deletion/anonymisation backend is promoted and live.
- Demo order-progress/test tooling was deliberately removed from TASK-UI-REDESIGN-004 and must not be reintroduced into customer production paths.

