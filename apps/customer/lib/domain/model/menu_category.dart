/// A menu category, for the "Explore Our Menu" row.
///
/// Categories are business data (PRD §12.2) — the café can rename or reorder
/// them without a code change, so nothing here is hardcoded to a fixed set.
class MenuCategory {
  const MenuCategory({required this.id, required this.name, required this.itemCount});

  final String id;
  final String name;

  /// Shown as "12 items". Zero is valid — a category can be temporarily empty.
  final int itemCount;
}
