import 'menu_category.dart';
import 'menu_item.dart';

/// One internally consistent catalogue snapshot from the shared backend.
class CatalogueSnapshot {
  const CatalogueSnapshot({
    required this.revision,
    required this.categories,
    required this.items,
  });

  final int revision;
  final List<MenuCategory> categories;
  final List<MenuItem> items;

  MenuItem? get featuredItem {
    for (final item in items) {
      if (item.isFeatured) return item;
    }
    return null;
  }

  List<MenuItem> get popularItems =>
      items.where((item) => item.isBestSeller).toList(growable: false);
}
