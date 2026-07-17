import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/menu_item.dart';
import 'category_chip.dart';

/// One cell in the Menu 3-column grid — unified card with floating cut-out
/// product art and a fixed text block so every tile reads the same height.
class MenuGridItem extends StatelessWidget {
  const MenuGridItem({
    super.key,
    required this.item,
    this.onTap,
  });

  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unavailable = !item.isAvailable;
    final asset = CategoryChip.assetFor(item.category);

    return Opacity(
      opacity: unavailable ? 0.52 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: unavailable ? null : onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: AidaColors.latte.withValues(alpha: 0.5),
          highlightColor: AidaColors.caramelTint.withValues(alpha: 0.35),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AidaColors.cardWhite,
                  AidaColors.caramelTint.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: AidaColors.latte.withValues(alpha: 0.65),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AidaColors.espresso.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Soft “stage” for the cut-out — no photo background box.
                // Expanded (rather than a fixed height) so the stage always
                // fills whatever room the grid's aspect ratio leaves after
                // the text block below, instead of overflowing the tile.
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
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
                              size: 40,
                              color: AidaColors.coffee.withValues(alpha: 0.4),
                            )
                            : Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                asset,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AidaType.sans(
                            size: 11.5,
                            weight: FontWeight.w700,
                            height: 1.25,
                            color: AidaColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              unavailable ? 'Sold out' : item.price.formatted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AidaType.sans(
                                size: 12,
                                weight: FontWeight.w800,
                                color:
                                    unavailable
                                        ? AidaColors.error
                                        : AidaColors.coffee,
                              ),
                            ),
                          ),
                          if (item.isBestSeller && !unavailable)
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
                                  size: 9,
                                  weight: FontWeight.w800,
                                  color: AidaColors.rewardGoldDeep,
                                ),
                              ),
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
