import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/order.dart';
import '../order_progress/demo_order_progress_provider.dart';
import '../order_progress/liquid_stage_tracker.dart';

const _stages = ['Confirmed', 'Preparing', 'Ready for pickup', 'Completed'];

/// DEMO: while staff/POS status updates aren't wired to the real backend,
/// an order this screen also finds in [demoOrderProgressProvider] shows that
/// live demo status instead of the (permanently "confirmed") real one —
/// otherwise the real [orderProvider] fetch would silently win over
/// whatever the Staff demo screen just did, since it resolves successfully
/// for a genuinely-placed order, it just never advances past "confirmed".
/// Once real status wiring lands, delete this screen's demo branch and the
/// whole `order_progress` demo feature along with it.
class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final OrderSnapshot order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoOrders = ref.watch(demoOrderProgressProvider);
    final demoMatch = demoOrders.where((o) => o.id == order.id).firstOrNull;

    // If this order used to be tracked in the demo system but just
    // dismissed (thank-you grace period elapsed), follow it back to the
    // menu rather than leaving this screen showing a "ghost" order.
    ref.listen<List<DemoOrder>>(demoOrderProgressProvider, (previous, next) {
      final wasLive =
          previous?.any((o) => o.id == order.id && !o.dismissed) ?? false;
      final stillLive = next.any((o) => o.id == order.id && !o.dismissed);
      if (wasLive && !stillLive && context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });

    final current =
        demoMatch != null
            ? demoOrderSnapshot(demoMatch)
            : ref.watch(orderProvider(order.id)).value ?? order;
    final activeStage = _stageIndex(current.status);
    final cancelled = current.status == OrderStatus.cancelled;
    final ready = current.status == OrderStatus.ready;
    final completed = current.status == OrderStatus.completed;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/order_confirmed.png', fit: BoxFit.cover),
          // A light wash, not a heavy tint — the photo is already pale, this
          // just guarantees the darker tabletop patch on the right never
          // fights the text.
          DecoratedBox(
            decoration: BoxDecoration(
              color: AidaColors.cardWhite.withValues(alpha: 0.35),
            ),
          ),
          _ConfirmationContent(
            current: current,
            activeStage: activeStage,
            cancelled: cancelled,
            ready: ready,
            completed: completed,
          ),
        ],
      ),
    );
  }
}

class _ConfirmationContent extends StatelessWidget {
  const _ConfirmationContent({
    required this.current,
    required this.activeStage,
    required this.cancelled,
    required this.ready,
    required this.completed,
  });

  final OrderSnapshot current;
  final int activeStage;
  final bool cancelled;
  final bool ready;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (cancelled) ...[
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AidaColors.latte.withValues(alpha: 0.5),
                              AidaColors.caramelTint,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 60,
                          color: AidaColors.coffee.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    Text(
                      cancelled
                          ? 'Order cancelled'
                          : completed
                          ? 'Thank you!'
                          : ready
                          ? 'Order ready!'
                          : current.status == OrderStatus.scheduled
                          ? 'Pickup scheduled'
                          : 'Order confirmed',
                      style: AidaType.serif(
                        size: 24,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cancelled
                          ? 'This order will not be prepared.'
                          : completed
                          ? 'Enjoy your drink. See you again soon.'
                          : ready
                          ? 'Head to the counter. Order ${current.orderNumber} is waiting for you.'
                          : 'Pay at the counter when you collect your order.',
                      textAlign: TextAlign.center,
                      style: AidaType.sans(
                        size: 13.5,
                        color: AidaColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order ${current.orderNumber}',
                      style: AidaType.sans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AidaColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (!cancelled)
                      LiquidStageTracker(
                        stageIndex: activeStage,
                        labels: _stages,
                      ),
                    const SizedBox(height: 40),
                    _PopInButton(
                      onTap:
                          () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                      label: 'Back to Menu',
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

int _stageIndex(OrderStatus status) => switch (status) {
  OrderStatus.confirmed || OrderStatus.scheduled => 0,
  OrderStatus.preparing => 1,
  OrderStatus.ready => 2,
  OrderStatus.completed => 3,
  OrderStatus.cancelled => 0,
};

/// Smaller pill (not the old full-width bar) that pops in with a little
/// overshoot once the screen settles, the same bounce
/// [FloatingCartBar]'s thumbnails use, rather than an ongoing/looping
/// animation — a repeating one here would never let a test's
/// `pumpAndSettle()` finish, since this screen is reached mid widget-test
/// flows.
class _PopInButton extends StatelessWidget {
  const _PopInButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: AidaColors.coffee,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AidaColors.coffee.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              label,
              style: AidaType.sans(
                size: 14,
                weight: FontWeight.w700,
                color: AidaColors.cream,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
