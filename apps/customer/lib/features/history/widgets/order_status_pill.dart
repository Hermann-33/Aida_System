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
      OrderStatus.confirmed => 'Confirmed',
      OrderStatus.scheduled => 'Scheduled',
      OrderStatus.preparing => 'Preparing',
      OrderStatus.ready => 'Ready',
      OrderStatus.completed => 'Completed',
      OrderStatus.cancelled => 'Cancelled',
    };
    final color = switch (status) {
      OrderStatus.ready || OrderStatus.completed => AidaColors.success,
      OrderStatus.cancelled => AidaColors.error,
      _ => AidaColors.coffee,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == OrderStatus.cancelled
                ? Icons.cancel_rounded
                : Icons.circle_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AidaType.sans(
              size: 11.5,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
