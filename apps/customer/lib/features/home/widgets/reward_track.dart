import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/reward.dart';

/// The progress track: markers at each reward tier, filled up to the member's
/// balance, with a pointer showing exactly where they stand.
///
/// Markers are spaced **evenly**, not proportionally to their point cost. With
/// tiers at 100/150/180 a proportional track would bunch them at one end and
/// read as broken. Even spacing is what Starbucks does, and it keeps every tier
/// legible. The pointer still interpolates *within* a segment, so its position
/// remains truthful.
class RewardTrack extends StatelessWidget {
  const RewardTrack({super.key, required this.balance, required this.rewards});

  final int balance;

  /// Tiers in ascending cost. An empty list renders nothing.
  final List<Reward> rewards;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final n = rewards.length;

        // Marker centres, evenly spaced, inset so the end labels do not clip.
        const inset = 22.0;
        final usable = width - inset * 2;
        final step = n == 1 ? 0.0 : usable / (n - 1);
        final centres = [for (var i = 0; i < n; i++) inset + step * i];

        final pointerX = _pointerX(centres);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 46,
              width: width,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Unfilled track.
                  Positioned(
                    left: inset,
                    right: inset,
                    top: 20,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AidaColors.latte,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Filled portion, up to the pointer.
                  Positioned(
                    left: inset,
                    top: 20,
                    child: Container(
                      height: 4,
                      width: (pointerX - inset).clamp(0.0, usable),
                      decoration: BoxDecoration(
                        color: AidaColors.rewardGold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  for (var i = 0; i < n; i++)
                    Positioned(
                      left: centres[i] - 9,
                      top: 13,
                      child: _Marker(
                        reached: rewards[i].isAffordableAt(balance),
                      ),
                    ),
                  // The "you are here" pin.
                  Positioned(
                    left: pointerX - 6,
                    top: 0,
                    child: const Icon(
                      Icons.place,
                      size: 13,
                      color: AidaColors.coffee,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Labels, in the same even-spaced columns as the markers.
            SizedBox(
              width: width,
              height: 30,
              child: Stack(
                children: [
                  for (var i = 0; i < n; i++)
                    Positioned(
                      left: centres[i] - 30,
                      width: 60,
                      child: Column(
                        children: [
                          Text(
                            '${rewards[i].pointsCost}',
                            textAlign: TextAlign.center,
                            style: AidaType.sans(
                              size: 12,
                              weight: FontWeight.w700,
                              color:
                                  rewards[i].isAffordableAt(balance)
                                      ? AidaColors.textPrimary
                                      : AidaColors.textMuted,
                            ),
                          ),
                          Text(
                            rewards[i].markerLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AidaType.sans(
                              size: 9.5,
                              color: AidaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Where the pin sits.
  ///
  /// Below the first tier the pin scales from the track start. Between tiers it
  /// interpolates within that segment. At or past the last tier it pins to the
  /// end — a balance of 10,000 should not fly off the track.
  double _pointerX(List<double> centres) {
    final first = rewards.first.pointsCost;
    final last = rewards.last.pointsCost;

    if (balance <= 0) return centres.first;
    if (balance >= last) return centres.last;

    if (balance < first) {
      final t = balance / first;
      return centres.first * t;
    }

    for (var i = 0; i < rewards.length - 1; i++) {
      final lo = rewards[i].pointsCost;
      final hi = rewards[i + 1].pointsCost;
      if (balance >= lo && balance < hi) {
        final t = (balance - lo) / (hi - lo);
        return centres[i] + (centres[i + 1] - centres[i]) * t;
      }
    }

    return centres.last;
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.reached});

  final bool reached;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? AidaColors.rewardGold : AidaColors.cardWhite,
        border: Border.all(
          color: reached ? AidaColors.rewardGold : AidaColors.latte,
          width: 2,
        ),
      ),
    );
  }
}
