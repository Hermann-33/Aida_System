import 'money.dart';

/// A product on the menu. PRD §12.1.
class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    this.isBestSeller = false,
    this.isStudentEligible = false,
    this.bonusPoints,
    this.compatibleAddOnIds = const [],
    this.rating,
    this.volumeMl,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final Money price;
  final bool isAvailable;
  final String? imageUrl;
  final bool isBestSeller;

  /// Whether student-only offers may apply to this item.
  final bool isStudentEligible;

  /// Campaign bonus points, shown as the gold `+25` pill in the approved
  /// design. Null when the item carries no campaign.
  final int? bonusPoints;

  /// IDs of menu items (from the Add-ons category) this item can be ordered
  /// with — e.g. a Latte's list includes "Extra Shot". Empty by default; a
  /// croissant has nothing here. This is a placeholder mapping, not a
  /// verified business rule — see the cart design spec §3.
  final List<String> compatibleAddOnIds;

  /// TEST DATA ONLY — there is no review system anywhere in this app, no
  /// customer can leave a rating, and this number is not backed by anything
  /// real. Shown purely so the detail page can be visually reviewed with a
  /// rating in place; must not ship to a real customer without an actual
  /// review feature behind it. Null renders nothing.
  final double? rating;

  /// Placeholder serving size, e.g. 240 for "240ml". Not a confirmed menu
  /// spec — same caveat as every price and size delta in this app: real
  /// numbers are the owner's call. Null renders nothing.
  final int? volumeMl;
}
