import 'dart:math';

import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/error/result.dart';
import '../domain/model/order.dart';
import '../domain/repository/order_repository.dart';

typedef ClientRequestIdFactory = String Function();

class OrderCheckoutSession {
  OrderCheckoutSession(this._repository, {ClientRequestIdFactory? createId})
    : _createId = createId ?? createUuidV4;

  final OrderRepository _repository;
  final ClientRequestIdFactory _createId;
  String? _pendingClientRequestId;

  String? get pendingClientRequestId => _pendingClientRequestId;

  Future<Result<OrderQuote>> quote(
    OrderRequest request, {
    String? branchId,
  }) => branchId == null
      ? _repository.quoteOrder(request)
      : _repository.quoteOrderAtBranch(branchId, request);

  Future<Result<OrderSnapshot>> place(
    OrderRequest request, {
    String? branchId,
  }) async {
    final requestId = _pendingClientRequestId ??= _createId();
    final requestWithId = request.copyWith(clientRequestId: requestId);
    final result = branchId == null
        ? await _repository.placeCustomerOrder(requestWithId)
        : await _repository.placeCustomerOrderAtBranch(branchId, requestWithId);
    if (result is Ok<OrderSnapshot>) _pendingClientRequestId = null;
    return result;
  }
}

/// Legacy policy-slot derivation retained for old callers and deterministic
/// unit tests. Live customer checkout uses server-returned branch slots instead.
List<DateTime> derivePickupSlots(
  OrderingPolicy policy, {
  int maximumSlots = 48,
}) {
  if (!policy.scheduleEnabled || maximumSlots <= 0) return const [];
  tz_data.initializeTimeZones();
  final location = tz.getLocation(policy.timezone);
  final minimum = tz.TZDateTime.from(
    policy.serverNow.toUtc().add(Duration(minutes: policy.minimumLeadMinutes)),
    location,
  );
  final interval = policy.slotIntervalMinutes;
  final minutesOfDay = minimum.hour * 60 + minimum.minute;
  final roundedMinutes = ((minutesOfDay + interval - 1) ~/ interval) * interval;
  var slot = tz.TZDateTime(
    location,
    minimum.year,
    minimum.month,
    minimum.day,
  ).add(Duration(minutes: roundedMinutes));
  if (slot.isBefore(minimum)) slot = slot.add(Duration(minutes: interval));

  final horizon = policy.serverNow.toUtc().add(
    Duration(days: policy.maximumAdvanceDays),
  );
  final slots = <DateTime>[];
  while (!slot.toUtc().isAfter(horizon) && slots.length < maximumSlots) {
    // TZDateTime overrides toUtc() and retains its runtime subtype. This legacy
    // helper promises ordinary UTC DateTime values, so normalize by epoch.
    slots.add(
      DateTime.fromMillisecondsSinceEpoch(
        slot.millisecondsSinceEpoch,
        isUtc: true,
      ),
    );
    slot = slot.add(Duration(minutes: interval));
  }
  return List.unmodifiable(slots);
}

String createUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String pair(int byte) => byte.toRadixString(16).padLeft(2, '0');
  final hex = bytes.map(pair).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
