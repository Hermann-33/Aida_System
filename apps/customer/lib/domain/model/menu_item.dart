import 'menu_customization.dart';
import 'menu_variant.dart';
import 'money.dart';

/// A published product/add-on from the shared catalogue.
class MenuItem {
  const MenuItem({
    required this.id,
    this.categoryId = '',
    this.sku = '',
    this.kind = 'product',
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    this.isFeatured = false,
    this.isBestSeller = false,
    this.isStudentEligible = false,
    this.isDrink = false,
    this.compatibleAddOnIds = const [],
    this.variants = const [],
    this.customizationGroups = const [],
    this.volumeMl,
  });

  /// Server-owned stable identifier. Live catalogue rows always provide these
  /// backend fields; defaults only preserve isolated widget/test construction.
  final String id;
  final String categoryId;
  final String sku;

  /// `product` or `addon`. Category names are display data and never determine
  /// whether an item is an add-on.
  final String kind;

  final String name;
  final String category;
  final String description;
  final Money price;
  final bool isAvailable;
  final String? imageUrl;
  final bool isFeatured;
  final bool isBestSeller;
  final bool isStudentEligible;

  /// True when this product participates in the standard drink option groups
  /// (currently Temperature and Sweetness). The backend owns this classification.
  final bool isDrink;

  /// Server-defined add-on item IDs valid for this product. Add-ons are selected
  /// on an individual cart line; they are not independent customer menu rows.
  final List<String> compatibleAddOnIds;

  /// Server-defined variants such as Small / Medium / Large. Empty means the
  /// item has no variant choice.
  final List<MenuVariant> variants;

  /// Required single-choice groups configured by Admin for this drink.
  final List<MenuCustomizationGroup> customizationGroups;

  final int? volumeMl;

  /// Ratings and bonus campaigns are not catalogue facts. Compatibility
  /// getters keep old presentation code compiling while ensuring no fake value
  /// can leak into the live menu.
  double? get rating => null;
  int? get bonusPoints => null;

  MenuVariant? get defaultVariant {
    for (final variant in variants) {
      if (variant.isDefault && variant.isAvailable) return variant;
    }
    for (final variant in variants) {
      if (variant.isAvailable) return variant;
    }
    return null;
  }
}
