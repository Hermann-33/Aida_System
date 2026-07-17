import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';

/// The four stages a real order actually goes through — payment, then
/// creation, then two kitchen stages. Copy is written as the real, shipped
/// experience — not flagged as a demo to the customer.
const _stages = [
  'Payment received',
  'Order created',
  'Kitchen is preparing your order',
  'Ready for pickup',
];

/// Shown after "Place Order." No backend exists to actually receive this
/// order, and no staff/kitchen app exists yet to mark real stages complete
/// (that's the separate Admin/POS app in the wider Aida System) — so this
/// timeline advances itself on a fixed timer rather than a real status push.
/// The fact that nothing real is behind it is a true statement about the
/// current build, not something a real customer should ever read; that
/// caveat lives here in code comments, not in the screen's text. See the
/// cart design spec §2.
///
/// The cart is already empty by the time this screen shows — CartScreen
/// clears it at the moment "Place Order" is tapped, not here, so the cart is
/// correctly empty no matter how the customer navigates away from this
/// screen (this button, or the device back gesture).
class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  // Payment has already happened by the time this screen appears, so the
  // timeline opens with that stage already complete and "Order created" as
  // the active one — not at zero.
  int _activeStage = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_activeStage >= _stages.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _activeStage++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _activeStage == _stages.length - 1;

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
                  ready ? Icons.local_cafe_rounded : Icons.coffee_maker_rounded,
                  size: 60,
                  color: AidaColors.coffee.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                ready ? 'Order ready!' : 'Preparing your order',
                style: AidaType.serif(size: 24, color: AidaColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                ready
                    ? 'Head to the counter — order #${widget.orderNumber} is waiting for you.'
                    : 'Hang tight, this only takes a moment.',
                textAlign: TextAlign.center,
                style: AidaType.sans(size: 13.5, color: AidaColors.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${widget.orderNumber}',
                style: AidaType.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AidaColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _stages.length; i++)
                      _TimelineStep(
                        label: _stages[i],
                        state:
                            i < _activeStage
                                ? _StepState.done
                                : i == _activeStage
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
