import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';

/// A square, floating icon tile with the label sitting free below it.
///
/// The label is deliberately **not** enclosed by the card's border or shadow —
/// only the icon square carries the "3D" floating look. Enclosing both in one
/// bordered box (the previous design) reads as a single flat pill; separating
/// them is what makes the tile itself look like it is sitting above the page.
///
/// Selected fills the tile with espresso and inverts the icon to cream. The
/// label — outside the tile — turns reward gold, which is what carries the
/// selected state once the tile itself is a different shape from the text.
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

  /// The square tile's side.
  static const tileSize = 92.0;

  /// Total tile height including the free-standing label beneath it. Callers
  /// size their scroll strip from this, so the number lives in one place.
  static const height = tileSize + 10 + 18;
  static const width = 100.0;

  /// Thin outline glyphs, matching the reference style — not the filled
  /// `_rounded` family used elsewhere in the app for larger, single icons.
  static IconData iconFor(String name) {
    return switch (name.toLowerCase()) {
      'all' => Icons.grid_view_outlined,
      'coffee' => Icons.coffee_outlined,
      'iced drinks' => Icons.local_drink_outlined,
      'food' => Icons.bakery_dining_outlined,
      'add-ons' => Icons.add_circle_outline,
      _ => Icons.local_cafe_outlined,
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
        child: SizedBox(
          width: CategoryChip.width,
          child: Column(
            children: [
              AnimatedScale(
                scale: _pressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 110),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: CategoryChip.tileSize,
                  height: CategoryChip.tileSize,
                  decoration: BoxDecoration(
                    // Neither flat white nor flat espresso — a faint diagonal
                    // gradient so the tile itself shows a highlight and a
                    // falloff, the way a raised surface catches light. This is
                    // what a single flat shadow cannot do on its own.
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          selected
                              ? [AidaColors.coffee, AidaColors.espresso]
                              : const [Color(0xFFFFFFFF), Color(0xFFF6EEE6)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    // A thin edge, so the tile reads clearly against the cream
                    // page instead of the gradient alone doing all the work —
                    // a soft embossed edge without this can look washed out,
                    // especially once compressed into a screenshot.
                    border: Border.all(
                      color:
                          selected
                              ? AidaColors.espresso
                              : AidaColors.latte.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      // Cast shadow: bottom-right, as if lit from the top-left.
                      // Darkened slightly over the previous pass so the tile's
                      // edge is unmistakable rather than merely implied.
                      BoxShadow(
                        color: AidaColors.espresso.withValues(
                          alpha: selected ? 0.34 : 0.22,
                        ),
                        blurRadius: 18,
                        offset: const Offset(6, 9),
                      ),
                      // Rim highlight: top-left, opposite the cast shadow.
                      // Without this the tile looks lit flatly; with it, the
                      // top-left edge catches light like a raised edge would.
                      BoxShadow(
                        color:
                            selected
                                ? AidaColors.coffee.withValues(alpha: 0.5)
                                : Colors.white,
                        blurRadius: 10,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    // User-requested increase over the original 44.
                    size: 56,
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
                  size: 12.5,
                  weight: FontWeight.w700,
                  // Gold when selected — the label is what carries the
                  // selected state now that it lives outside the tile.
                  color: selected ? AidaColors.rewardGold : AidaColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
