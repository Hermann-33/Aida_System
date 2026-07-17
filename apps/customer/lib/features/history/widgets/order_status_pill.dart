import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/order.dart';

/// Shared by the order history list and the order detail receipt so the
/// status always reads identically in both places.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      OrderStatus.ready => 'Ready',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AidaColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 13,
            color: AidaColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AidaType.sans(
              size: 11.5,
              weight: FontWeight.w700,
              color: AidaColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
