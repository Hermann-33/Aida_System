import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/money.dart';
import '../../domain/model/order.dart';

/// DEMO ONLY. Stands in for real staff/POS-driven order status until that
/// side is wired to this repository — see `docs/frontend/UI_REDESIGN_SPEC.md`
/// for why the real Dashboard/POS repository is out of scope here. Nothing
/// in this file touches Supabase; it is local, in-memory state a barista
/// would normally drive from the Dashboard.
enum DemoStage { placed, preparing, ready, completed }

class DemoOrder {
  const DemoOrder({
    required this.id,
    required this.orderNumber,
    required this.fulfillmentType,
    required this.itemName,
    required this.itemCount,
    required this.total,
    required this.stage,
    this.dismissed = false,
  });

  final String id;
  final String orderNumber;
  final FulfillmentType fulfillmentType;
  final String itemName;
  final int itemCount;
  final Money total;
  final DemoStage stage;

  /// True once the "thank you" grace period after [DemoStage.completed] has
  /// elapsed — hides the order from [activeDemoOrderProvider] without
  /// dropping it from state, so staff can still find and reset it.
  final bool dismissed;

  DemoOrder copyWith({DemoStage? stage, bool? dismissed}) => DemoOrder(
    id: id,
    orderNumber: orderNumber,
    fulfillmentType: fulfillmentType,
    itemName: itemName,
    itemCount: itemCount,
    total: total,
    stage: stage ?? this.stage,
    dismissed: dismissed ?? this.dismissed,
  );
}

/// Starts empty — a demo order only exists once the customer actually places
/// one (see [addFromCheckout], called from `cart_screen.dart` right after a
/// real checkout succeeds), or once staff adds a test order from the Staff
/// demo screen to exercise the flow without a full checkout each time.
class DemoOrderProgress extends Notifier<List<DemoOrder>> {
  @override
  List<DemoOrder> build() => const [];

  int _testOrderSeq = 0;

  /// How long the capsule keeps showing "Thank you" after the barista hands
  /// the order over, before it quietly drops off every tab.
  static const thankYouDuration = Duration(seconds: 6);

  /// Adds a demo order carrying the customer's real order details right
  /// after checkout succeeds — this is what actually makes
  /// [OrderProgressCapsule] appear; nothing shows it before an order exists.
  void addFromCheckout(OrderSnapshot order) {
    state = [
      ...state,
      DemoOrder(
        id: order.id,
        orderNumber: order.orderNumber,
        fulfillmentType: order.fulfillmentType,
        itemName: _summarize(order.lines),
        itemCount: order.itemCount,
        total: order.total,
        stage: DemoStage.placed,
      ),
    ];
  }

  /// Staff "Add test order" — lets the barista-side flow be exercised
  /// without a real checkout, alternating ASAP/scheduled fixtures.
  void addTestOrder() {
    _testOrderSeq += 1;
    final asap = _testOrderSeq.isOdd;
    state = [
      ...state,
      DemoOrder(
        id: 'demo-test-$_testOrderSeq',
        orderNumber: 'T${100 + _testOrderSeq}',
        fulfillmentType:
            asap ? FulfillmentType.asap : FulfillmentType.scheduled,
        itemName: asap ? 'Salted Caramel Latte' : 'Iced Matcha',
        itemCount: asap ? 2 : 1,
        total: asap ? Money.fromSen(2580) : Money.fromSen(1450),
        stage: DemoStage.placed,
      ),
    ];
  }

  /// Staff "Accept" — confirmed order enters preparation. There's no fixed
  /// timer to "ready": with a real queue, how long that takes depends on how
  /// many orders are ahead of it, which only the barista knows — so they
  /// declare it explicitly (see [markReady]) instead of a clock deciding.
  void accept(String id) => _setStage(id, DemoStage.preparing);

  /// Staff explicitly marks a drink ready for pickup.
  void markReady(String id) => _setStage(id, DemoStage.ready);

  /// Staff "Done" — barista marks the finished order handed over. Stays
  /// visible (as a "thank you") for [thankYouDuration] before dismissing
  /// itself, rather than vanishing the instant it's tapped.
  void complete(String id) {
    _setStage(id, DemoStage.completed);
    Future.delayed(thankYouDuration, () {
      final current = state.where((o) => o.id == id).firstOrNull;
      if (current?.stage == DemoStage.completed &&
          current?.dismissed == false) {
        _setDismissed(id, true);
      }
    });
  }

  /// Puts one order back to placed, to replay the flow.
  void reset(String id) {
    state = [
      for (final order in state)
        if (order.id == id)
          order.copyWith(stage: DemoStage.placed, dismissed: false)
        else
          order,
    ];
  }

  /// Clears every demo order, for a clean empty state.
  void clearAll() => state = const [];

  void _setStage(String id, DemoStage stage) {
    state = [
      for (final order in state)
        if (order.id == id) order.copyWith(stage: stage) else order,
    ];
  }

  void _setDismissed(String id, bool dismissed) {
    state = [
      for (final order in state)
        if (order.id == id) order.copyWith(dismissed: dismissed) else order,
    ];
  }
}

String _summarize(List<OrderLineSnapshot> lines) {
  if (lines.isEmpty) return 'Order';
  final first = lines.first.name;
  return lines.length > 1 ? '$first +${lines.length - 1} more' : first;
}

final demoOrderProgressProvider =
    NotifierProvider<DemoOrderProgress, List<DemoOrder>>(DemoOrderProgress.new);

/// The single order the customer-facing capsule shows — the most recently
/// updated order that hasn't been dismissed yet. Mirrors how
/// [FloatingCartBar] shows one aggregate view rather than a per-line list.
final activeDemoOrderProvider = Provider<DemoOrder?>((ref) {
  final orders = ref.watch(demoOrderProgressProvider);
  for (final order in orders) {
    if (!order.dismissed) return order;
  }
  return null;
});

/// Turns a live [DemoOrder] into the same [OrderSnapshot] shape the rest of
/// the app expects, so [OrderConfirmationScreen] (and the capsule) can reuse
/// one real screen instead of a separate demo-only detail view. Shared here
/// rather than duplicated, since both the capsule and the confirmation
/// screen itself now need it — see [OrderConfirmationScreen]'s doc comment
/// for why the screen prefers this over the real backend status.
OrderSnapshot demoOrderSnapshot(DemoOrder order) => OrderSnapshot(
  id: order.id,
  orderNumber: order.orderNumber,
  fulfillmentType: order.fulfillmentType,
  status: switch (order.stage) {
    DemoStage.placed => OrderStatus.confirmed,
    DemoStage.preparing => OrderStatus.preparing,
    DemoStage.ready => OrderStatus.ready,
    DemoStage.completed => OrderStatus.completed,
  },
  statusVersion: 1,
  currency: 'MYR',
  pricingVersion: 1,
  subtotal: order.total,
  total: order.total,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  lines: const [],
);
