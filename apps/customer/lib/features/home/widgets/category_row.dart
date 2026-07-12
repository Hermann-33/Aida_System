import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/menu_category.dart';

/// Horizontal category strip: rounded-square icon tiles with the label beneath.
///
/// A selected tile fills with espresso and inverts its icon to cream. Pressing
/// dips the tile slightly, so a tap is felt even before the screen changes —
/// which matters on the Menu, where selecting a category filters in place and
/// there is no navigation to confirm the tap landed.
class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.categories, this.selectedId, this.onTap});

  final List<MenuCategory> categories;

  /// Null means nothing is selected — the state on Home, where tapping
  /// navigates rather than filters.
  final String? selectedId;

  final void Function(MenuCategory)? onTap;

  static IconData iconFor(String name) {
    return switch (name.toLowerCase()) {
      'all' => Icons.grid_view_rounded,
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
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final c = categories[i];
          return CategoryChip(
            label: c.name,
            icon: iconFor(c.name),
            selected: c.id == selectedId,
            onTap: () => onTap?.call(c),
          );
        },
      ),
    );
  }
}

/// One tile. Public so the Menu screen can reuse it for its "All" chip.
class CategoryChip extends StatefulWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _pressed ? 0.93 : 1.0,
                duration: const Duration(milliseconds: 110),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: selected ? AidaColors.espresso : AidaColors.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          selected
                              ? AidaColors.espresso
                              : AidaColors.latte.withValues(alpha: 0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AidaColors.espresso.withValues(
                          alpha: selected ? 0.22 : 0.05,
                        ),
                        blurRadius: selected ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 27,
                    color: selected ? AidaColors.cream : AidaColors.coffee,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AidaType.sans(
                  size: 11,
                  weight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AidaColors.textPrimary : AidaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
