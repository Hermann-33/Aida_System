import 'package:flutter/material.dart';

import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';

/// Shown after "Place Order." Copy is written as the real, shipped
/// experience — not flagged as a demo to the customer. The fact that no
/// backend exists to actually receive this order is a true statement about
/// the current build, not something a real customer should ever read; that
/// caveat lives in the design spec and code comments, not in this screen's
/// text. See the cart design spec §2.
///
/// The cart is already empty by the time this screen shows — CartScreen
/// clears it at the moment "Place Order" is tapped, not here, so the cart is
/// correctly empty no matter how the customer navigates away from this
/// screen (this button, or the device back gesture).
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AidaColors.rewardGold,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 44,
                  color: AidaColors.espresso,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Order Placed!',
                style: AidaType.serif(size: 26, color: AidaColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #$orderNumber',
                style: AidaType.sans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AidaColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thanks for ordering with Aida Café. See you soon!',
                textAlign: TextAlign.center,
                style: AidaType.sans(size: 14, height: 1.5, color: AidaColors.textMuted),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
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
