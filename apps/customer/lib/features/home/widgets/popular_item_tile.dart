import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../core/widgets/product_image.dart';
import '../../../domain/model/menu_item.dart';

/// A row in "Popular Picks".
///
/// There is no add-to-cart control: ordering is out of v1 scope. Tapping opens
/// the item's detail. A chevron promises navigation, which is a promise this
/// screen can actually keep.
class PopularItemTile extends StatelessWidget {
  const PopularItemTile({super.key, required this.item, this.onTap});

  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unavailable = !item.isAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // A sold-out item is not tappable — nothing useful is behind it.
        onTap: unavailable ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Opacity(
            // Dim the whole row rather than hiding it: the customer should know
            // the café sells this, just not right now.
            opacity: unavailable ? 0.5 : 1,
            child: Row(
              children: [
                ProductImage(imageUrl: item.imageUrl, category: item.category, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AidaType.sans(
                                size: 15,
                                weight: FontWeight.w700,
                                color: AidaColors.textPrimary,
                              ),
                            ),
                          ),
                          if (unavailable) ...[
                            const SizedBox(width: 8),
                            const _SoldOutBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AidaType.sans(size: 12, color: AidaColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            item.price.formatted,
                            style: AidaType.sans(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AidaColors.coffee,
                            ),
                          ),
                          if (item.bonusPoints != null) ...[
                            const SizedBox(width: 8),
                            _BonusChip(points: item.bonusPoints!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!unavailable)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AidaColors.textMuted.withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoldOutBadge extends StatelessWidget {
  const _SoldOutBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AidaColors.latte,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'SOLD OUT',
        style: AidaType.sans(
          size: 9,
          weight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AidaColors.textMuted,
        ),
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  const _BonusChip({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AidaColors.rewardGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '+$points pts',
        style: AidaType.sans(
          size: 10,
          weight: FontWeight.w700,
          color: AidaColors.rewardGold,
        ),
      ),
    );
  }
}
