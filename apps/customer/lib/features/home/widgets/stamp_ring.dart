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
/// The ring animates its own fill on first appearance and again on tap — a
/// punch card that just appears fully punched loses the "you earned these
/// one at a time" feeling the metaphor is built on.
///
/// The centre shows both the icon and the "collected/required" count as text.
/// Ten thin segments read as roughly "mostly full" at a glance, not as an
/// exact 7 — the number is what actually answers "how many do I have."
class StampRing extends StatefulWidget {
  const StampRing({super.key, required this.card, this.size = 84});

  final StampCard card;
  final double size;

  @override
  State<StampRing> createState() => _StampRingState();
}

class _StampRingState extends State<StampRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late Animation<double> _fill = _buildFillAnimation();

  Animation<double> _buildFillAnimation() {
    return Tween<double>(
      begin: 0,
      end: widget.card.collected.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StampRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.collected != widget.card.collected) {
      setState(() => _fill = _buildFillAnimation());
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Replays the fill on tap — a small, satisfying re-affirmation of
      // progress, the same reason a real punch card is fun to look at.
      onTap: () => _controller.forward(from: 0),
      child: AnimatedBuilder(
        animation: _fill,
        builder: (context, _) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _StampRingPainter(
                    segments: widget.card.required_,
                    filled: _fill.value,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.coffee_rounded,
                      size: widget.size * 0.24,
                      color: AidaColors.coffee,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.card.collected}/${widget.card.required_}',
                      style: TextStyle(
                        fontSize: widget.size * 0.165,
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
        },
      ),
    );
  }
}

class _StampRingPainter extends CustomPainter {
  _StampRingPainter({required this.segments, required this.filled});

  final int segments;

  /// How many segments are filled, as a continuous value — e.g. 3.4 means
  /// three full segments plus the fourth 40% swept in, which is what makes
  /// the animation read as a ring filling rather than segments popping on.
  final double filled;

  static const _gapDeg = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = segments;
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
      final segmentFill = (filled - i).clamp(0.0, 1.0);

      paint.color = unfilled;
      canvas.drawArc(rect, angle, segmentSweep, false, paint);

      if (segmentFill > 0) {
        paint.color = AidaColors.rewardGold;
        canvas.drawArc(rect, angle, segmentSweep * segmentFill, false, paint);
      }

      angle += segmentSweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _StampRingPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.filled != filled;
}
