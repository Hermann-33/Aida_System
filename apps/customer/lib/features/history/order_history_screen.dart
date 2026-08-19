import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/order.dart';
import 'order_detail_screen.dart';
import 'widgets/order_status_pill.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
]; // Dart's DateTime has no built-in formatter, and adding intl for one
// "13 Jul 2026" string isn't worth a new dependency.

String formatOrderDate(DateTime dt) =>
    '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

/// Owner-scoped order history from get_my_orders(). Realtime is used only to
/// invalidate and refetch these authoritative snapshots.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderHistoryProvider);

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
                  Text(
                    'My Orders',
                    style: AidaType.serif(
                      size: 22,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: orders.when(
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(
                        color: AidaColors.coffee,
                      ),
                    ),
                error:
                    (error, _) => _HistoryError(
                      onRetry: () => ref.invalidate(orderHistoryProvider),
                    ),
                data:
                    (values) =>
                        values.isEmpty
                            ? const _EmptyHistory()
                            : RefreshIndicator(
                              onRefresh:
                                  () async =>
                                      ref.refresh(orderHistoryProvider.future),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  20,
                                ),
                                itemCount: values.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 12),
                                itemBuilder:
                                    (_, i) => _OrderCard(order: values[i]),
                              ),
                            ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Unable to load your orders',
          style: AidaType.sans(size: 14, color: AidaColors.textMuted),
        ),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AidaColors.latte.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 38,
                color: AidaColors.coffee,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No orders yet',
              style: AidaType.sans(
                size: 15,
                weight: FontWeight.w700,
                color: AidaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Orders you place will show up here.',
              textAlign: TextAlign.center,
              style: AidaType.sans(size: 12.5, color: AidaColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSnapshot order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AidaColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order ${order.orderNumber}',
                            style: AidaType.sans(
                              size: 15.5,
                              weight: FontWeight.w800,
                              color: AidaColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formatOrderDate(order.createdAt.toLocal()),
                            style: AidaType.sans(
                              size: 12,
                              color: AidaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OrderStatusPill(status: order.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ThumbnailStack(order: order),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order.itemCount == 1
                              ? '1 item'
                              : '${order.itemCount} items',
                          style: AidaType.sans(
                            size: 11.5,
                            color: AidaColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          order.total.formatted,
                          style: AidaType.sans(
                            size: 17,
                            weight: FontWeight.w800,
                            color: AidaColors.coffee,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AidaColors.latte.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AidaColors.coffee,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item photos as an overlapping stack — the modern "avatar group" pattern —
/// instead of a plain spaced row. Each circle gets a card-white ring so the
/// overlap reads as deliberate layering, not collision.
class _ThumbnailStack extends StatelessWidget {
  const _ThumbnailStack({required this.order});

  final OrderSnapshot order;

  static const _size = 40.0;
  static const _overlap = 26.0;
  static const _maxShown = 4;

  @override
  Widget build(BuildContext context) {
    final shown = order.lines.take(_maxShown).toList();
    final extra = order.lines.length - shown.length;
    final slots = shown.length + (extra > 0 ? 1 : 0);

    return SizedBox(
      width: _size + (slots - 1) * _overlap,
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _overlap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AidaColors.cardWhite,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: _size - 4,
                  height: _size - 4,
                  decoration: const BoxDecoration(
                    color: AidaColors.caramelTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_cafe_rounded,
                    size: 18,
                    color: AidaColors.coffee,
                  ),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * _overlap,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: AidaColors.latte.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AidaColors.cardWhite, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: AidaType.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AidaColors.coffee,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
