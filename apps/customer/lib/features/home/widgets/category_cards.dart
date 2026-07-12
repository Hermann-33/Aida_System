import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../core/widgets/product_image.dart';
import '../../../domain/model/menu_category.dart';
import 'category_row.dart';

/// Wide category cards for Home.
///
/// Distinct from the compact [CategoryChip] on Menu, which is a filter control
/// with a selected state. This is a navigation affordance: it never looks
/// "selected", it just invites a tap. Conflating the two would mean a chip that
/// sometimes filters and sometimes navigates.
///
/// Each card carries its own tint so the strip reads as varied without needing
/// photography — and each has an image slot behind the tint, so a photo drops in
/// later without touching the layout.
class CategoryCards extends StatelessWidget {
  const CategoryCards({super.key, required this.categories, this.onTap});

  final List<MenuCategory> categories;
  final void Function(MenuCategory)? onTap;

  /// Tints cycle by position rather than being keyed to category names, so a
  /// category the owner adds later still gets a colour instead of falling
  /// through to grey.
  ///
  /// City Red is deliberately absent: it means City U / student, and a Food
  /// card wearing it would quietly break that signal.
  static const _tints = <(Color, Color)>[
    (Color(0x1F7A5B44), AidaColors.coffee), // coffee wash
    (Color(0x24C9A24E), AidaColors.rewardGold), // gold wash
    (AidaColors.caramelTint, AidaColors.coffee), // caramel
    (Color(0x8CE0D5C3), AidaColors.espresso), // latte wash
  ];

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = categories[i];
          final (background, accent) = _tints[i % _tints.length];

          return _CategoryCard(
            category: c,
            background: background,
            accent: accent,
            onTap: () => onTap?.call(c),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.background,
    required this.accent,
    required this.onTap,
  });

  final MenuCategory category;
  final Color background;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;

    return Semantics(
      button: true,
      label: '${c.name}, ${c.itemCount} items',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: Container(
            width: 168,
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AidaColors.latte.withValues(alpha: 0.55)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Stack(
                children: [
                  // Image slot, behind everything. Empty today; a photo here
                  // later needs no layout change, only a scrim.
                  if (c.imageUrl != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.35,
                        child: ProductImage(
                          imageUrl: c.imageUrl,
                          category: c.name,
                          borderRadius: 0,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AidaColors.cardWhite.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            CategoryRow.iconFor(c.name),
                            size: 22,
                            color: widget.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AidaType.sans(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: AidaColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.itemCount == 1 ? '1 item' : '${c.itemCount} items',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AidaType.sans(
                                  size: 11.5,
                                  color: AidaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
