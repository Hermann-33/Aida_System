import 'package:aida_customer/domain/model/order_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderPaymentSnapshot Phase 9 contract', () {
    test('accepts unpaid order without provider intent', () {
      final snapshot = OrderPaymentSnapshot.fromJson(
        _payload(),
        orderTotalSen: 1000,
        orderCurrency: 'MYR',
      );

      expect(snapshot.tenderType, PaymentTenderType.unpaid);
      expect(snapshot.paymentState, OrderPaymentState.unpaid);
      expect(snapshot.refunded.sen, 0);
      expect(snapshot.refundable.sen, 1000);
      expect(snapshot.latestIntent, isNull);
    });

    test('accepts pending external payment with authorized intent', () {
      final snapshot = OrderPaymentSnapshot.fromJson(
        _payload(
          tenderType: 'external',
          paymentState: 'pending',
          latestIntent: _intent(state: 'authorized'),
        ),
        orderTotalSen: 1000,
        orderCurrency: 'MYR',
      );

      expect(snapshot.paymentState, OrderPaymentState.pending);
      expect(snapshot.latestIntent!.state, PaymentIntentState.authorized);
    });

    test('accepts partial external refund only from succeeded refunds', () {
      final snapshot = OrderPaymentSnapshot.fromJson(
        _payload(
          tenderType: 'external',
          paymentState: 'partially_refunded',
          paidAt: '2026-09-17T08:00:00Z',
          refundedSen: 400,
          refundableSen: 600,
          latestIntent: _intent(
            state: 'captured',
            capturedAt: '2026-09-17T08:00:00Z',
          ),
          refunds: <Map<String, dynamic>>[
            _refund(
              id: 'refund-1',
              state: 'succeeded',
              amountSen: 400,
              succeededAt: '2026-09-17T08:05:00Z',
            ),
            _refund(
              id: 'refund-2',
              state: 'requested',
              amountSen: 500,
            ),
          ],
        ),
        orderTotalSen: 1000,
        orderCurrency: 'MYR',
      );

      expect(snapshot.refunded.sen, 400);
      expect(snapshot.refundable.sen, 600);
      expect(snapshot.refunds.length, 2);
    });

    test('rejects succeeded refund snapshots that do not reconcile', () {
      final payload = _payload(
        tenderType: 'cash',
        paymentState: 'partially_refunded',
        paidAt: '2026-09-17T08:00:00Z',
        refundedSen: 400,
        refundableSen: 600,
        refunds: <Map<String, dynamic>>[
          _refund(
            state: 'succeeded',
            amountSen: 300,
            succeededAt: '2026-09-17T08:05:00Z',
          ),
        ],
      );

      expect(
        () => OrderPaymentSnapshot.fromJson(
          payload,
          orderTotalSen: 1000,
          orderCurrency: 'MYR',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects refund reservations above accepted order total', () {
      final payload = _payload(
        tenderType: 'external',
        paymentState: 'paid',
        paidAt: '2026-09-17T08:00:00Z',
        latestIntent: _intent(
          state: 'captured',
          capturedAt: '2026-09-17T08:00:00Z',
        ),
        refunds: <Map<String, dynamic>>[
          _refund(amountSen: 600),
          _refund(id: 'refund-2', amountSen: 600),
        ],
      );

      expect(
        () => OrderPaymentSnapshot.fromJson(
          payload,
          orderTotalSen: 1000,
          orderCurrency: 'MYR',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects external paid state without captured intent', () {
      final payload = _payload(
        tenderType: 'external',
        paymentState: 'paid',
        paidAt: '2026-09-17T08:00:00Z',
        latestIntent: _intent(state: 'authorized'),
      );

      expect(
        () => OrderPaymentSnapshot.fromJson(
          payload,
          orderTotalSen: 1000,
          orderCurrency: 'MYR',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects intent amount or currency that differs from order', () {
      final payload = _payload(
        tenderType: 'external',
        paymentState: 'pending',
        latestIntent: _intent(amountSen: 900),
      );

      expect(
        () => OrderPaymentSnapshot.fromJson(
          payload,
          orderTotalSen: 1000,
          orderCurrency: 'MYR',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _payload({
  String tenderType = 'unpaid',
  String paymentState = 'unpaid',
  String? paidAt,
  int refundedSen = 0,
  int refundableSen = 1000,
  bool providerAvailable = false,
  Map<String, dynamic>? latestIntent,
  List<Map<String, dynamic>> refunds = const [],
}) => <String, dynamic>{
  'tenderType': tenderType,
  'paymentState': paymentState,
  'paidAt': paidAt,
  'refundedSen': refundedSen,
  'refundableSen': refundableSen,
  'providerAvailable': providerAvailable,
  'latestIntent': latestIntent,
  'refunds': refunds,
};

Map<String, dynamic> _intent({
  String state = 'created',
  String settlementState = 'not_reported',
  int amountSen = 1000,
  String currency = 'MYR',
  String? capturedAt,
}) => <String, dynamic>{
  'id': 'intent-1',
  'providerKey': 'phase9_test',
  'state': state,
  'settlementState': settlementState,
  'amountSen': amountSen,
  'currency': currency,
  'createdAt': '2026-09-17T07:55:00Z',
  'authorizedAt': state == 'authorized' ? '2026-09-17T07:59:00Z' : null,
  'capturedAt': capturedAt,
  'settledAt': settlementState == 'settled' ? '2026-09-17T08:10:00Z' : null,
};

Map<String, dynamic> _refund({
  String id = 'refund-1',
  String tenderType = 'external',
  String state = 'requested',
  int amountSen = 100,
  String? succeededAt,
}) => <String, dynamic>{
  'id': id,
  'tenderType': tenderType,
  'state': state,
  'amountSen': amountSen,
  'reason': 'Test refund',
  'createdAt': '2026-09-17T08:04:00Z',
  'succeededAt': succeededAt,
};
