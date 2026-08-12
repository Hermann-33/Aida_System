import 'menu_variant.dart';
import 'money.dart';

/// A published product/add-on from the shared catalogue.
class MenuItem {
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.sku,
    required this.kind,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    this.isFeatured = false,
    this.isBestSeller = false,
    this.isStudentEligible = false,
    this.compatibleAddOnIds = const [],
    this.variants = const [],
    this.volumeMl,
  });

  /// Server-owned stable identifier.
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

  /// Server-defined add-on item IDs valid for this product.
  final List<String> compatibleAddOnIds;

  /// Server-defined variants such as Small / Medium / Large. Empty means the
  /// item has no variant choice.
  final List<MenuVariant> variants;

  final int? volumeMl;

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
