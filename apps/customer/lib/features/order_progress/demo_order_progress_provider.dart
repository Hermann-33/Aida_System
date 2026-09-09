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

/// Starts empty. Demo orders are always synthetic and are created only from
/// developer tooling. Persisted customer orders are intentionally never copied
/// into this provider, so debug demonstrations cannot become order authority.
class DemoOrderProgress extends Notifier<List<DemoOrder>> {
  @override
  List<DemoOrder> build() => const [];

  int _testOrderSeq = 0;

  /// How long the capsule keeps showing "Thank you" after the barista hands
  /// the order over, before it quietly drops off every tab.
  static const thankYouDuration = Duration(seconds: 6);

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
