import 'package:aida_customer/domain/model/order.dart';
import 'package:aida_customer/domain/model/order_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OrderSnapshot binds persisted commercial and payment authority', () {
    final snapshot = OrderSnapshot.fromJson(_payload());
    expect(snapshot.total.sen, 1000);
    expect(snapshot.refunded.sen, 400);
    expect(snapshot.payment.paymentState, OrderPaymentState.partiallyRefunded);
    expect(snapshot.payment.refundable.sen, 600);
    expect(snapshot.payment.latestIntent?.state, PaymentIntentState.captured);
  });

  test('OrderSnapshot rejects top-level refunded amount that disagrees with payment projection', () {
    final payload = _payload()..['refundedSen'] = 300;
    expect(() => OrderSnapshot.fromJson(payload), throwsA(isA<FormatException>()));
  });

  test('OrderSnapshot rejects missing payment projection', () {
    final payload = _payload()..remove('payment');
    expect(() => OrderSnapshot.fromJson(payload), throwsA(isA<FormatException>()));
  });
}

Map<String, dynamic> _payload() => <String, dynamic>{
  'id': '99500000-0000-0000-0000-000000000001',
  'orderNumber': 100501,
  'fulfillmentType': 'asap',
  'requestedPickupAt': null,
  'status': 'completed',
  'statusVersion': 4,
  'currency': 'MYR',
  'pricingVersion': 2,
  'subtotalSen': 1000,
  'voucherDiscountSen': 0,
  'promotionDiscountSen': 0,
  'discountSen': 0,
  'totalSen': 1000,
  'refundedSen': 400,
  'payment': <String, dynamic>{
    'tenderType': 'external',
    'paymentState': 'partially_refunded',
    'paidAt': '2026-09-18T01:00:00Z',
    'refundedSen': 400,
    'refundableSen': 600,
    'providerAvailable': true,
    'latestIntent': <String, dynamic>{
      'id': 'intent-1',
      'providerKey': 'phase9_test',
      'state': 'captured',
      'settlementState': 'pending',
      'amountSen': 1000,
      'currency': 'MYR',
      'createdAt': '2026-09-18T00:59:00Z',
      'authorizedAt': null,
      'capturedAt': '2026-09-18T01:00:00Z',
      'settledAt': null,
    },
    'refunds': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'refund-1',
        'tenderType': 'external',
        'state': 'succeeded',
        'amountSen': 400,
        'reason': 'Test refund',
        'createdAt': '2026-09-18T02:00:00Z',
        'succeededAt': '2026-09-18T02:01:00Z',
      },
    ],
  },
  'voucher': null,
  'promotions': <Map<String, dynamic>>[],
  'createdAt': '2026-09-18T00:55:00Z',
  'updatedAt': '2026-09-18T02:01:00Z',
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': '99500000-0000-0000-0000-000000000002',
      'lineNumber': 1,
      'itemId': 'item-1',
      'sku': 'FD-SAN',
      'name': 'Sandwich',
      'basePriceSen': 1000,
      'variant': null,
      'addOns': <Map<String, dynamic>>[],
      'addOnTotalSen': 0,
      'options': <Map<String, dynamic>>[],
      'optionTotalSen': 0,
      'unitPriceSen': 1000,
      'quantity': 1,
      'lineTotalSen': 1000,
      'note': null,
    },
  ],
};
