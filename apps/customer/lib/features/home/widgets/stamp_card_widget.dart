import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../domain/model/loyalty.dart';
import '../../../core/theme/aida_type.dart';

/// Digital stamp card. Filled stamps are gold with a cup; unfilled are dashed
/// outlines showing their position, per the approved design.
class StampCardWidget extends StatelessWidget {
  const StampCardWidget({super.key, required this.card});

  final StampCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AidaTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Both children are Flexible: a customer using large system text must
          // not blow the row out. The count is the thing you cannot lose, so
          // the title ellipsizes first.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Stamp Rewards',
                  overflow: TextOverflow.ellipsis,
                  style: AidaType.sans(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AidaColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${card.collected} / ${card.required_} STAMPS',
                style: AidaTheme.sectionLabel(color: AidaColors.rewardGold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wrap rather than a fixed grid, so a café that changes the threshold
          // from 10 to 8 or 12 does not break the layout.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              card.required_,
              (i) => _Stamp(index: i, filled: card.isFilled(i)),
            ),
          ),
          if (card.freeDrinksAvailable > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AidaColors.rewardGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    size: 18,
                    color: AidaColors.rewardGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.freeDrinksAvailable == 1
                          ? '1 free drink ready — show your QR at the counter'
                          : '${card.freeDrinksAvailable} free drinks ready',
                      style: AidaType.sans(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AidaColors.coffee,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.index, required this.filled});

  final int index;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;

    if (filled) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AidaColors.rewardGold, Color(0xFFB58B3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.coffee_rounded, size: 20, color: AidaColors.espresso),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AidaColors.cream,
        border: Border.all(color: AidaColors.latte, width: 1.5),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: AidaType.sans(
            size: 13,
            weight: FontWeight.w600,
            color: AidaColors.textMuted,
          ),
        ),
      ),
    );
  }
}
