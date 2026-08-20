import 'package:aida_customer/domain/model/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes numeric server order number as display string', () {
    final order = OrderSnapshot.fromJson({
      'id': 'cb4230ff-2742-49cc-882c-4da6341cee79',
      'orderNumber': 100013,
      'fulfillmentType': 'scheduled',
      'requestedPickupAt': '2026-08-20T23:30:00+00:00',
      'status': 'scheduled',
      'statusVersion': 1,
      'currency': 'MYR',
      'pricingVersion': 1,
      'subtotalSen': 3000,
      'totalSen': 3000,
      'createdAt': '2026-08-20T17:53:13.79766+00:00',
      'updatedAt': '2026-08-20T17:53:13.79766+00:00',
      'lines': <Object?>[],
    });

    expect(order.orderNumber, '100013');
    expect(order.status, OrderStatus.scheduled);
    expect(order.fulfillmentType, FulfillmentType.scheduled);
  });
}
