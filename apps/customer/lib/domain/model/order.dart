import 'money.dart';

enum FulfillmentType { asap, scheduled }

enum OrderStatus {
  confirmed,
  scheduled,
  preparing,
  ready,
  completed,
  cancelled;

  static OrderStatus fromJson(Object? value) {
    if (value is! String) {
      throw const FormatException('Order status must be a string');
    }
    for (final status in values) {
      if (status.name == value) return status;
    }
    throw FormatException('Unknown order status: $value');
  }
}

class OrderingPolicy {
  const OrderingPolicy({
    required this.serverNow,
    required this.timezone,
    required this.scheduleEnabled,
    required this.minimumLeadMinutes,
    this.preparationLeadMinutes = 0,
    required this.slotIntervalMinutes,
    required this.maximumAdvanceDays,
  });

  factory OrderingPolicy.fromJson(Map<String, dynamic> json) {
    final minimumLeadMinutes = _requiredInt(json, 'minimumLeadMinutes');
    final preparationLeadMinutes = _requiredInt(
      json,
      'preparationLeadMinutes',
    );
    final slotIntervalMinutes = _requiredInt(json, 'slotIntervalMinutes');
    final maximumAdvanceDays = _requiredInt(json, 'maximumAdvanceDays');
    if (minimumLeadMinutes < 0 ||
        preparationLeadMinutes < 0 ||
        slotIntervalMinutes <= 0 ||
        maximumAdvanceDays < 0) {
      throw const FormatException('Invalid ordering policy values');
    }
    return OrderingPolicy(
      serverNow: _requiredDate(json, 'serverNow'),
      timezone: _requiredString(json, 'timezone'),
      scheduleEnabled: _requiredBool(json, 'scheduleEnabled'),
      minimumLeadMinutes: minimumLeadMinutes,
      preparationLeadMinutes: preparationLeadMinutes,
      slotIntervalMinutes: slotIntervalMinutes,
      maximumAdvanceDays: maximumAdvanceDays,
    );
  }

  final DateTime serverNow;
  final String timezone;
  final bool scheduleEnabled;
  final int minimumLeadMinutes;
  final int preparationLeadMinutes;
  final int slotIntervalMinutes;
  final int maximumAdvanceDays;
}

class OrderSelectionLine {
  const OrderSelectionLine({
    required this.itemId,
    this.variantId,
    this.addOnIds = const [],
    this.optionValueIds = const [],
    required this.quantity,
    this.note,
  });

  final String itemId;
  final String? variantId;
  final List<String> addOnIds;
  final List<String> optionValueIds;
  final int quantity;
  final String? note;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'itemId': itemId,
    if (variantId != null) 'variantId': variantId,
    'addOnIds': addOnIds,
    'optionValueIds': optionValueIds,
    'quantity': quantity,
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
  };
}

class OrderRequest {
  const OrderRequest({
    required this.fulfillmentType,
    required this.items,
    this.requestedPickupAt,
    this.clientRequestId,
    this.voucherId,
  });

  final FulfillmentType fulfillmentType;
  final List<OrderSelectionLine> items;
  final DateTime? requestedPickupAt;
  final String? clientRequestId;
  final String? voucherId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (clientRequestId != null) 'clientRequestId': clientRequestId,
    if (voucherId != null) 'voucherId': voucherId,
    'fulfillmentType': fulfillmentType.name,
    if (fulfillmentType == FulfillmentType.scheduled)
      'requestedPickupAt': requestedPickupAt!.toUtc().toIso8601String(),
    'items': items.map((line) => line.toJson()).toList(growable: false),
  };

  OrderRequest copyWith({String? clientRequestId, String? voucherId}) =>
      OrderRequest(
        fulfillmentType: fulfillmentType,
        items: items,
        requestedPickupAt: requestedPickupAt,
        clientRequestId: clientRequestId ?? this.clientRequestId,
        voucherId: voucherId ?? this.voucherId,
      );
}

class OrderAddOnSnapshot {
  const OrderAddOnSnapshot({
    required this.itemId,
    required this.sku,
    required this.name,
    required this.price,
  });

  factory OrderAddOnSnapshot.fromJson(Map<String, dynamic> json) =>
      OrderAddOnSnapshot(
        itemId: _requiredString(json, 'itemId'),
        sku: _requiredString(json, 'sku'),
        name: _requiredString(json, 'name'),
        price: Money.fromSen(_requiredInt(json, 'priceSen')),
      );

  final String itemId;
  final String sku;
  final String name;
  final Money price;
}

class OrderVariantSnapshot {
  const OrderVariantSnapshot({
    required this.id,
    required this.code,
    required this.label,
    required this.priceDeltaSen,
  });

  factory OrderVariantSnapshot.fromJson(Map<String, dynamic> json) =>
      OrderVariantSnapshot(
        id: _requiredString(json, 'id'),
        code: _requiredString(json, 'code'),
        label: _requiredString(json, 'label'),
        priceDeltaSen: _requiredInt(json, 'priceDeltaSen'),
      );

  final String id;
  final String code;
  final String label;
  final int priceDeltaSen;
}

class OrderOptionSnapshot {
  const OrderOptionSnapshot({
    required this.groupId,
    required this.groupCode,
    required this.groupName,
    required this.optionValueId,
    required this.optionCode,
    required this.optionLabel,
    required this.priceDeltaSen,
  });

  factory OrderOptionSnapshot.fromJson(Map<String, dynamic> json) =>
      OrderOptionSnapshot(
        groupId: _requiredString(json, 'groupId'),
        groupCode: _requiredString(json, 'groupCode'),
        groupName: _requiredString(json, 'groupName'),
        optionValueId: _requiredString(json, 'optionValueId'),
        optionCode: _requiredString(json, 'optionCode'),
        optionLabel: _requiredString(json, 'optionLabel'),
        priceDeltaSen: _requiredInt(json, 'priceDeltaSen'),
      );

  final String groupId;
  final String groupCode;
  final String groupName;
  final String optionValueId;
  final String optionCode;
  final String optionLabel;
  final int priceDeltaSen;
}

class OrderLineSnapshot {
  const OrderLineSnapshot({
    this.id,
    required this.lineNumber,
    required this.itemId,
    required this.sku,
    required this.name,
    required this.basePrice,
    this.variant,
    this.addOns = const [],
    required this.addOnTotal,
    this.options = const [],
    this.optionTotal = Money.zero,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.note,
  });

  factory OrderLineSnapshot.fromJson(Map<String, dynamic> json) {
    final variantRaw = json['variant'];
    if (variantRaw != null && variantRaw is! Map) {
      throw const FormatException('Order line variant must be an object');
    }
    final addOnsRaw = json['addOns'];
    if (addOnsRaw is! List) {
      throw const FormatException('Order line addOns must be an array');
    }
    final optionsRaw = json['options'];
    if (optionsRaw is! List) {
      throw const FormatException('Order line options must be an array');
    }

    final quantity = _requiredInt(json, 'quantity');
    final basePriceSen = _requiredInt(json, 'basePriceSen');
    final addOnTotalSen = _requiredInt(json, 'addOnTotalSen');
    final optionTotalSen = _requiredInt(json, 'optionTotalSen');
    final unitPriceSen = _requiredInt(json, 'unitPriceSen');
    final lineTotalSen = _requiredInt(json, 'lineTotalSen');
    if (quantity <= 0 ||
        basePriceSen < 0 ||
        addOnTotalSen < 0 ||
        unitPriceSen < 0 ||
        lineTotalSen < 0) {
      throw const FormatException('Invalid order line commercial values');
    }
    if (lineTotalSen != unitPriceSen * quantity) {
      throw const FormatException('Order line total does not match quantity');
    }

    final noteRaw = json['note'];
    if (noteRaw != null && noteRaw is! String) {
      throw const FormatException('Order line note must be a string or null');
    }
    final idRaw = json['id'];
    if (idRaw != null && idRaw is! String) {
      throw const FormatException('Order line id must be a string or null');
    }

    return OrderLineSnapshot(
      id: idRaw as String?,
      lineNumber: _requiredInt(json, 'lineNumber'),
      itemId: _requiredString(json, 'itemId'),
      sku: _requiredString(json, 'sku'),
      name: _requiredString(json, 'name'),
      basePrice: Money.fromSen(basePriceSen),
      variant:
          variantRaw == null
              ? null
              : OrderVariantSnapshot.fromJson(
                Map<String, dynamic>.from(variantRaw),
              ),
      addOns:
          addOnsRaw
              .map(
                (value) => OrderAddOnSnapshot.fromJson(
                  _mapValue(value, 'order line add-on'),
                ),
              )
              .toList(growable: false),
      addOnTotal: Money.fromSen(addOnTotalSen),
      options:
          optionsRaw
              .map(
                (value) => OrderOptionSnapshot.fromJson(
                  _mapValue(value, 'order line option'),
                ),
              )
              .toList(growable: false),
      optionTotal: Money.fromSen(optionTotalSen),
      unitPrice: Money.fromSen(unitPriceSen),
      quantity: quantity,
      lineTotal: Money.fromSen(lineTotalSen),
      note: noteRaw as String?,
    );
  }

  final String? id;
  final int lineNumber;
  final String itemId;
  final String sku;
  final String name;
  final Money basePrice;
  final OrderVariantSnapshot? variant;
  final List<OrderAddOnSnapshot> addOns;
  final Money addOnTotal;
  final List<OrderOptionSnapshot> options;
  final Money optionTotal;
  final Money unitPrice;
  final int quantity;
  final Money lineTotal;
  final String? note;

  String? get configurationLabel {
    final parts = <String>[
      if (variant != null) variant!.label,
      ...options.map((option) => '${option.groupName}: ${option.optionLabel}'),
      ...addOns.map((addOn) => addOn.name),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class OrderVoucherSnapshot {
  const OrderVoucherSnapshot({
    this.id,
    required this.code,
    required this.rewardCode,
    required this.rewardName,
    required this.rewardType,
    required this.discount,
    this.freeItemLineNumber,
    this.expiresAt,
    this.appliedAt,
  });

  factory OrderVoucherSnapshot.fromJson(Map<String, dynamic> json) {
    final discountSen = _requiredInt(json, 'discountSen');
    if (discountSen <= 0) {
      throw const FormatException('Voucher discount must be positive');
    }
    return OrderVoucherSnapshot(
      id: _optionalString(json, 'id'),
      code: _requiredString(json, 'code'),
      rewardCode: _requiredString(json, 'rewardCode'),
      rewardName: _requiredString(json, 'rewardName'),
      rewardType: _requiredString(json, 'rewardType'),
      discount: Money.fromSen(discountSen),
      freeItemLineNumber: _optionalInt(json, 'freeItemLineNumber'),
      expiresAt: _optionalDate(json['expiresAt']),
      appliedAt: _optionalDate(json['appliedAt']),
    );
  }

  final String? id;
  final String code;
  final String rewardCode;
  final String rewardName;
  final String rewardType;
  final Money discount;
  final int? freeItemLineNumber;
  final DateTime? expiresAt;
  final DateTime? appliedAt;
}

class OrderQuote {
  const OrderQuote({
    required this.pricingVersion,
    required this.currency,
    required this.subtotal,
    this.discount = Money.zero,
    required this.total,
    this.voucher,
    required this.fulfillmentType,
    this.requestedPickupAt,
    required this.serverNow,
    required this.schedulePolicy,
    required this.lines,
  });

  factory OrderQuote.fromJson(Map<String, dynamic> json) {
    final lines = _parseLines(json);
    final subtotalSen = _requiredInt(json, 'subtotalSen');
    final discountSen = _requiredInt(json, 'discountSen');
    final totalSen = _requiredInt(json, 'totalSen');
    final voucher = _parseVoucher(json['voucher']);
    _validateCommercialSnapshot(
      subtotalSen: subtotalSen,
      discountSen: discountSen,
      totalSen: totalSen,
      lines: lines,
      voucher: voucher,
    );

    final schedulePolicyRaw = json['schedulePolicy'];
    if (schedulePolicyRaw is! Map) {
      throw const FormatException('schedulePolicy must be an object');
    }
    final serverNow = _requiredDate(json, 'serverNow');
    return OrderQuote(
      pricingVersion: _requiredInt(json, 'pricingVersion'),
      currency: _requiredString(json, 'currency'),
      subtotal: Money.fromSen(subtotalSen),
      discount: Money.fromSen(discountSen),
      total: Money.fromSen(totalSen),
      voucher: voucher,
      fulfillmentType: _fulfillmentType(json['fulfillmentType']),
      requestedPickupAt: _optionalDate(json['requestedPickupAt']),
      serverNow: serverNow,
      schedulePolicy: OrderingPolicy.fromJson(<String, dynamic>{
        ...Map<String, dynamic>.from(schedulePolicyRaw),
        'serverNow': serverNow.toIso8601String(),
      }),
      lines: lines,
    );
  }

  final int pricingVersion;
  final String currency;
  final Money subtotal;
  final Money discount;
  final Money total;
  final OrderVoucherSnapshot? voucher;
  final FulfillmentType fulfillmentType;
  final DateTime? requestedPickupAt;
  final DateTime serverNow;
  final OrderingPolicy schedulePolicy;
  final List<OrderLineSnapshot> lines;
}

class OrderSnapshot {
  const OrderSnapshot({
    required this.id,
    required this.orderNumber,
    required this.fulfillmentType,
    this.requestedPickupAt,
    required this.status,
    required this.statusVersion,
    required this.currency,
    required this.pricingVersion,
    required this.subtotal,
    this.discount = Money.zero,
    required this.total,
    this.voucher,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
  });

  factory OrderSnapshot.fromJson(Map<String, dynamic> json) {
    final lines = _parseLines(json);
    final subtotalSen = _requiredInt(json, 'subtotalSen');
    final discountSen = _requiredInt(json, 'discountSen');
    final totalSen = _requiredInt(json, 'totalSen');
    final voucher = _parseVoucher(json['voucher']);
    _validateCommercialSnapshot(
      subtotalSen: subtotalSen,
      discountSen: discountSen,
      totalSen: totalSen,
      lines: lines,
      voucher: voucher,
    );

    return OrderSnapshot(
      id: _requiredString(json, 'id'),
      orderNumber: _requiredOrderNumber(json['orderNumber']),
      fulfillmentType: _fulfillmentType(json['fulfillmentType']),
      requestedPickupAt: _optionalDate(json['requestedPickupAt']),
      status: OrderStatus.fromJson(json['status']),
      statusVersion: _requiredInt(json, 'statusVersion'),
      currency: _requiredString(json, 'currency'),
      pricingVersion: _requiredInt(json, 'pricingVersion'),
      subtotal: Money.fromSen(subtotalSen),
      discount: Money.fromSen(discountSen),
      total: Money.fromSen(totalSen),
      voucher: voucher,
      createdAt: _requiredDate(json, 'createdAt'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      lines: lines,
    );
  }

  final String id;
  final String orderNumber;
  final FulfillmentType fulfillmentType;
  final DateTime? requestedPickupAt;
  final OrderStatus status;
  final int statusVersion;
  final String currency;
  final int pricingVersion;
  final Money subtotal;
  final Money discount;
  final Money total;
  final OrderVoucherSnapshot? voucher;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderLineSnapshot> lines;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
}

List<OrderLineSnapshot> _parseLines(Map<String, dynamic> json) {
  final raw = json['lines'];
  if (raw is! List || raw.isEmpty) {
    throw const FormatException('Order lines must be a non-empty array');
  }
  return raw
      .map(
        (value) => OrderLineSnapshot.fromJson(
          _mapValue(value, 'order line'),
        ),
      )
      .toList(growable: false);
}

OrderVoucherSnapshot? _parseVoucher(Object? raw) {
  if (raw == null) return null;
  if (raw is! Map) {
    throw const FormatException('Voucher snapshot must be an object or null');
  }
  return OrderVoucherSnapshot.fromJson(Map<String, dynamic>.from(raw));
}

void _validateCommercialSnapshot({
  required int subtotalSen,
  required int discountSen,
  required int totalSen,
  required List<OrderLineSnapshot> lines,
  required OrderVoucherSnapshot? voucher,
}) {
  if (subtotalSen < 0 || discountSen < 0 || totalSen < 0) {
    throw const FormatException('Order commercial values cannot be negative');
  }
  if (totalSen != subtotalSen - discountSen) {
    throw const FormatException(
      'Order total must equal subtotal minus discount',
    );
  }
  final lineSubtotal = lines.fold<int>(
    0,
    (sum, line) => sum + line.lineTotal.sen,
  );
  if (lineSubtotal != subtotalSen) {
    throw const FormatException(
      'Order line totals must equal the authoritative subtotal',
    );
  }
  if (discountSen == 0 && voucher != null) {
    throw const FormatException('Zero-discount order cannot carry a voucher');
  }
  if (discountSen > 0 && voucher == null) {
    throw const FormatException('Discounted order requires a voucher snapshot');
  }
  if (voucher != null && voucher.discount.sen != discountSen) {
    throw const FormatException(
      'Voucher discount must match the authoritative order discount',
    );
  }
}

FulfillmentType _fulfillmentType(Object? value) {
  if (value is! String) {
    throw const FormatException('fulfillmentType must be a string');
  }
  for (final type in FulfillmentType.values) {
    if (type.name == value) return type;
  }
  throw FormatException('Unknown fulfillmentType: $value');
}

Map<String, dynamic> _mapValue(Object? value, String label) {
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

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string or null');
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

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('$key must be an integer or null');
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
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be an ISO-8601 timestamp');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key must be an ISO-8601 timestamp');
  }
  return parsed;
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is! String || value.isEmpty) {
    throw const FormatException('Optional date must be an ISO-8601 timestamp');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw const FormatException('Optional date must be an ISO-8601 timestamp');
  }
  return parsed;
}

String _requiredOrderNumber(Object? value) {
  if (value is int) return value.toString();
  if (value is String && value.trim().isNotEmpty) return value;
  throw const FormatException('orderNumber must be a non-empty string or integer');
}
