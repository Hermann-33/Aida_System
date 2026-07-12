import 'package:flutter/material.dart';

import '../../../domain/model/menu_category.dart';
import 'category_chip.dart';

/// Horizontal strip of category cards, shared by Home and Menu.
///
/// One widget rather than two so the two screens cannot drift apart visually.
/// The difference between them is only in the arguments:
///
/// - **Home** passes `showAll: false` and a null [selectedId]. Nothing looks
///   selected; tapping navigates to Menu.
/// - **Menu** passes `showAll: true`. The selection persists and filters.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.categories,
    this.selectedId,
    this.showAll = false,
    this.keyPrefix = 'cat',
    this.onSelect,
  });

  final List<MenuCategory> categories;

  /// Null means "All" on Menu, and "nothing selected" on Home.
  final String? selectedId;

  /// Whether to prepend an "All" card.
  ///
  /// "All" is not a real category from the server — it is the absence of a
  /// filter. Synthesising it here keeps the server's data honest.
  final bool showAll;

  /// Distinguishes Home's cards from Menu's in the widget tree, so a test can
  /// target one screen's strip without matching the other's.
  final String keyPrefix;

  /// Receives null when "All" is tapped.
  final ValueChanged<String?>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final count = categories.length + (showAll ? 1 : 0);

    return SizedBox(
      // Extra room so the selected card's shadow is not clipped.
      height: CategoryChip.height + 12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: 2),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (showAll && i == 0) {
            return CategoryChip(
              key: ValueKey('${keyPrefix}_all'),
              label: 'All',
              icon: CategoryChip.iconFor('All'),
              selected: selectedId == null,
              onTap: () => onSelect?.call(null),
            );
          }

          final c = categories[showAll ? i - 1 : i];
          return CategoryChip(
            key: ValueKey('${keyPrefix}_${c.id}'),
            label: c.name,
            icon: CategoryChip.iconFor(c.name),
            selected: c.id == selectedId,
            onTap: () => onSelect?.call(c.id),
          );
        },
      ),
    );
  }
}
