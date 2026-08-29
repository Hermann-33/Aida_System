import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';

/// A floating category tile with the label sitting free below it.
///
/// Real categories (Coffee, Iced Drinks, Food, Add-ons) and Favorites show a
/// cut-out product/mascot photo — just the item on transparent pixels, no
/// card fill behind it — matching the client's "real images, no background"
/// ask. "All" has no single item to represent it, so it falls back to the
/// icon-in-a-square tile.
///
/// The label is deliberately **not** enclosed by the tile's border or shadow —
/// only the tile itself carries the floating look.
///
/// Selected draws a coloured ring around the photo tile (or fills the icon
/// fallback). The label turns reward gold either way.
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

  /// Thin outline glyphs — the "All" fallback tile only. Real categories use
  /// [assetFor] instead; see the class doc.
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

  /// Cut-out product photo for the category. Null for "All" — there's no
  /// single item to depict — and for anything unrecognised.
  static String? assetFor(String name) {
    return switch (name.toLowerCase()) {
      'coffee' => 'assets/images/cat_coffee.png',
      'iced drinks' => 'assets/images/cat_iced.png',
      'food' => 'assets/images/cat_food.png',
      'add-ons' => 'assets/images/cat_addons.png',
      'favorites' => 'assets/images/favorite_mascot.png',
      _ => null,
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
    final asset = CategoryChip.assetFor(widget.label);

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
                child:
                    asset != null
                        ? _PhotoTile(asset: asset, selected: selected)
                        : _IconTile(icon: widget.icon, selected: selected),
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
                  color:
                      selected ? AidaColors.rewardGold : AidaColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cut-out product photo — transparent PNG, no fill behind it. A coffee
/// selection ring is the only chrome when selected.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.asset, required this.selected});

  final String asset;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: CategoryChip.tileSize,
      height: CategoryChip.tileSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AidaColors.coffee : Colors.transparent,
          width: 3,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder:
              (_, __, ___) => Icon(
                Icons.local_cafe_outlined,
                size: 40,
                color: AidaColors.coffee.withValues(alpha: 0.55),
              ),
        ),
      ),
    );
  }
}

/// Icon-in-a-square fallback for categories with no representative item
/// ("All" — there is no single thing to depict).
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: CategoryChip.tileSize,
      height: CategoryChip.tileSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              selected
                  ? [AidaColors.coffee, AidaColors.espresso]
                  : [
                    AidaColors.cardWhite,
                    AidaColors.latte.withValues(alpha: 0.5),
                  ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
              selected
                  ? AidaColors.espresso
                  : AidaColors.latte.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(
              alpha: selected ? 0.34 : 0.22,
            ),
            blurRadius: 18,
            offset: const Offset(6, 9),
          ),
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
        icon,
        size: 56,
        color: selected ? AidaColors.cream : AidaColors.coffee,
      ),
    );
  }
}
