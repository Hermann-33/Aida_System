import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/order.dart';

const _stages = ['Confirmed', 'Preparing', 'Ready for pickup', 'Completed'];

/// Shows persisted backend status. Realtime only invalidates [orderProvider];
/// this screen never advances an order on a client timer.
class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final OrderSnapshot order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(orderProvider(order.id)).value ?? order;
    final activeStage = _stageIndex(current.status);
    final cancelled = current.status == OrderStatus.cancelled;
    final ready = current.status == OrderStatus.ready;
    final completed = current.status == OrderStatus.completed;

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            children: [
              const Spacer(),
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
                  cancelled
                      ? Icons.close_rounded
                      : ready
                      ? Icons.local_cafe_rounded
                      : Icons.coffee_maker_rounded,
                  size: 60,
                  color: AidaColors.coffee.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                cancelled
                    ? 'Order cancelled'
                    : completed
                    ? 'Order completed'
                    : ready
                    ? 'Order ready!'
                    : current.status == OrderStatus.scheduled
                    ? 'Pickup scheduled'
                    : 'Order confirmed',
                style: AidaType.serif(size: 24, color: AidaColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                cancelled
                    ? 'This order will not be prepared.'
                    : ready
                    ? 'Head to the counter — order ${current.orderNumber} is waiting for you.'
                    : 'Pay at the counter when you collect your order.',
                textAlign: TextAlign.center,
                style: AidaType.sans(size: 13.5, color: AidaColors.textMuted),
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
              const SizedBox(height: 32),
              if (!cancelled)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _stages.length; i++)
                        _TimelineStep(
                          label: _stages[i],
                          state:
                              i < activeStage
                                  ? _StepState.done
                                  : i == activeStage
                                  ? _StepState.active
                                  : _StepState.pending,
                          isLast: i == _stages.length - 1,
                        ),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: FilledButton.styleFrom(
                    backgroundColor: AidaColors.coffee,
                    foregroundColor: AidaColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Back to Menu',
                    style: AidaType.sans(size: 14.5, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
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

enum _StepState { done, active, pending }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.state,
    required this.isLast,
  });

  final String label;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor =
        state == _StepState.pending ? AidaColors.latte : AidaColors.coffee;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      state == _StepState.done
                          ? AidaColors.coffee
                          : Colors.transparent,
                  border: Border.all(color: dotColor, width: 2),
                ),
                child:
                    state == _StepState.done
                        ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AidaColors.cream,
                        )
                        : state == _StepState.active
                        ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AidaColors.coffee,
                            ),
                          ),
                        )
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        state == _StepState.done
                            ? AidaColors.coffee
                            : AidaColors.latte,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 22, top: 2),
            child: Text(
              label,
              style: AidaType.sans(
                size: 13.5,
                weight:
                    state == _StepState.pending
                        ? FontWeight.w500
                        : FontWeight.w700,
                color:
                    state == _StepState.pending
                        ? AidaColors.textMuted
                        : AidaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
