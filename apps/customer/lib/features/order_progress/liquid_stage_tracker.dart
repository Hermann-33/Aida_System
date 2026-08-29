import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';

/// A vertical liquid-filled tube tracking progress through [labels], rising
/// from the bottom (first label) to the top (last label) — same liquid
/// language as [OrderProgressCapsule], just tall instead of wide, for
/// screens with room to give the metaphor its own moment.
class LiquidStageTracker extends StatelessWidget {
  const LiquidStageTracker({
    super.key,
    required this.stageIndex,
    required this.labels,
  });

  /// 0-based index into [labels] for the current stage.
  final int stageIndex;
  final List<String> labels;

  static const _height = 260.0;
  static const _tubeWidth = 46.0;

  @override
  Widget build(BuildContext context) {
    final fraction = (stageIndex + 1) / labels.length;
    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LiquidTube(fraction: fraction),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              // Reversed so the last label sits at the top, matching the
              // tube filling upward as stages complete.
              children: [
                for (var i = labels.length - 1; i >= 0; i--)
                  _StageLabel(
                    label: labels[i],
                    reached: i <= stageIndex,
                    active: i == stageIndex,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageLabel extends StatelessWidget {
  const _StageLabel({
    required this.label,
    required this.reached,
    required this.active,
  });

  final String label;
  final bool reached;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (active)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AidaColors.coffee,
            ),
          )
        else if (reached)
          const Icon(Icons.check_rounded, size: 14, color: AidaColors.coffee)
        else
          const SizedBox(width: 14),
        if (reached && !active) const SizedBox(width: 4),
        Text(
          label,
          style: AidaType.sans(
            size: 13.5,
            weight: reached ? FontWeight.w700 : FontWeight.w500,
            color: reached ? AidaColors.textPrimary : AidaColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _LiquidTube extends StatelessWidget {
  const _LiquidTube({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: LiquidStageTracker._tubeWidth,
      decoration: BoxDecoration(
        color: AidaColors.latte.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(LiquidStageTracker._tubeWidth / 2),
        border: Border.all(color: AidaColors.latte.withValues(alpha: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LiquidStageTracker._tubeWidth / 2),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder:
              (context, value, _) => CustomPaint(
                size: Size.infinite,
                // Fixed wave phase, not a running clock — an endlessly
                // repeating animation here would never let a test's
                // pumpAndSettle() finish.
                painter: _VerticalLiquidPainter(fill: value, phase: 0.6),
              ),
        ),
      ),
    );
  }
}

class _VerticalLiquidPainter extends CustomPainter {
  const _VerticalLiquidPainter({required this.fill, required this.phase});

  final double fill;
  final double phase;

  static const _amplitude = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill <= 0) return;
    final filledHeight = size.height * fill;
    final baseY = size.height - filledHeight;
    final waveLength = math.max(size.width, 1) * 1.6;

    final path = Path()..moveTo(0, size.height);
    const steps = 16;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final dy = math.sin((x / waveLength * 2 * math.pi) + phase) * _amplitude;
      path.lineTo(x, (baseY + dy).clamp(0.0, size.height));
    }
    path
      ..lineTo(size.width, size.height)
      ..close();

    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AidaColors.coffeeLight, AidaColors.coffee],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VerticalLiquidPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.phase != phase;
}
