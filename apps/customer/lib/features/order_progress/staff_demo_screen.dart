import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/order.dart';
import 'demo_order_progress_provider.dart';

/// DEMO ONLY — stands in for the real Dashboard/POS "Accept" and "Done"
/// actions until that repository is wired to this one (see
/// `demo_order_progress_provider.dart`). Reachable from Profile → "Staff
/// demo" so the customer-facing [OrderProgressCapsule] can be driven live
/// without a second device or a real backend.
class StaffDemoScreen extends ConsumerWidget {
  const StaffDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(demoOrderProgressProvider);
    final notifier = ref.read(demoOrderProgressProvider.notifier);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      appBar: AppBar(
        backgroundColor: AidaColors.cream,
        elevation: 0,
        foregroundColor: AidaColors.textPrimary,
        title: Text(
          'Staff demo',
          style: AidaType.serif(size: 20, color: AidaColors.textPrimary),
        ),
        actions: [
          if (orders.isNotEmpty)
            TextButton(
              onPressed: notifier.clearAll,
              child: Text(
                'Clear all',
                style: AidaType.sans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AidaColors.coffee,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Stands in for the barista side of the Dashboard until that '
              'repository is wired up. A demo order only appears here (and '
              'the capsule only shows on the customer tabs) once someone '
              'actually checks out, or you add a test order below. Accept, '
              'Mark ready, and Done are all staff calls; nothing advances on '
              'a timer, since real prep time depends on how many orders are '
              'queued ahead of it.',
              style: AidaType.sans(size: 13, color: AidaColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: notifier.addTestOrder,
              style: OutlinedButton.styleFrom(
                foregroundColor: AidaColors.coffee,
                side: BorderSide(
                  color: AidaColors.coffee.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add test order'),
            ),
            const SizedBox(height: 20),
            if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'No orders yet.\nCheck out in the app, or add a test order above.',
                    textAlign: TextAlign.center,
                    style: AidaType.sans(size: 13, color: AidaColors.textMuted),
                  ),
                ),
              ),
            for (final order in orders) ...[
              _StaffOrderCard(
                order: order,
                onAccept: () => notifier.accept(order.id),
                onMarkReady: () => notifier.markReady(order.id),
                onDone: () => notifier.complete(order.id),
                onReset: () => notifier.reset(order.id),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaffOrderCard extends StatelessWidget {
  const _StaffOrderCard({
    required this.order,
    required this.onAccept,
    required this.onMarkReady,
    required this.onDone,
    required this.onReset,
  });

  final DemoOrder order;
  final VoidCallback onAccept;
  final VoidCallback onMarkReady;
  final VoidCallback onDone;
  final VoidCallback onReset;

  static const _stageLabel = {
    DemoStage.placed: 'Placed, awaiting staff',
    DemoStage.preparing: 'Preparing',
    DemoStage.ready: 'Ready, awaiting handover',
    DemoStage.completed: 'Handed over',
  };

  static final _stageColor = {
    DemoStage.placed: AidaColors.textMuted,
    DemoStage.preparing: AidaColors.coffee,
    DemoStage.ready: AidaColors.rewardGoldDeep,
    DemoStage.completed: AidaColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  '#${order.orderNumber} · ${order.itemName}',
                  style: AidaType.sans(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AidaColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AidaColors.latte.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.fulfillmentType == FulfillmentType.asap
                      ? 'Now'
                      : 'Scheduled',
                  style: AidaType.sans(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: AidaColors.coffee,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · ${order.total.formatted}',
            style: AidaType.sans(size: 13, color: AidaColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _stageColor[order.stage],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _stageLabel[order.stage]!,
                style: AidaType.sans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: _stageColor[order.stage],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (order.stage == DemoStage.placed)
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AidaColors.coffee,
                      foregroundColor: AidaColors.cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Accept order'),
                  ),
                ),
              if (order.stage == DemoStage.preparing)
                Expanded(
                  child: FilledButton(
                    onPressed: onMarkReady,
                    style: FilledButton.styleFrom(
                      backgroundColor: AidaColors.coffee,
                      foregroundColor: AidaColors.cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Mark ready'),
                  ),
                ),
              if (order.stage == DemoStage.ready)
                Expanded(
                  child: FilledButton(
                    onPressed: onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AidaColors.rewardGoldDeep,
                      foregroundColor: AidaColors.cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Done, handed over'),
                  ),
                ),
              if (order.stage == DemoStage.completed)
                Expanded(
                  child: Text(
                    order.dismissed
                        ? 'Capsule dismissed. Reset to replay.'
                        : 'Showing "thank you" on the capsule now…',
                    style: AidaType.sans(
                      size: 12.5,
                      color: AidaColors.textMuted,
                    ),
                  ),
                ),
              if (order.stage != DemoStage.placed) ...[
                const SizedBox(width: 10),
                TextButton(onPressed: onReset, child: const Text('Reset')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
