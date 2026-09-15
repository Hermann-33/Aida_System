import 'package:aida_customer/domain/model/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderQuote Phase 6 commercial contract', () {
    test('accepts an undiscounted authoritative quote', () {
      final quote = OrderQuote.fromJson(_quotePayload());

      expect(quote.subtotal.sen, 1000);
      expect(quote.discount.sen, 0);
      expect(quote.total.sen, 1000);
      expect(quote.voucher, isNull);
    });

    test('accepts a discounted quote with matching voucher snapshot', () {
      final quote = OrderQuote.fromJson(
        _quotePayload(
          discountSen: 100,
          voucher: _voucherPayload(discountSen: 100),
        ),
      );

      expect(quote.discount.sen, 100);
      expect(quote.total.sen, 900);
      expect(quote.voucher?.code, 'AIDA-RM1');
      expect(quote.voucher?.discount.sen, 100);
    });

    test('rejects a quote missing discountSen', () {
      final payload = _quotePayload()..remove('discountSen');

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects total that is not subtotal minus discount', () {
      final payload = _quotePayload(
        discountSen: 100,
        voucher: _voucherPayload(discountSen: 100),
      )..['totalSen'] = 950;

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects line totals that do not equal authoritative subtotal', () {
      final payload = _quotePayload();
      final line = (payload['lines'] as List).single as Map<String, dynamic>;
      line['unitPriceSen'] = 900;
      line['lineTotalSen'] = 900;

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a positive discount without trusted voucher snapshot', () {
      final payload = _quotePayload(discountSen: 100)..['voucher'] = null;

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a voucher snapshot on a zero-discount quote', () {
      final payload = _quotePayload(
        voucher: _voucherPayload(discountSen: 100),
      );

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects voucher discount that differs from authoritative discount', () {
      final payload = _quotePayload(
        discountSen: 100,
        voucher: _voucherPayload(discountSen: 50),
      );

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed required policy booleans', () {
      final payload = _quotePayload();
      final policy = payload['schedulePolicy'] as Map<String, dynamic>;
      policy['scheduleEnabled'] = 'true';

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OrderSnapshot Phase 6 commercial contract', () {
    test('accepts immutable applied voucher facts', () {
      final snapshot = OrderSnapshot.fromJson(
        _snapshotPayload(
          discountSen: 100,
          voucher: _appliedVoucherPayload(discountSen: 100),
        ),
      );

      expect(snapshot.discount.sen, 100);
      expect(snapshot.total.sen, 900);
      expect(snapshot.voucher?.appliedAt, DateTime.utc(2026, 9, 15, 8));
    });

    test('rejects unknown order status instead of defaulting to confirmed', () {
      final payload = _snapshotPayload()..['status'] = 'mystery';

      expect(
        () => OrderSnapshot.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects discounted snapshot without voucher application facts', () {
      final payload = _snapshotPayload(discountSen: 100)..['voucher'] = null;

      expect(
        () => OrderSnapshot.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _quotePayload({
  int discountSen = 0,
  Map<String, dynamic>? voucher,
}) => <String, dynamic>{
  'pricingVersion': 2,
  'currency': 'MYR',
  'subtotalSen': 1000,
  'discountSen': discountSen,
  'totalSen': 1000 - discountSen,
  'voucher': voucher,
  'fulfillmentType': 'asap',
  'requestedPickupAt': null,
  'serverNow': '2026-09-15T08:00:00Z',
  'schedulePolicy': <String, dynamic>{
    'timezone': 'Asia/Kuala_Lumpur',
    'scheduleEnabled': true,
    'minimumLeadMinutes': 15,
    'preparationLeadMinutes': 10,
    'slotIntervalMinutes': 15,
    'maximumAdvanceDays': 2,
  },
  'lines': <Map<String, dynamic>>[_linePayload()],
};

Map<String, dynamic> _snapshotPayload({
  int discountSen = 0,
  Map<String, dynamic>? voucher,
}) => <String, dynamic>{
  'id': '00000000-0000-4000-8000-000000000001',
  'orderNumber': 100001,
  'fulfillmentType': 'asap',
  'requestedPickupAt': null,
  'status': 'confirmed',
  'statusVersion': 1,
  'currency': 'MYR',
  'pricingVersion': 2,
  'subtotalSen': 1000,
  'discountSen': discountSen,
  'totalSen': 1000 - discountSen,
  'voucher': voucher,
  'createdAt': '2026-09-15T08:00:00Z',
  'updatedAt': '2026-09-15T08:00:00Z',
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      ..._linePayload(),
      'id': '00000000-0000-4000-8000-000000000002',
    },
  ],
};

Map<String, dynamic> _linePayload() => <String, dynamic>{
  'lineNumber': 1,
  'itemId': 'item-1',
  'sku': 'CF-LAT',
  'name': 'Latte',
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
};

Map<String, dynamic> _voucherPayload({required int discountSen}) =>
    <String, dynamic>{
      'id': 'voucher-1',
      'code': 'AIDA-RM1',
      'rewardCode': 'RM1',
      'rewardName': 'RM 1 off',
      'rewardType': 'fixed_amount',
      'discountSen': discountSen,
      'freeItemLineNumber': null,
      'expiresAt': '2026-10-15T08:00:00Z',
    };

Map<String, dynamic> _appliedVoucherPayload({required int discountSen}) =>
    <String, dynamic>{
      'code': 'AIDA-RM1',
      'rewardCode': 'RM1',
      'rewardName': 'RM 1 off',
      'rewardType': 'fixed_amount',
      'discountSen': discountSen,
      'appliedAt': '2026-09-15T08:00:00Z',
    };
