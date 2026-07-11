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
}
