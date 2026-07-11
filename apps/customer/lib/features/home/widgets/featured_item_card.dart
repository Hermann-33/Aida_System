import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../domain/model/menu_item.dart';
import '../../../core/theme/aida_type.dart';

/// "Featured Today · BARISTA PICK" with the gold bonus-points pill.
class FeaturedItemCard extends StatelessWidget {
  const FeaturedItemCard({super.key, required this.item, this.onTap});

  final MenuItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: AidaColors.cardWhite,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AidaTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Featured Today',
                      overflow: TextOverflow.ellipsis,
                      style: AidaType.sans(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                  ),
                  if (item.isBestSeller) ...[
                    const SizedBox(width: 8),
                    Text('BARISTA PICK', style: AidaTheme.sectionLabel()),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder tile — product photography is not in yet, and a
                  // wrong stock image shown to the client is worse than none.
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AidaColors.latte.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_cafe_rounded,
                      size: 30,
                      color: AidaColors.coffee,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AidaType.serif(
                            size: 19,
                            weight: FontWeight.w700,
                            color: AidaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AidaType.sans(
                            size: 12,
                            height: 1.4,
                            color: AidaColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.price.formatted,
                                overflow: TextOverflow.ellipsis,
                                style: AidaType.sans(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  color: AidaColors.coffee,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (item.bonusPoints != null)
                              _BonusPill(points: item.bonusPoints!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BonusPill extends StatelessWidget {
  const _BonusPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AidaColors.rewardGold, Color(0xFFB58B3C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 14, color: AidaColors.espresso),
          const SizedBox(width: 5),
          Text(
            '+$points',
            style: AidaType.sans(
              size: 13,
              weight: FontWeight.w800,
              color: AidaColors.espresso,
            ),
          ),
        ],
      ),
    );
  }
}
