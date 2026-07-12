import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';

/// A tall rounded category card: icon above, label inside.
///
/// Selected fills with espresso, the icon turns cream, and the label turns
/// **reward gold** — the gold text is what makes the selected state read as
/// deliberate rather than merely inverted.
///
/// Used on both Home and Menu. On Home nothing is ever selected (tapping
/// navigates); on Menu the selection persists and filters.
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

  /// The strip's height. Callers size their scroll view from this, so the
  /// number lives in one place.
  static const height = 126.0;
  static const width = 84.0;

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
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: CategoryChip.width,
            height: CategoryChip.height,
            decoration: BoxDecoration(
              color: selected ? AidaColors.espresso : AidaColors.cardWhite,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color:
                    selected
                        ? AidaColors.espresso
                        : AidaColors.latte.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: AidaColors.espresso.withValues(alpha: selected ? 0.24 : 0.06),
                  blurRadius: selected ? 16 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 30,
                  color: selected ? AidaColors.cream : AidaColors.espresso,
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AidaType.sans(
                      size: 12,
                      weight: FontWeight.w700,
                      // Gold, not cream. This is the detail that carries the
                      // whole selected state.
                      color: selected ? AidaColors.rewardGold : AidaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
