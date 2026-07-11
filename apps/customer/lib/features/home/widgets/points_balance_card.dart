import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../domain/model/loyalty.dart';
import '../../../core/theme/aida_type.dart';

/// The espresso points pill from the approved design.
class PointsBalanceCard extends StatelessWidget {
  const PointsBalanceCard({super.key, required this.points, this.isStale = false});

  final Points points;

  /// Shown when the balance came from cache and a refresh failed. A stale
  /// number presented as current fact is worse than an honest one (spec §5.3).
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AidaColors.espresso, AidaColors.coffee],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: AidaTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIDA POINTS BALANCE',
                  style: AidaTheme.sectionLabel(color: AidaColors.latte),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        points.formatted,
                        overflow: TextOverflow.ellipsis,
                        style: AidaType.serif(
                          size: 34,
                          weight: FontWeight.w700,
                          color: AidaColors.rewardGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'points',
                      style: AidaType.sans(size: 14, color: AidaColors.latte),
                    ),
                  ],
                ),
                if (isStale) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last updated a while ago',
                    style: AidaType.sans(
                      size: 11,
                      color: AidaColors.latte.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.local_cafe_rounded,
            color: AidaColors.rewardGold.withValues(alpha: 0.35),
            size: 40,
          ),
        ],
      ),
    );
  }
}
