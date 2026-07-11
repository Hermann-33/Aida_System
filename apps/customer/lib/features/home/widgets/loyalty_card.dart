import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/loyalty.dart';
import '../../../domain/model/reward.dart';
import 'reward_track.dart';

/// Points and stamps in one card.
///
/// These were two separate cards. Merged because they answer one question —
/// "what can I get?" — and a customer should not have to assemble that answer
/// from two places. Points buy vouchers; stamps earn a free drink. Both are
/// progress toward a reward, so both belong on one surface.
class LoyaltyCard extends StatelessWidget {
  const LoyaltyCard({
    super.key,
    required this.points,
    required this.stamps,
    required this.rewards,
    this.onDetails,
    this.onRedeem,
  });

  final Points points;
  final StampCard stamps;
  final List<Reward> rewards;
  final VoidCallback? onDetails;
  final VoidCallback? onRedeem;

  /// Cheapest reward the member cannot yet afford, or null if they can afford
  /// everything.
  Reward? get _nextReward {
    for (final r in rewards) {
      if (!r.isAffordableAt(points.balance)) return r;
    }
    return null;
  }

  bool get _canRedeemSomething => rewards.any((r) => r.isAffordableAt(points.balance));

  @override
  Widget build(BuildContext context) {
    final next = _nextReward;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AidaTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              color: AidaColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          size: 24,
                          color: AidaColors.rewardGold,
                        ),
                      ],
                    ),
                    Text(
                      'Aida Points',
                      style: AidaType.sans(size: 12, color: AidaColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (next != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AidaColors.rewardGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${next.pointsCost - points.balance} pts to ${next.markerLabel}',
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      style: AidaType.sans(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AidaColors.coffee,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          RewardTrack(balance: points.balance, rewards: rewards),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AidaColors.textPrimary,
                    side: const BorderSide(color: AidaColors.latte),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Details',
                    style: AidaType.sans(size: 13, weight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  // Disabled when nothing is affordable. A Redeem button that
                  // opens a screen of things you cannot buy is a dead end.
                  onPressed: _canRedeemSomething ? onRedeem : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AidaColors.espresso,
                    foregroundColor: AidaColors.cream,
                    disabledBackgroundColor: AidaColors.latte,
                    disabledForegroundColor: AidaColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Redeem',
                    style: AidaType.sans(size: 13, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: AidaColors.latte),
          const SizedBox(height: 16),

          _StampStrip(card: stamps),
        ],
      ),
    );
  }
}

/// Compact stamp row. Smaller than the standalone card it replaces, because it
/// now shares space with the points track.
class _StampStrip extends StatelessWidget {
  const _StampStrip({required this.card});

  final StampCard card;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Stamp Card',
                overflow: TextOverflow.ellipsis,
                style: AidaType.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AidaColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${card.collected} / ${card.required_}',
              style: AidaTheme.sectionLabel(color: AidaColors.rewardGold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Size the stamps to fit one row, whatever the threshold. A hardcoded
        // size orphans the last stamps onto a second row, and a café that moves
        // from 10 stamps to 12 would break the layout.
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 6.0;
            final n = card.required_;
            final size =
                n == 0
                    ? 0.0
                    : ((constraints.maxWidth - gap * (n - 1)) / n).clamp(18.0, 34.0);

            return Row(
              children: [
                for (var i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  _Stamp(index: i, filled: card.isFilled(i), size: size),
                ],
              ],
            );
          },
        ),
        if (card.freeDrinksAvailable > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                size: 15,
                color: AidaColors.rewardGold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  card.freeDrinksAvailable == 1
                      ? '1 free drink ready — show your QR'
                      : '${card.freeDrinksAvailable} free drinks ready',
                  style: AidaType.sans(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: AidaColors.coffee,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.index, required this.filled, required this.size});

  final int index;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
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
        child: Icon(Icons.coffee_rounded, size: size * 0.5, color: AidaColors.espresso),
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
            size: size * 0.36,
            weight: FontWeight.w600,
            color: AidaColors.textMuted,
          ),
        ),
      ),
    );
  }
}
