import 'dart:async';

import 'package:aida_customer/core/error/failures.dart';
import 'package:aida_customer/core/error/result.dart';
import 'package:aida_customer/domain/model/order.dart';
import 'package:aida_customer/domain/repository/order_repository.dart';

class TestOrderRepository implements OrderRepository {
  TestOrderRepository({this.placeFailure});

  final Failure? placeFailure;
  final updates = StreamController<void>.broadcast();
  int historyFetches = 0;
  final quotedRequests = <OrderRequest>[];
  final placedRequests = <OrderRequest>[];

  static final policy = OrderingPolicy(
    serverNow: DateTime.utc(2026, 8, 13, 2),
    timezone: 'Asia/Kuala_Lumpur',
    scheduleEnabled: true,
    minimumLeadMinutes: 30,
    slotIntervalMinutes: 15,
    maximumAdvanceDays: 2,
  );

  static final quote = OrderQuote.fromJson({
    'pricingVersion': 1,
    'currency': 'MYR',
    'subtotalSen': 3480,
    'totalSen': 3480,
    'fulfillmentType': 'asap',
    'requestedPickupAt': null,
    'serverNow': '2026-08-13T02:00:00Z',
    'schedulePolicy': {
      'timezone': 'Asia/Kuala_Lumpur',
      'scheduleEnabled': true,
      'minimumLeadMinutes': 30,
      'slotIntervalMinutes': 15,
      'maximumAdvanceDays': 2,
    },
    'lines': [
      {
        'lineNumber': 1,
        'itemId': 'p_scl',
        'sku': 'CF-SCL',
        'name': 'Salted Caramel Latte',
        'basePriceSen': 1290,
        'variant': {
          'id': 'v_large',
          'code': 'large',
          'label': 'Large',
          'priceDeltaSen': 150,
        },
        'addOns': [
          {
            'itemId': 'p_shot',
            'sku': 'AD-SHT',
            'name': 'Extra Shot',
            'priceSen': 300,
          },
        ],
        'addOnTotalSen': 300,
        'unitPriceSen': 1740,
        'quantity': 2,
        'lineTotalSen': 3480,
        'note': 'less ice please',
      },
    ],
  });

  static final order = OrderSnapshot.fromJson({
    'id': '00000000-0000-4000-8000-000000000001',
    'orderNumber': 'AIDA-100001',
    'fulfillmentType': 'asap',
    'requestedPickupAt': null,
    'status': 'confirmed',
    'statusVersion': 1,
    'currency': 'MYR',
    'pricingVersion': 1,
    'subtotalSen': 3480,
    'totalSen': 3480,
    'createdAt': '2026-08-13T02:01:00Z',
    'updatedAt': '2026-08-13T02:01:00Z',
    'lines': [
      {
        'id': '00000000-0000-4000-8000-000000000002',
        'lineNumber': 1,
        'itemId': 'p_scl',
        'sku': 'CF-SCL',
        'name': 'Salted Caramel Latte',
        'basePriceSen': 1290,
        'variant': {
          'id': 'v_large',
          'code': 'large',
          'label': 'Large',
          'priceDeltaSen': 150,
        },
        'addOns': [
          {
            'itemId': 'p_shot',
            'sku': 'AD-SHT',
            'name': 'Extra Shot',
            'priceSen': 300,
          },
        ],
        'addOnTotalSen': 300,
        'unitPriceSen': 1740,
        'quantity': 2,
        'lineTotalSen': 3480,
        'note': 'less ice please',
      },
    ],
  });

  @override
  Future<Result<OrderingPolicy>> getOrderingPolicy() async => Ok(policy);

  @override
  Future<Result<OrderQuote>> quoteOrder(OrderRequest request) async {
    quotedRequests.add(request);
    return Ok(quote);
  }

  @override
  Future<Result<OrderSnapshot>> placeCustomerOrder(OrderRequest request) async {
    placedRequests.add(request);
    return placeFailure == null ? Ok(order) : Err(placeFailure!);
  }

  @override
  Future<Result<List<OrderSnapshot>>> getMyOrders({int limit = 20}) async {
    historyFetches++;
    return Ok([order]);
  }

  @override
  Future<Result<OrderSnapshot>> getOrder(String orderId) async => Ok(order);

  @override
  Stream<void> watchMyOrders() => updates.stream;
}
