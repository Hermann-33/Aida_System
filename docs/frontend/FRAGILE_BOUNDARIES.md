> Scope note: customer Flutter fragile boundaries. Dashboard boundaries are under `docs/dashboard/FRAGILE_BOUNDARIES.md` when present.

# Fragile Boundaries

Updated: 2026-08-17

## Highest-risk customer areas

- `lib/application/providers.dart`: Auth/member/catalogue/order repository bindings and session-scoped invalidation converge here.
- `lib/domain/repository/member_repository.dart`: Auth and member identity port; never expand cached member material into role, verification, loyalty or price authority.
- `lib/data/repository/mock_member_repository.dart`: remaining loyalty/presentation demo values must never be wired as production identity, catalogue or order fallbacks.
- `lib/main.dart`: root Auth lifecycle and public Supabase client initialization.
- `features/shell/app_shell.dart`: indexed tab lifetime/floating cart.
- `domain/model/cart.dart` and `features/cart/cart_screen.dart`: local selection/estimate state must remain distinct from server quote and placement authority.
- order checkout/history/confirmation: idempotency keys, schedule-policy interpretation, immutable snapshots and persisted status must stay server-backed.
- membership-card cache: only member ID/code may restore offline, isolated by Supabase user ID and cleared on logout/user switch.
- Android main manifest/toolchain: production networking and clean-checkout release compatibility are regression-protected boundaries.
- large Home and item-detail screens: local state/calculation/navigation coupling.
- golden baselines: review visual differences before updating.

## Contract-sensitive assumptions

Reward ladder, narrow student states and payment-method labels must not become shared schema by accident. Catalogue identifiers/variants/add-ons, permanent member code, ordering policy, trusted totals and order status already have accepted server contracts and must not be shadowed by client constants.

The completed live order E2E does not relax these boundaries: customer payloads remain intent-only, server totals/status remain authoritative and customer status changes arrive through authorized backend state.

## Cross-repo rule

Any change to member code, verification, catalogue IDs/pricing/modifiers, order status, payment semantics, rewards/vouchers or promotions must be reviewed against the POS/Admin consumer before completion.
