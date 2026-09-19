import 'money.dart';

enum PaymentTenderType {
  unpaid,
  cash,
  external;

  static PaymentTenderType fromJson(Object? value) => switch (value) {
    'unpaid' => unpaid,
    'cash' => cash,
    'external' => external,
    _ => throw FormatException('Unknown payment tender type: $value'),
  };
}

enum OrderPaymentState {
  unpaid,
  pending,
  paid,
  partiallyRefunded,
  refunded;

  static OrderPaymentState fromJson(Object? value) => switch (value) {
    'unpaid' => unpaid,
    'pending' => pending,
    'paid' => paid,
    'partially_refunded' => partiallyRefunded,
    'refunded' => refunded,
    _ => throw FormatException('Unknown order payment state: $value'),
  };
}

enum PaymentIntentState {
  created,
  requiresAction,
  authorized,
  captured,
  failed,
  cancelled;

  static PaymentIntentState fromJson(Object? value) => switch (value) {
    'created' => created,
    'requires_action' => requiresAction,
    'authorized' => authorized,
    'captured' => captured,
    'failed' => failed,
    'cancelled' => cancelled,
    _ => throw FormatException('Unknown payment intent state: $value'),
  };
}

enum PaymentSettlementState {
  notReported,
  pending,
  settled,
  failed;

  static PaymentSettlementState fromJson(Object? value) => switch (value) {
    'not_reported' => notReported,
    'pending' => pending,
    'settled' => settled,
    'failed' => failed,
    _ => throw FormatException('Unknown payment settlement state: $value'),
  };
}

enum RefundTenderType {
  cash,
  external;

  static RefundTenderType fromJson(Object? value) => switch (value) {
    'cash' => cash,
    'external' => external,
    _ => throw FormatException('Unknown refund tender type: $value'),
  };
}

enum RefundState {
  requested,
  processing,
  succeeded,
  failed,
  cancelled;

  static RefundState fromJson(Object? value) => switch (value) {
    'requested' => requested,
    'processing' => processing,
    'succeeded' => succeeded,
    'failed' => failed,
    'cancelled' => cancelled,
    _ => throw FormatException('Unknown refund state: $value'),
  };
}

class PaymentIntentSnapshot {
  const PaymentIntentSnapshot({
    required this.id,
    required this.providerKey,
    required this.state,
    required this.settlementState,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.authorizedAt,
    this.capturedAt,
    this.settledAt,
  });

  factory PaymentIntentSnapshot.fromJson(Map<String, dynamic> json) {
    final amountSen = _requiredInt(json, 'amountSen');
    if (amountSen <= 0) {
      throw const FormatException('Payment intent amount must be positive');
    }
    return PaymentIntentSnapshot(
      id: _requiredString(json, 'id'),
      providerKey: _requiredString(json, 'providerKey'),
      state: PaymentIntentState.fromJson(json['state']),
      settlementState: PaymentSettlementState.fromJson(
        json['settlementState'],
      ),
      amount: Money.fromSen(amountSen),
      currency: _requiredString(json, 'currency'),
      createdAt: _requiredDate(json, 'createdAt'),
      authorizedAt: _optionalDate(json['authorizedAt']),
      capturedAt: _optionalDate(json['capturedAt']),
      settledAt: _optionalDate(json['settledAt']),
    );
  }

  final String id;
  final String providerKey;
  final PaymentIntentState state;
  final PaymentSettlementState settlementState;
  final Money amount;
  final String currency;
  final DateTime createdAt;
  final DateTime? authorizedAt;
  final DateTime? capturedAt;
  final DateTime? settledAt;
}

class RefundSnapshot {
  const RefundSnapshot({
    required this.id,
    required this.tenderType,
    required this.state,
    required this.amount,
    this.reason,
    required this.createdAt,
    this.succeededAt,
  });

  factory RefundSnapshot.fromJson(Map<String, dynamic> json) {
    final amountSen = _requiredInt(json, 'amountSen');
    if (amountSen <= 0) {
      throw const FormatException('Refund amount must be positive');
    }
    final reason = json['reason'];
    if (reason != null && reason is! String) {
      throw const FormatException('Refund reason must be a string or null');
    }
    final state = RefundState.fromJson(json['state']);
    final succeededAt = _optionalDate(json['succeededAt']);
    if (state == RefundState.succeeded && succeededAt == null) {
      throw const FormatException('Succeeded refund requires succeededAt');
    }
    return RefundSnapshot(
      id: _requiredString(json, 'id'),
      tenderType: RefundTenderType.fromJson(json['tenderType']),
      state: state,
      amount: Money.fromSen(amountSen),
      reason: reason as String?,
      createdAt: _requiredDate(json, 'createdAt'),
      succeededAt: succeededAt,
    );
  }

  final String id;
  final RefundTenderType tenderType;
  final RefundState state;
  final Money amount;
  final String? reason;
  final DateTime createdAt;
  final DateTime? succeededAt;
}

class OrderPaymentSnapshot {
  const OrderPaymentSnapshot({
    required this.tenderType,
    required this.paymentState,
    this.paidAt,
    required this.refunded,
    required this.refundable,
    required this.providerAvailable,
    this.latestIntent,
    this.refunds = const [],
  });

  factory OrderPaymentSnapshot.fromJson(
    Map<String, dynamic> json, {
    required int orderTotalSen,
    required String orderCurrency,
  }) {
    if (orderTotalSen < 0) {
      throw const FormatException('Order total cannot be negative');
    }
    final refundedSen = _requiredInt(json, 'refundedSen');
    final refundableSen = _requiredInt(json, 'refundableSen');
    if (refundedSen < 0 || refundableSen < 0) {
      throw const FormatException('Refund balances cannot be negative');
    }
    if (refundedSen + refundableSen != orderTotalSen) {
      throw const FormatException(
        'Refunded plus refundable balance must equal order total',
      );
    }

    final tenderType = PaymentTenderType.fromJson(json['tenderType']);
    final paymentState = OrderPaymentState.fromJson(json['paymentState']);
    final paidAt = _optionalDate(json['paidAt']);
    final providerAvailable = _requiredBool(json, 'providerAvailable');

    final latestIntentRaw = json['latestIntent'];
    if (latestIntentRaw != null && latestIntentRaw is! Map) {
      throw const FormatException('latestIntent must be an object or null');
    }
    final latestIntent = latestIntentRaw == null
        ? null
        : PaymentIntentSnapshot.fromJson(
            Map<String, dynamic>.from(latestIntentRaw),
          );
    if (latestIntent != null &&
        (latestIntent.amount.sen != orderTotalSen ||
            latestIntent.currency != orderCurrency)) {
      throw const FormatException(
        'Payment intent must match the accepted order amount and currency',
      );
    }

    final refundsRaw = json['refunds'];
    if (refundsRaw is! List) {
      throw const FormatException('refunds must be an array');
    }
    final refunds = refundsRaw
        .map(
          (value) => RefundSnapshot.fromJson(
            _requiredMap(value, 'refund snapshot'),
          ),
        )
        .toList(growable: false);

    final succeededRefundSen = refunds
        .where((refund) => refund.state == RefundState.succeeded)
        .fold<int>(0, (sum, refund) => sum + refund.amount.sen);
    if (succeededRefundSen != refundedSen) {
      throw const FormatException(
        'Succeeded refund snapshots must equal refundedSen',
      );
    }
    final reservedRefundSen = refunds
        .where(
          (refund) => refund.state == RefundState.requested ||
              refund.state == RefundState.processing ||
              refund.state == RefundState.succeeded,
        )
        .fold<int>(0, (sum, refund) => sum + refund.amount.sen);
    if (reservedRefundSen > orderTotalSen) {
      throw const FormatException('Refund reservations exceed order total');
    }

    _validatePaymentShape(
      tenderType: tenderType,
      paymentState: paymentState,
      paidAt: paidAt,
      refundedSen: refundedSen,
      orderTotalSen: orderTotalSen,
      latestIntent: latestIntent,
    );

    return OrderPaymentSnapshot(
      tenderType: tenderType,
      paymentState: paymentState,
      paidAt: paidAt,
      refunded: Money.fromSen(refundedSen),
      refundable: Money.fromSen(refundableSen),
      providerAvailable: providerAvailable,
      latestIntent: latestIntent,
      refunds: refunds,
    );
  }

  final PaymentTenderType tenderType;
  final OrderPaymentState paymentState;
  final DateTime? paidAt;
  final Money refunded;
  final Money refundable;
  final bool providerAvailable;
  final PaymentIntentSnapshot? latestIntent;
  final List<RefundSnapshot> refunds;
}

void _validatePaymentShape({
  required PaymentTenderType tenderType,
  required OrderPaymentState paymentState,
  required DateTime? paidAt,
  required int refundedSen,
  required int orderTotalSen,
  required PaymentIntentSnapshot? latestIntent,
}) {
  switch (paymentState) {
    case OrderPaymentState.unpaid:
      if (tenderType != PaymentTenderType.unpaid ||
          paidAt != null ||
          refundedSen != 0) {
        throw const FormatException('Invalid unpaid payment projection');
      }
    case OrderPaymentState.pending:
      if (tenderType != PaymentTenderType.external ||
          paidAt != null ||
          refundedSen != 0 ||
          latestIntent == null ||
          !<PaymentIntentState>{
            PaymentIntentState.created,
            PaymentIntentState.requiresAction,
            PaymentIntentState.authorized,
          }.contains(latestIntent.state)) {
        throw const FormatException('Invalid pending payment projection');
      }
    case OrderPaymentState.paid:
      if (tenderType == PaymentTenderType.unpaid ||
          paidAt == null ||
          refundedSen != 0) {
        throw const FormatException('Invalid paid payment projection');
      }
    case OrderPaymentState.partiallyRefunded:
      if (tenderType == PaymentTenderType.unpaid ||
          paidAt == null ||
          refundedSen <= 0 ||
          refundedSen >= orderTotalSen) {
        throw const FormatException(
          'Invalid partially-refunded payment projection',
        );
      }
    case OrderPaymentState.refunded:
      if (tenderType == PaymentTenderType.unpaid ||
          paidAt == null ||
          refundedSen != orderTotalSen) {
        throw const FormatException('Invalid fully-refunded payment projection');
      }
  }

  if (tenderType == PaymentTenderType.cash && latestIntent != null) {
    throw const FormatException('Cash payment cannot carry provider intent');
  }
  if (tenderType == PaymentTenderType.external &&
      paymentState != OrderPaymentState.pending &&
      (latestIntent == null || latestIntent.state != PaymentIntentState.captured)) {
    throw const FormatException(
      'Captured external payment requires captured provider intent',
    );
  }
}

Map<String, dynamic> _requiredMap(Object? value, String label) {
  if (value is! Map) {
    throw FormatException('$label must be an object');
  }
  return Map<String, dynamic>.from(value);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key must be an integer');
  }
  return value;
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('$key must be a boolean');
  }
  return value;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final parsed = _optionalDate(json[key]);
  if (parsed == null) {
    throw FormatException('$key must be an ISO timestamp');
  }
  return parsed;
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Timestamp must be a string or null');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Invalid ISO timestamp: $value');
  }
  return parsed.toUtc();
}
