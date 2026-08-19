import 'package:aida_customer/application/order_checkout.dart';
import 'package:aida_customer/core/error/failures.dart';
import 'package:aida_customer/core/error/result.dart';
import 'package:aida_customer/domain/model/order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_order_repository.dart';

void main() {
  const request = OrderRequest(
    fulfillmentType: FulfillmentType.asap,
    items: [OrderSelectionLine(itemId: 'item-id', quantity: 1)],
  );

  test('slots honor lead time, interval and horizon', () {
    final slots = derivePickupSlots(
      TestOrderRepository.policy,
      maximumSlots: 500,
    );
    expect(slots.first, DateTime.utc(2026, 8, 13, 2, 30));
    expect(slots[1].difference(slots.first), const Duration(minutes: 15));
    expect(slots.last.isAfter(DateTime.utc(2026, 8, 15, 2)), isFalse);
  });

  test('ambiguous failure reuses id and success starts a new intent', () async {
    final repository = _SequencedRepository();
    var next = 0;
    final session = OrderCheckoutSession(
      repository,
      createId: () => 'request-${++next}',
    );

    expect(await session.place(request), isA<Err<OrderSnapshot>>());
    expect(await session.place(request), isA<Ok<OrderSnapshot>>());
    expect(repository.ids, ['request-1', 'request-1']);
    expect(await session.place(request), isA<Ok<OrderSnapshot>>());
    expect(repository.ids.last, 'request-2');
  });
}

class _SequencedRepository extends TestOrderRepository {
  int attempts = 0;
  final ids = <String?>[];

  @override
  Future<Result<OrderSnapshot>> placeCustomerOrder(OrderRequest request) async {
    ids.add(request.clientRequestId);
    attempts++;
    if (attempts == 1) return const Err(ServerFailure('Connection lost'));
    return Ok(TestOrderRepository.order);
  }
}
