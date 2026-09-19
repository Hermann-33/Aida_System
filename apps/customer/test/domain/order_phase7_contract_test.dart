import 'package:aida_customer/domain/model/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderQuote Phase 7 promotion contract', () {
    test('accepts promotion-only discount with trusted snapshots', () {
      final quote = OrderQuote.fromJson(
        _quotePayload(
          voucherDiscountSen: 0,
          promotionDiscountSen: 150,
          discountSen: 150,
          promotions: <Map<String, dynamic>>[_promotion(discountSen: 150)],
        ),
      );

      expect(quote.voucher, isNull);
      expect(quote.voucherDiscount.sen, 0);
      expect(quote.promotionDiscount.sen, 150);
      expect(quote.discount.sen, 150);
      expect(quote.total.sen, 850);
      expect(quote.promotions.single.code, 'P7_TEST');
    });

    test('accepts voucher plus voucher-compatible promotion', () {
      final quote = OrderQuote.fromJson(
        _quotePayload(
          voucherDiscountSen: 100,
          promotionDiscountSen: 200,
          discountSen: 300,
          voucher: _voucher(discountSen: 100),
          promotions: <Map<String, dynamic>>[
            _promotion(discountSen: 200, allowWithVoucher: true),
          ],
        ),
      );

      expect(quote.voucherDiscount.sen, 100);
      expect(quote.promotionDiscount.sen, 200);
      expect(quote.discount.sen, 300);
      expect(quote.total.sen, 700);
    });

    test('rejects aggregate discount that does not reconcile components', () {
      final payload = _quotePayload(
        voucherDiscountSen: 0,
        promotionDiscountSen: 150,
        discountSen: 100,
        promotions: <Map<String, dynamic>>[_promotion(discountSen: 150)],
      );

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects promotion discount without trusted promotion snapshots', () {
      final payload = _quotePayload(
        voucherDiscountSen: 0,
        promotionDiscountSen: 150,
        discountSen: 150,
      );

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects snapshot sum that differs from promotionDiscountSen', () {
      final payload = _quotePayload(
        voucherDiscountSen: 0,
        promotionDiscountSen: 150,
        discountSen: 150,
        promotions: <Map<String, dynamic>>[_promotion(discountSen: 100)],
      );

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects voucher-incompatible promotion beside a voucher', () {
      final payload = _quotePayload(
        voucherDiscountSen: 100,
        promotionDiscountSen: 200,
        discountSen: 300,
        voucher: _voucher(discountSen: 100),
        promotions: <Map<String, dynamic>>[
          _promotion(discountSen: 200, allowWithVoucher: false),
        ],
      );

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects exclusive promotion combined with another promotion', () {
      final payload = _quotePayload(
        voucherDiscountSen: 0,
        promotionDiscountSen: 200,
        discountSen: 200,
        promotions: <Map<String, dynamic>>[
          _promotion(discountSen: 100, stackingMode: 'exclusive'),
          _promotion(
            code: 'P7_SECOND',
            discountSen: 100,
            stackingMode: 'stackable',
          ),
        ],
      );

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed promotion commercial fields', () {
      final malformed = _promotion(discountSen: 100)..['discountType'] = 'magic';
      final payload = _quotePayload(
        voucherDiscountSen: 0,
        promotionDiscountSen: 100,
        discountSen: 100,
        promotions: <Map<String, dynamic>>[malformed],
      );

      expect(
        () => OrderQuote.fromJson(payload),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OrderSnapshot Phase 7 immutable promotion contract', () {
    test('accepts applied promotion facts with appliedAt', () {
      final snapshot = OrderSnapshot.fromJson(
        _snapshotPayload(
          voucherDiscountSen: 0,
          promotionDiscountSen: 125,
          discountSen: 125,
          promotions: <Map<String, dynamic>>[
            _promotion(
              discountSen: 125,
              appliedAt: '2026-09-15T09:00:00Z',
            ),
          ],
        ),
      );

      expect(snapshot.promotionDiscount.sen, 125);
      expect(snapshot.promotions.single.appliedAt, DateTime.utc(2026, 9, 15, 9));
    });
  });
}

Map<String, dynamic> _quotePayload({
  required int voucherDiscountSen,
  required int promotionDiscountSen,
  required int discountSen,
  Map<String, dynamic>? voucher,
  List<Map<String, dynamic>> promotions = const [],
}) => <String, dynamic>{
  'pricingVersion': 2,
  'currency': 'MYR',
  'subtotalSen': 1000,
  'voucherDiscountSen': voucherDiscountSen,
  'promotionDiscountSen': promotionDiscountSen,
  'discountSen': discountSen,
  'totalSen': 1000 - discountSen,
  if (voucher != null) 'voucher': voucher,
  'promotions': promotions,
  'fulfillmentType': 'asap',
  'requestedPickupAt': null,
  'serverNow': '2026-09-15T09:00:00Z',
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
  required int voucherDiscountSen,
  required int promotionDiscountSen,
  required int discountSen,
  Map<String, dynamic>? voucher,
  List<Map<String, dynamic>> promotions = const [],
}) => <String, dynamic>{
  'id': '00000000-0000-4000-8000-000000000101',
  'orderNumber': 100101,
  'fulfillmentType': 'asap',
  'requestedPickupAt': null,
  'status': 'confirmed',
  'statusVersion': 1,
  'currency': 'MYR',
  'pricingVersion': 2,
  'subtotalSen': 1000,
  'voucherDiscountSen': voucherDiscountSen,
  'promotionDiscountSen': promotionDiscountSen,
  'discountSen': discountSen,
  'totalSen': 1000 - discountSen,
  'refundedSen': 0,
  'payment': <String, dynamic>{
    'tenderType': 'unpaid',
    'paymentState': 'unpaid',
    'paidAt': null,
    'refundedSen': 0,
    'refundableSen': 1000 - discountSen,
    'providerAvailable': false,
    'latestIntent': null,
    'refunds': <Map<String, dynamic>>[],
  },
  if (voucher != null) 'voucher': voucher,
  'promotions': promotions,
  'createdAt': '2026-09-15T09:00:00Z',
  'updatedAt': '2026-09-15T09:00:00Z',
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      ..._linePayload(),
      'id': '00000000-0000-4000-8000-000000000102',
    },
  ],
};

Map<String, dynamic> _linePayload() => <String, dynamic>{
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
};

Map<String, dynamic> _voucher({required int discountSen}) => <String, dynamic>{
  'id': 'voucher-1',
  'code': 'AIDA-RM1',
  'rewardCode': 'RM1',
  'rewardName': 'RM 1 off',
  'rewardType': 'fixed_amount',
  'discountSen': discountSen,
  'freeItemLineNumber': null,
  'expiresAt': '2026-10-15T09:00:00Z',
};

Map<String, dynamic> _promotion({
  String code = 'P7_TEST',
  required int discountSen,
  String stackingMode = 'stackable',
  bool allowWithVoucher = true,
  String? appliedAt,
}) => <String, dynamic>{
  'code': code,
  'name': 'Phase 7 Test Promotion',
  'discountType': 'fixed',
  'discountValue': discountSen,
  'discountSen': discountSen,
  'priority': 10,
  'stackingMode': stackingMode,
  'allowWithVoucher': allowWithVoucher,
  if (appliedAt != null) 'appliedAt': appliedAt,
};
