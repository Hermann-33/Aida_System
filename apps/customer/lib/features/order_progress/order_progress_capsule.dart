import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../cart/order_confirmation_screen.dart';
import 'demo_order_progress_provider.dart';

/// Same fixed slot and pill language as [FloatingCartBar] — visible on any
/// tab whenever a demo order is in flight, empty otherwise. DEMO DATA: reads
/// [activeDemoOrderProvider], not a real order; see that file's doc comment.
class OrderProgressCapsule extends ConsumerWidget {
  const OrderProgressCapsule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(activeDemoOrderProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
      child:
          order == null
              ? const SizedBox.shrink(key: ValueKey('order-progress-empty'))
              : _Capsule(
                key: ValueKey('order-progress-${order.id}'),
                order: order,
              ),
    );
  }
}

const _fillFor = {
  DemoStage.placed: 0.0,
  DemoStage.preparing: 0.45,
  DemoStage.ready: 0.85,
  DemoStage.completed: 1.0,
};

const _labelFor = {
  DemoStage.placed: 'Order placed, waiting for the barista',
  DemoStage.preparing: 'Preparing your order',
  DemoStage.ready: 'Ready for pickup!',
  DemoStage.completed: 'Thank you for your order!',
};

class _Capsule extends StatefulWidget {
  const _Capsule({super.key, required this.order});

  final DemoOrder order;

  @override
  State<_Capsule> createState() => _CapsuleState();
}

class _CapsuleState extends State<_Capsule>
    with SingleTickerProviderStateMixin {
  static const _radius = 50.0;
  static const _badgeSize = 34.0; // 30 + ~13%

  late final AnimationController _fill;
  DemoStage? _lastStage;

  // A fixed per-order phase, not a running clock — an endlessly-repeating
  // animation here would never let pumpAndSettle() finish in tests (this
  // capsule lives in AppShell, so it's present during nearly every widget
  // test in the app). Still reads as a wave, just not a live one.
  late final double _wavePhase = (widget.order.id.hashCode % 628) / 100;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      value: _fillFor[widget.order.stage]!,
    );
    _lastStage = widget.order.stage;
  }

  @override
  void didUpdateWidget(covariant _Capsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stage = widget.order.stage;
    if (stage != _lastStage) {
      // Every transition is an explicit staff tap now, not a timer counting
      // down to a guessed duration — so it's always a quick, deliberate
      // step rather than a slow climb toward a promised time.
      _fill.animateTo(
        _fillFor[stage]!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
      _lastStage = stage;
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                // Just the current snapshot — OrderConfirmationScreen
                // itself now stays subscribed to the demo provider (it
                // needs to, since real order history/checkout can land on
                // the same screen), so this doesn't need to.
                builder:
                    (_) => OrderConfirmationScreen(
                      order: demoOrderSnapshot(order),
                    ),
              ),
            ),
        // Shadow lives on this outer, unclipped box — the ClipRRect below
        // only shapes the liquid fill, and clipping it would clip the
        // shadow too if the two swapped places.
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: AidaColors.espresso.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              children: [
                // Base capsule — same espresso surface as the cart bar.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AidaColors.espresso),
                  ),
                ),
                // Liquid fill with a wavy leading edge.
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fill,
                    builder:
                        (context, _) => CustomPaint(
                          painter: _LiquidFillPainter(
                            fill: _fill.value,
                            phase: _wavePhase,
                          ),
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Container(
                          width: _badgeSize,
                          height: _badgeSize,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AidaColors.latte,
                                AidaColors.caramelTint,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            color: AidaColors.coffee,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Order #${order.orderNumber}',
                              style: AidaType.sans(
                                size: 10.5,
                                weight: FontWeight.w700,
                                color: AidaColors.cream.withValues(alpha: 0.75),
                              ),
                            ),
                            Text(
                              _labelFor[order.stage]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AidaType.sans(
                                size: 13,
                                weight: FontWeight.w700,
                                color: AidaColors.cream,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.total.formatted,
                        style: AidaType.sans(
                          size: 14,
                          weight: FontWeight.w800,
                          color: AidaColors.rewardGold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AidaColors.cream,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fills left→right up to [fill] of the width, with a soft vertical wave
/// riding the leading edge instead of a flat progress-bar line.
class _LiquidFillPainter extends CustomPainter {
  const _LiquidFillPainter({required this.fill, required this.phase});

  final double fill;
  final double phase;

  static const _amplitude = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill <= 0) return;
    final baseX = size.width * fill;
    final waveLength = math.max(size.height, 1) * 1.3;

    final path = Path()..moveTo(0, 0);
    const steps = 16;
    for (var i = 0; i <= steps; i++) {
      final y = size.height * i / steps;
      final dx = math.sin((y / waveLength * 2 * math.pi) + phase) * _amplitude;
      path.lineTo((baseX + dx).clamp(0.0, size.width), y);
    }
    path
      ..lineTo(0, size.height)
      ..close();

    final paint =
        Paint()
          ..shader = LinearGradient(
            colors: [AidaColors.coffee, AidaColors.coffeeLight],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidFillPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.phase != phase;
}
