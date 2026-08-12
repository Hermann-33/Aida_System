> Scope note: customer Flutter fragile boundaries. Dashboard boundaries are under `docs/dashboard/FRAGILE_BOUNDARIES.md`.

# Fragile Boundaries

## Highest-risk customer areas

- `lib/application/providers.dart`: repository binding, navigation and multiple session stores in one place.
- `lib/domain/repository/member_repository.dart`: broad read/auth port but missing real write/quote/order contracts.
- `lib/data/repository/mock_member_repository.dart`: demo values shape UI assumptions.
- `lib/main.dart`: root auth lifecycle.
- `features/shell/app_shell.dart`: indexed tab lifetime/floating cart.
- `domain/model/cart.dart` and `features/cart/cart_screen.dart`: client pricing, payment simulation, random order and local history.
- order model/confirmation: inadequate lifecycle and timer status.
- membership card: static QR plus unimplemented offline storage claim.
- large Home and item-detail screens: local state/calculation/navigation coupling.
- golden baselines: review visual differences before updating.

## Contract-sensitive assumptions

Fixed category names, add-ons as items, size deltas, reward ladder, permanent member code, narrow student/order status models and payment-method labels must not become shared schema by accident.

## Cross-repo rule

Any change to member code, verification, catalogue IDs/pricing/modifiers, order status, payment semantics, rewards/vouchers or promotions must be reviewed against the POS/Admin consumer before completion.