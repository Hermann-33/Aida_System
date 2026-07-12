import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/loyalty.dart';

/// Stamp progress as a track: a line with stamps alternating above and below.
///
/// Zigzagging is what buys the space. Ten stamps in a single row have to shrink
/// to fit; alternating them means neighbours never collide horizontally, so each
/// stamp can be half again as large on the same width.
///
/// The line fills gold up to the member's current stamp, so progress reads at a
/// glance without counting cups.
class StampTrack extends StatelessWidget {
  const StampTrack({super.key, required this.card});

  final StampCard card;

  @override
  Widget build(BuildContext context) {
    final n = card.required_;
    if (n == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Stamps alternate sides, so only same-side neighbours (i, i+2) can
        // collide. That is what lets the size exceed the horizontal step.
        final step = n == 1 ? 0.0 : (width - 40) / (n - 1);
        final size = (step * 2 - 8).clamp(26.0, 40.0);

        final trackHeight = size * 2;
        final lineY = trackHeight / 2;
        final left = size / 2 + 2;

        double xOf(int i) => left + step * i;

        // Fill to the last collected stamp; nothing collected means no fill.
        final fillTo =
            card.collected == 0 ? left : xOf((card.collected - 1).clamp(0, n - 1));

        return SizedBox(
          height: trackHeight + 4,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: left,
                top: lineY - 2,
                child: Container(
                  height: 4,
                  width: (xOf(n - 1) - left).clamp(0.0, width),
                  decoration: BoxDecoration(
                    color: AidaColors.latte,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: lineY - 2,
                child: Container(
                  height: 4,
                  width: (fillTo - left).clamp(0.0, width),
                  decoration: BoxDecoration(
                    color: AidaColors.rewardGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              for (var i = 0; i < n; i++)
                Positioned(
                  left: xOf(i) - size / 2,
                  // Even index sits above the line, odd below.
                  top: i.isEven ? lineY - size : lineY,
                  child: _Stamp(index: i, filled: card.isFilled(i), size: size),
                ),
            ],
          ),
        );
      },
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AidaColors.rewardGold, AidaColors.rewardGoldDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // Ring in the card colour, so a stamp reads as sitting on the line
          // rather than being cut by it.
          border: Border.all(color: AidaColors.cardWhite, width: 2),
        ),
        child: Icon(Icons.coffee_rounded, size: size * 0.46, color: AidaColors.espresso),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AidaColors.cream,
        border: Border.all(color: AidaColors.latte, width: 2),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: AidaType.sans(
            size: size * 0.34,
            weight: FontWeight.w600,
            color: AidaColors.textMuted,
          ),
        ),
      ),
    );
  }
}
