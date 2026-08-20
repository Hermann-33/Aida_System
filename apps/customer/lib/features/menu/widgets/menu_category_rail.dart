import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/menu_category.dart';
import 'category_chip.dart';

/// Vertical category rail for the Menu screen's photo-list layout. Tiles are
/// soft "3D puck" tiles — gradient fill + a cast shadow below and a rim
/// highlight above, the same two-shadow trick [CategoryChip]'s "All" tile
/// already uses — showing each category's real cut-out product photo where
/// one exists, so the rail reads as catchy product art rather than flat
/// glyphs, with an icon fallback only for "All" and "Favorites" (no single
/// item represents either).
///
/// Menu-only — Home keeps [CategoryStrip]'s horizontal photo tiles, so this
/// doesn't touch Home.
class MenuCategoryRail extends StatelessWidget {
  const MenuCategoryRail({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.favoritesOnly,
    required this.onSelect,
    required this.onSelectFavorites,
  });

  final List<MenuCategory> categories;

  /// Null means "All". Ignored for highlighting while [favoritesOnly] is on.
  final String? selectedId;

  /// Whether the dedicated "Favorites" tile is the active lens.
  final bool favoritesOnly;

  /// Receives null when "All" is tapped. Not called for "Favorites".
  final ValueChanged<String?> onSelect;

  final VoidCallback onSelectFavorites;

  static const width = 76.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 24),
        children: [
          _RailTile(
            key: const ValueKey('menu_cat_all'),
            label: 'All',
            icon: CategoryChip.iconFor('All'),
            selected: !favoritesOnly && selectedId == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(height: 18),
          _RailTile(
            key: const ValueKey('menu_cat_favorites'),
            label: 'Favorites',
            icon: Icons.favorite_rounded,
            selected: favoritesOnly,
            onTap: onSelectFavorites,
          ),
          for (final c in categories) ...[
            const SizedBox(height: 18),
            _RailTile(
              key: ValueKey('menu_cat_${c.id}'),
              label: c.name,
              icon: CategoryChip.iconFor(c.name),
              asset: CategoryChip.assetFor(c.name),
              selected: !favoritesOnly && c.id == selectedId,
              onTap: () => onSelect(c.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _RailTile extends StatefulWidget {
  const _RailTile({
    super.key,
    required this.label,
    required this.icon,
    this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? asset;
  final bool selected;
  final VoidCallback onTap;

  static const _puckSize = 52.0;

  @override
  State<_RailTile> createState() => _RailTileState();
}

class _RailTileState extends State<_RailTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Column(
          children: [
            AnimatedScale(
              scale: _pressed ? 0.93 : 1.0,
              duration: const Duration(milliseconds: 110),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: _RailTile._puckSize,
                height: _RailTile._puckSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        selected
                            ? [AidaColors.coffee, AidaColors.espresso]
                            : [
                              AidaColors.cardWhite,
                              AidaColors.latte.withValues(alpha: 0.55),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        selected
                            ? AidaColors.espresso
                            : AidaColors.latte.withValues(alpha: 0.8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AidaColors.espresso.withValues(
                        alpha: selected ? 0.32 : 0.16,
                      ),
                      blurRadius: 12,
                      offset: const Offset(4, 6),
                    ),
                    BoxShadow(
                      color:
                          selected
                              ? AidaColors.coffee.withValues(alpha: 0.45)
                              : Colors.white,
                      blurRadius: 6,
                      offset: const Offset(-3, -3),
                    ),
                  ],
                ),
                child:
                    widget.asset != null
                        ? Padding(
                          padding: const EdgeInsets.all(7),
                          child: Image.asset(
                            widget.asset!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder:
                                (_, __, ___) => Icon(
                                  widget.icon,
                                  size: 24,
                                  color:
                                      selected
                                          ? AidaColors.cream
                                          : AidaColors.coffee,
                                ),
                          ),
                        )
                        : Icon(
                          widget.icon,
                          size: 24,
                          color:
                              selected ? AidaColors.cream : AidaColors.coffee,
                        ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AidaType.sans(
                size: 11,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AidaColors.coffee : AidaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
