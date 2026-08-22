import 'package:aida_customer/domain/model/order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_order_repository.dart';

void main() {
  test('maps policy and authoritative quote totals', () {
    final policy = TestOrderRepository.policy;
    final quote = TestOrderRepository.quote;

    expect(policy.timezone, 'Asia/Kuala_Lumpur');
    expect(policy.minimumLeadMinutes, 30);
    expect(quote.total.sen, 3480);
    expect(quote.lines.single.unitPrice.sen, 1740);
    expect(
      quote.lines.single.configurationLabel,
      'Large · Temperature: Hot · Sweetness: Less sweet · Extra Shot',
    );
  });

  test('serializes only trusted ASAP selections', () {
    const request = OrderRequest(
      fulfillmentType: FulfillmentType.asap,
      items: [
        OrderSelectionLine(
          itemId: 'item-id',
          variantId: 'variant-id',
          addOnIds: ['addon-id'],
          optionValueIds: ['temperature-hot', 'sweetness-regular'],
          quantity: 2,
          note: ' less ice ',
        ),
      ],
    );

    expect(request.toJson(), {
      'fulfillmentType': 'asap',
      'items': [
        {
          'itemId': 'item-id',
          'variantId': 'variant-id',
          'addOnIds': ['addon-id'],
          'optionValueIds': ['temperature-hot', 'sweetness-regular'],
          'quantity': 2,
          'note': 'less ice',
        },
      ],
    });
    expect(request.toJson().toString(), isNot(contains('price')));
    expect(request.toJson().toString(), isNot(contains('total')));
  });

  test('serializes scheduled pickup in UTC', () {
    final request = OrderRequest(
      fulfillmentType: FulfillmentType.scheduled,
      requestedPickupAt: DateTime.parse('2026-08-13T11:30:00+08:00'),
      items: const [OrderSelectionLine(itemId: 'item-id', quantity: 1)],
    );

    expect(request.toJson()['requestedPickupAt'], '2026-08-13T03:30:00.000Z');
  });

  test('maps every persisted status without client progression', () {
    for (final status in OrderStatus.values) {
      expect(OrderStatus.fromJson(status.name), status);
    }
  });
}
