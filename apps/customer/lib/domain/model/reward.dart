/// What a reward gives you when redeemed.
enum RewardKind {
  /// A cash-value voucher, e.g. RM 5 off.
  voucher,

  /// A specific free item, e.g. a pastry.
  freeItem,

  /// A free drink earned from a completed stamp card, not from points.
  freeDrink,
}

/// A reward a member can buy with points. PRD §10.1.
///
/// Costs are business data — the owner must be able to change them without a
/// code change — so nothing here assumes a fixed ladder.
class Reward {
  const Reward({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.kind,
    this.shortLabel,
  });

  final String id;
  final String name;
  final int pointsCost;
  final RewardKind kind;

  /// Terse label under a slider marker, e.g. "RM 5". Falls back to [name].
  final String? shortLabel;

  String get markerLabel => shortLabel ?? name;

  /// Whether [balance] covers this reward. A pure comparison — the client
  /// still never decides the outcome of a redemption; the server does.
  bool isAffordableAt(int balance) => balance >= pointsCost;
}
