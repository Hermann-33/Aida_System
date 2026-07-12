import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/loyalty.dart';
import 'stamp_ring.dart';

/// Points and stamps in one compact card.
///
/// Points are shown as a plain balance — no tier ladder. A customer only needs
/// to know how many points they have; what those points buy belongs on the
/// Rewards screen, not competing for attention here.
///
/// Stamp progress is a ring, not the previous zigzag line: the same
/// information in a fraction of the vertical space. See [StampRing] for why
/// it's ten discrete arcs rather than one smooth sweep.
class LoyaltyCard extends StatelessWidget {
  const LoyaltyCard({
    super.key,
    required this.points,
    required this.stamps,
    this.onDetails,
    this.onRedeem,
  });

  final Points points;
  final StampCard stamps;
  final VoidCallback? onDetails;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    final remaining = (stamps.required_ - stamps.collected).clamp(0, stamps.required_);

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                              size: 32,
                              color: AidaColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          size: 22,
                          color: AidaColors.rewardGold,
                        ),
                      ],
                    ),
                    Text(
                      'Aida Points',
                      style: AidaType.sans(size: 12, color: AidaColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    // One honest line about where they stand. The exact "7/10"
                    // count lives here as text, alongside the ring, rather
                    // than making the ring carry that precision on its own.
                    Row(
                      children: [
                        Icon(
                          stamps.freeDrinksAvailable > 0
                              ? Icons.card_giftcard_rounded
                              : Icons.coffee_rounded,
                          size: 15,
                          color: AidaColors.rewardGold,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _statusLine(remaining),
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
                ),
              ),
              const SizedBox(width: 16),
              StampRing(card: stamps),
            ],
          ),
          const SizedBox(height: 18),

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
                  onPressed: onRedeem,
                  style: FilledButton.styleFrom(
                    backgroundColor: AidaColors.espresso,
                    foregroundColor: AidaColors.cream,
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
        ],
      ),
    );
  }

  String _statusLine(int remaining) {
    if (stamps.freeDrinksAvailable == 1) {
      return '1 free drink ready — show your QR at the counter';
    }
    if (stamps.freeDrinksAvailable > 1) {
      return '${stamps.freeDrinksAvailable} free drinks ready — show your QR';
    }
    final count = '${stamps.collected}/${stamps.required_} stamps';
    if (remaining == 1) return '$count · 1 more to go';
    return '$count · $remaining more to go';
  }
}
