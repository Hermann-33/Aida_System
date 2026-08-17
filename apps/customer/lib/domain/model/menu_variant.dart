/// A server-defined purchasable variant for a menu item.
///
/// Price deltas stay as integer sen because a variant may be cheaper than the
/// base item (for example Small = -100 sen). The database guarantees the final
/// item price never becomes negative.
class MenuVariant {
  const MenuVariant({
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
