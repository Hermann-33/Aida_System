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
///
/// Whether it scrolls is decided at layout time, not hardcoded: when every
/// tile fits the available width, the row centres itself — a scroll strip
/// with dead space on one side reads as unfinished, not as "there's more if
/// you scroll." The moment more categories are added and the row no longer
/// fits, it becomes a normal scrollable strip automatically, with no layout
/// decision to revisit by hand as the menu grows.
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

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final count = categories.length + (showAll ? 1 : 0);

    Widget itemAt(int i) {
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
    }

    final totalWidth = count * CategoryChip.width + (count - 1) * _gap;

    return SizedBox(
      // Extra room so the tile's shadow pair — cast below and rim above —
      // is not clipped in either direction.
      height: CategoryChip.height + 20,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (totalWidth <= constraints.maxWidth) {
              return Row(
                children: [
                  for (var i = 0; i < count; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    itemAt(i),
                  ],
                ],
              );
            }

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: count,
              separatorBuilder: (_, __) => const SizedBox(width: _gap),
              itemBuilder: (_, i) => itemAt(i),
            );
          },
        ),
      ),
    );
  }
}
