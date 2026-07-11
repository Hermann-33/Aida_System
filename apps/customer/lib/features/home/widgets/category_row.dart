import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/menu_category.dart';

/// Horizontal "Explore Our Menu" category strip.
class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.categories, this.onTap});

  final List<MenuCategory> categories;
  final void Function(MenuCategory)? onTap;

  static IconData _iconFor(String name) {
    return switch (name.toLowerCase()) {
      'coffee' => Icons.coffee_rounded,
      'iced drinks' => Icons.local_drink_rounded,
      'food' => Icons.bakery_dining_rounded,
      'add-ons' => Icons.add_circle_outline_rounded,
      _ => Icons.local_cafe_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final c = categories[i];
          return _CategoryChip(
            category: c,
            icon: _iconFor(c.name),
            onTap: () => onTap?.call(c),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.icon, required this.onTap});

  final MenuCategory category;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AidaColors.cardWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AidaColors.latte.withValues(alpha: 0.8)),
              ),
              child: Icon(icon, size: 26, color: AidaColors.coffee),
            ),
            const SizedBox(height: 7),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AidaType.sans(
                size: 11,
                weight: FontWeight.w600,
                color: AidaColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
