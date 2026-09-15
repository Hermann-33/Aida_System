import 'dart:async';

import 'package:aida_customer/core/error/failures.dart';
import 'package:aida_customer/core/error/result.dart';
import 'package:aida_customer/domain/model/branch_pickup.dart';
import 'package:aida_customer/domain/model/order.dart';
import 'package:aida_customer/domain/repository/order_repository.dart';

class TestOrderRepository implements OrderRepository {
  TestOrderRepository({this.placeFailure});

  final Failure? placeFailure;
  final updates = StreamController<void>.broadcast();
  int historyFetches = 0;
  final quotedRequests = <OrderRequest>[];
  final placedRequests = <OrderRequest>[];
  final quotedBranchIds = <String?>[];
  final placedBranchIds = <String?>[];

  static final policy = OrderingPolicy(
    serverNow: DateTime.utc(2026, 8, 13, 2),
    timezone: 'Asia/Kuala_Lumpur',
    scheduleEnabled: true,
    minimumLeadMinutes: 30,
    preparationLeadMinutes: 15,
    slotIntervalMinutes: 15,
    maximumAdvanceDays: 2,
  );

  static const pickupBranch = PickupBranch(
    id: 'branch-main',
    code: 'BR-MAIN',
    name: 'Main Café',
    timezone: 'Asia/Kuala_Lumpur',
    addressText: 'Cyberjaya',
    isDefault: true,
    policy: PickupBranchPolicy(
      asapEnabled: true,
      scheduleEnabled: true,
      minimumLeadMinutes: 30,
      preparationLeadMinutes: 15,
      slotIntervalMinutes: 15,
      maximumAdvanceDays: 2,
      slotCapacityOrders: 4,
    ),
  );

  static final pickupState = BranchPickupState(
    serverNow: DateTime.utc(2026, 8, 13, 2),
    valid: true,
    code: 'AVAILABLE',
    message: 'Pickup is available',
  );

  static final pickupSlots = BranchPickupSlots(
    serverNow: DateTime.utc(2026, 8, 13, 2),
    branchId: pickupBranch.id,
    serviceDate: DateTime(2026, 8, 13),
    timezone: pickupBranch.timezone,
    slotIntervalMinutes: 15,
    slots: [
      PickupSlot(
        pickupAt: DateTime.utc(2026, 8, 13, 2, 30),
        prepareAt: DateTime.utc(2026, 8, 13, 2, 15),
        remainingOrders: 4,
      ),
      PickupSlot(
        pickupAt: DateTime.utc(2026, 8, 13, 2, 45),
        prepareAt: DateTime.utc(2026, 8, 13, 2, 30),
        remainingOrders: 3,
      ),
    ],
  );

  static final quote = OrderQuote.fromJson({
    'pricingVersion': 2,
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
      'preparationLeadMinutes': 15,
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
        'options': [
          {
            'groupId': 'grp_temperature',
            'groupCode': 'temperature',
            'groupName': 'Temperature',
            'optionValueId': 'opt_hot',
            'optionCode': 'hot',
            'optionLabel': 'Hot',
            'priceDeltaSen': 0,
          },
          {
            'groupId': 'grp_sweetness',
            'groupCode': 'sweetness',
            'groupName': 'Sweetness',
            'optionValueId': 'opt_less_sweet',
            'optionCode': 'less-sweet',
            'optionLabel': 'Less sweet',
            'priceDeltaSen': 0,
          },
        ],
        'optionTotalSen': 0,
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
    'pricingVersion': 2,
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
        'options': [
          {
            'groupId': 'grp_temperature',
            'groupCode': 'temperature',
            'groupName': 'Temperature',
            'optionValueId': 'opt_hot',
            'optionCode': 'hot',
            'optionLabel': 'Hot',
            'priceDeltaSen': 0,
          },
          {
            'groupId': 'grp_sweetness',
            'groupCode': 'sweetness',
            'groupName': 'Sweetness',
            'optionValueId': 'opt_less_sweet',
            'optionCode': 'less-sweet',
            'optionLabel': 'Less sweet',
            'priceDeltaSen': 0,
          },
        ],
        'optionTotalSen': 0,
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
  Future<Result<List<PickupBranch>>> listPickupBranches() async =>
      const Ok([pickupBranch]);

  @override
  Future<Result<BranchPickupState>> getBranchPickupState(String branchId) async =>
      Ok(pickupState);

  @override
  Future<Result<BranchPickupSlots>> listBranchPickupSlots(
    String branchId,
    DateTime serviceDate,
  ) async => Ok(
    serviceDate.year == 2026 &&
            serviceDate.month == 8 &&
            serviceDate.day == 13
        ? pickupSlots
        : BranchPickupSlots(
          serverNow: pickupSlots.serverNow,
          branchId: branchId,
          serviceDate: serviceDate,
          timezone: pickupBranch.timezone,
          slotIntervalMinutes: pickupBranch.policy.slotIntervalMinutes,
          slots: const [],
        ),
  );

  @override
  Future<Result<OrderQuote>> quoteOrder(OrderRequest request) async {
    quotedRequests.add(request);
    quotedBranchIds.add(null);
    return Ok(quote);
  }

  @override
  Future<Result<OrderQuote>> quoteOrderAtBranch(
    String branchId,
    OrderRequest request,
  ) async {
    quotedRequests.add(request);
    quotedBranchIds.add(branchId);
    return Ok(quote);
  }

  @override
  Future<Result<OrderSnapshot>> placeCustomerOrder(OrderRequest request) async {
    placedRequests.add(request);
    placedBranchIds.add(null);
    return placeFailure == null ? Ok(order) : Err(placeFailure!);
  }

  @override
  Future<Result<OrderSnapshot>> placeCustomerOrderAtBranch(
    String branchId,
    OrderRequest request,
  ) async {
    placedRequests.add(request);
    placedBranchIds.add(branchId);
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
