import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../domain/model/loyalty.dart';

/// Stamp progress as a compact ring, replacing the zigzag [StampCard] line.
///
/// Drawn as `required_` discrete arcs with gaps between them, not one smooth
/// sweep — a plain progress ring abstracts away *which* stamp a customer is
/// on, and the punch-card metaphor (ten individual marks, filled one by one)
/// is what makes stamp cards satisfying in the first place.
///
/// The centre shows both the icon and the "collected/required" count as text.
/// Ten thin segments read as roughly "mostly full" at a glance, not as an
/// exact 7 — the number is what actually answers "how many do I have."
class StampRing extends StatelessWidget {
  const StampRing({super.key, required this.card, this.size = 84});

  final StampCard card;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _StampRingPainter(card: card)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.coffee_rounded, size: size * 0.24, color: AidaColors.coffee),
              const SizedBox(height: 2),
              Text(
                '${card.collected}/${card.required_}',
                style: TextStyle(
                  fontSize: size * 0.165,
                  fontWeight: FontWeight.w800,
                  color: AidaColors.textPrimary,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StampRingPainter extends CustomPainter {
  _StampRingPainter({required this.card});

  final StampCard card;

  static const _gapDeg = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = card.required_;
    if (n == 0) return;

    final strokeWidth = size.width * 0.12;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gap = _gapDeg * pi / 180;
    final segmentSweep = (2 * pi - n * gap) / n;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Start at the top (-90°), offset half a gap so segments sit symmetrically
    // around twelve o'clock rather than one edge landing exactly on it.
    // The unfilled track is a translucent Coffee tint, not Latte — Latte at
    // this stroke width can read as neutral gray rather than warm. Fading the
    // brand brown itself guarantees it stays warm, however thin the stroke.
    final unfilled = AidaColors.coffee.withValues(alpha: 0.18);

    var angle = -pi / 2 + gap / 2;
    for (var i = 0; i < n; i++) {
      paint.color = card.isFilled(i) ? AidaColors.rewardGold : unfilled;
      canvas.drawArc(rect, angle, segmentSweep, false, paint);
      angle += segmentSweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _StampRingPainter oldDelegate) =>
      oldDelegate.card.collected != card.collected ||
      oldDelegate.card.required_ != card.required_;
}
