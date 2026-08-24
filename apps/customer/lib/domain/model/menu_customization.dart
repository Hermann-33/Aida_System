/// Server-defined, per-drink single-choice customization groups such as
/// Temperature and Sweetness.
///
/// The customer app only stages option IDs. Labels, availability, defaults and
/// price deltas come from the shared catalogue and are revalidated by the
/// authoritative order quote boundary.
class MenuCustomizationGroup {
  const MenuCustomizationGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
    this.options = const [],
  });

  final String id;
  final String code;
  final String name;
  final int sortOrder;
  final List<MenuCustomizationOption> options;

  List<MenuCustomizationOption> get availableOptions =>
      options.where((option) => option.isAvailable).toList(growable: false);

  MenuCustomizationOption? get defaultOption {
    for (final option in options) {
      if (option.isDefault && option.isAvailable) return option;
    }
    for (final option in options) {
      if (option.isAvailable) return option;
    }
    return null;
  }
}

class MenuCustomizationOption {
  const MenuCustomizationOption({
    required this.id,
    required this.code,
    required this.label,
    required this.priceDeltaSen,
    required this.isDefault,
    required this.isAvailable,
    required this.sortOrder,
  });

  final String id;
  final String code;
  final String label;
  final int priceDeltaSen;
  final bool isDefault;
  final bool isAvailable;
  final int sortOrder;
}
