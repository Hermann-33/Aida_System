import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/menu_item.dart';
import 'category_chip.dart';

/// Photo-forward list row for the Menu screen's single-column layout: large
/// image, name, price, and a filled "+" affordance. Both the "+" and the
/// rest of the card open the same detail sheet — items can carry
/// variants/add-ons, so a bare tap can't safely skip that choice and add a
/// default straight to the cart.
class MenuListItem extends StatelessWidget {
  const MenuListItem({super.key, required this.item, this.onTap});

  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unavailable = !item.isAvailable;
    final asset = CategoryChip.assetFor(item.category);

    return Opacity(
      opacity: unavailable ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: unavailable ? null : onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: AidaColors.latte.withValues(alpha: 0.5),
          highlightColor: AidaColors.caramelTint.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            // No card fill, no shadow — sits flat on the page like the
            // reference cart row, separated only by whitespace between rows.
            // Top-aligned, not centered: the "+" lives at the bottom of the
            // text column, so it lands in the card's bottom-right corner
            // rather than floating beside the whole row.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        AidaColors.latte.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child:
                      asset == null
                          ? Icon(
                            Icons.local_cafe_outlined,
                            size: 34,
                            color: AidaColors.coffee.withValues(alpha: 0.4),
                          )
                          : Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              asset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AidaType.serif(
                          size: 15,
                          color: AidaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  unavailable
                                      ? 'Sold out'
                                      : item.price.formatted,
                                  style: AidaType.sans(
                                    size: 14,
                                    weight: FontWeight.w800,
                                    color:
                                        unavailable
                                            ? AidaColors.error
                                            : AidaColors.coffee,
                                  ),
                                ),
                                if (item.isBestSeller && !unavailable) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AidaColors.rewardGold.withValues(
                                        alpha: 0.22,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '★',
                                      style: AidaType.sans(
                                        size: 10,
                                        weight: FontWeight.w800,
                                        color: AidaColors.rewardGoldDeep,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _AddButton(
                            disabled: unavailable,
                            onTap: unavailable ? null : onTap,
                          ),
                        ],
                      ),
                    ],
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

/// A "squircle" with one sharp corner (bottom-left) — softer than a plain
/// rounded square, more distinctive than a circle, per the reference shape.
const _addButtonRadius = BorderRadius.only(
  topLeft: Radius.circular(18),
  topRight: Radius.circular(18),
  bottomRight: Radius.circular(18),
  bottomLeft: Radius.circular(4),
);

/// Gradient fill plus a cast shadow below and a rim highlight above, so it
/// reads as a pressable button rather than a flat dot. Same two-shadow trick
/// as the category rail's tiles.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.disabled, this.onTap});

  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: _addButtonRadius,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: _addButtonRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  disabled
                      ? [AidaColors.latte, AidaColors.latte]
                      : [AidaColors.coffee, AidaColors.espresso],
            ),
            boxShadow:
                disabled
                    ? null
                    : [
                      BoxShadow(
                        color: AidaColors.espresso.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(3, 5),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 5,
                        offset: const Offset(-2, -2),
                      ),
                    ],
          ),
          child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
