import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/cart.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/order.dart';
import 'order_history_screen.dart' show formatOrderDate;
import 'widgets/order_status_pill.dart';

/// A single past order's receipt. The reference this was built from also had
/// a "Voucher" tab for in-store redemption — skipped here since Aida has no
/// per-order voucher system; that concept belongs with the stamp card on the
/// Rewards page, not with an individual order, and is planned there instead.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.order});

  final PastOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuItemsProvider);
    final menu = menuAsync.value ?? const <MenuItem>[];

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Your Order',
                      textAlign: TextAlign.center,
                      style: AidaType.serif(
                        size: 20,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  _StatusCard(order: order),
                  const SizedBox(height: 16),
                  _ReceiptCard(order: order, menu: menu),
                ],
              ),
            ),
            _DoneBar(onDone: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

/// Pins a clear closing action to the bottom — without it, a short receipt
/// (a single item, no voucher tab) just trails off into empty cream
/// background with nothing anchoring the page.
class _DoneBar extends StatelessWidget {
  const _DoneBar({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: AidaColors.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AidaColors.espresso.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: AidaColors.coffee,
              foregroundColor: AidaColors.cream,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'Done',
              style: AidaType.sans(size: 15, weight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final PastOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AidaColors.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AidaColors.success),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order confirmed',
                  style: AidaType.sans(
                    size: 14.5,
                    weight: FontWeight.w700,
                    color: AidaColors.textPrimary,
                  ),
                ),
                Text(
                  'Ready for pickup at the counter',
                  style: AidaType.sans(size: 12, color: AidaColors.textMuted),
                ),
              ],
            ),
          ),
          OrderStatusPill(status: order.status),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.order, required this.menu});

  final PastOrder order;
  final List<MenuItem> menu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order ${order.orderNumber}',
                  style: AidaType.sans(
                    size: 14.5,
                    weight: FontWeight.w700,
                    color: AidaColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatOrderDate(order.placedAt),
                style: AidaType.sans(size: 12, color: AidaColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AidaColors.latte),
          const SizedBox(height: 14),
          for (final line in order.lineItems) ...[
            _ReceiptLine(line: line, menu: menu),
            const SizedBox(height: 12),
          ],
          const Divider(height: 1, color: AidaColors.latte),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Subtotal',
                style: AidaType.sans(size: 13, color: AidaColors.textMuted),
              ),
              const Spacer(),
              Text(
                order.subtotal.formatted,
                style: AidaType.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AidaColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Total',
                style: AidaType.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AidaColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                order.subtotal.formatted,
                style: AidaType.sans(
                  size: 18,
                  weight: FontWeight.w800,
                  color: AidaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AidaColors.latte),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.credit_card_rounded,
                size: 16,
                color: AidaColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Paid with ${order.paymentMethodLabel}',
                style: AidaType.sans(size: 13, color: AidaColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.line, required this.menu});

  final CartLineItem line;
  final List<MenuItem> menu;

  @override
  Widget build(BuildContext context) {
    final addOns = addOnTotalFor(line.addOnIds, menu);
    final lineTotal = line.lineTotal(addOns);
    final summary = line.configSummary(menu);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.item.name,
                style: AidaType.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AidaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${line.quantity} × ${line.unitPrice(addOns).formatted}',
                style: AidaType.sans(size: 12, color: AidaColors.textMuted),
              ),
              if (summary != null) ...[
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: AidaType.sans(size: 12, color: AidaColors.textMuted),
                ),
              ],
              if (line.note != null) ...[
                const SizedBox(height: 2),
                Text(
                  '"${line.note}"',
                  style: AidaType.sans(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AidaColors.coffee,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          lineTotal.formatted,
          style: AidaType.sans(
            size: 14,
            weight: FontWeight.w700,
            color: AidaColors.coffee,
          ),
        ),
      ],
    );
  }
}
