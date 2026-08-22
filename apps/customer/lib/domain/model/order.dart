import 'money.dart';

enum FulfillmentType { asap, scheduled }

enum OrderStatus {
  confirmed,
  scheduled,
  preparing,
  ready,
  completed,
  cancelled;

  static OrderStatus fromJson(Object? value) => values.firstWhere(
    (status) => status.name == value,
    orElse: () => confirmed,
  );
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

  factory OrderingPolicy.fromJson(Map<String, dynamic> json) => OrderingPolicy(
    serverNow: DateTime.parse(json['serverNow'] as String),
    timezone: json['timezone'] as String,
    scheduleEnabled: json['scheduleEnabled'] == true,
    minimumLeadMinutes: _int(json['minimumLeadMinutes']),
    preparationLeadMinutes: json['preparationLeadMinutes'] == null
        ? 0
        : _int(json['preparationLeadMinutes']),
    slotIntervalMinutes: _int(json['slotIntervalMinutes']),
    maximumAdvanceDays: _int(json['maximumAdvanceDays']),
  );

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
  });

  final FulfillmentType fulfillmentType;
  final List<OrderSelectionLine> items;
  final DateTime? requestedPickupAt;
  final String? clientRequestId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (clientRequestId != null) 'clientRequestId': clientRequestId,
    'fulfillmentType': fulfillmentType.name,
    if (fulfillmentType == FulfillmentType.scheduled)
      'requestedPickupAt': requestedPickupAt!.toUtc().toIso8601String(),
    'items': items.map((line) => line.toJson()).toList(growable: false),
  };

  OrderRequest copyWith({String? clientRequestId}) => OrderRequest(
    fulfillmentType: fulfillmentType,
    items: items,
    requestedPickupAt: requestedPickupAt,
    clientRequestId: clientRequestId ?? this.clientRequestId,
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
        itemId: json['itemId'] as String,
        sku: json['sku'] as String,
        name: json['name'] as String,
        price: Money.fromSen(_int(json['priceSen'])),
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
        id: json['id'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
        priceDeltaSen: _int(json['priceDeltaSen']),
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
        groupId: json['groupId'] as String,
        groupCode: json['groupCode'] as String,
        groupName: json['groupName'] as String,
        optionValueId: json['optionValueId'] as String,
        optionCode: json['optionCode'] as String,
        optionLabel: json['optionLabel'] as String,
        priceDeltaSen: _int(json['priceDeltaSen']),
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
    final variant = json['variant'];
    final addOns = json['addOns'];
    final options = json['options'];
    return OrderLineSnapshot(
      id: json['id'] as String?,
      lineNumber: _int(json['lineNumber']),
      itemId: json['itemId'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      basePrice: Money.fromSen(_int(json['basePriceSen'])),
      variant: variant is Map
          ? OrderVariantSnapshot.fromJson(Map<String, dynamic>.from(variant))
          : null,
      addOns: addOns is List
          ? addOns
              .map(
                (value) => OrderAddOnSnapshot.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ),
              )
              .toList(growable: false)
          : const [],
      addOnTotal: Money.fromSen(_int(json['addOnTotalSen'])),
      options: options is List
          ? options
              .map(
                (value) => OrderOptionSnapshot.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ),
              )
              .toList(growable: false)
          : const [],
      optionTotal: Money.fromSen(
        json['optionTotalSen'] == null ? 0 : _int(json['optionTotalSen']),
      ),
      unitPrice: Money.fromSen(_int(json['unitPriceSen'])),
      quantity: _int(json['quantity']),
      lineTotal: Money.fromSen(_int(json['lineTotalSen'])),
      note: json['note'] as String?,
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

class OrderQuote {
  const OrderQuote({
    required this.pricingVersion,
    required this.currency,
    required this.subtotal,
    required this.total,
    required this.fulfillmentType,
    this.requestedPickupAt,
    required this.serverNow,
    required this.schedulePolicy,
    required this.lines,
  });

  factory OrderQuote.fromJson(Map<String, dynamic> json) => OrderQuote(
    pricingVersion: _int(json['pricingVersion']),
    currency: json['currency'] as String,
    subtotal: Money.fromSen(_int(json['subtotalSen'])),
    total: Money.fromSen(_int(json['totalSen'])),
    fulfillmentType: FulfillmentType.values.byName(
      json['fulfillmentType'] as String,
    ),
    requestedPickupAt: _date(json['requestedPickupAt']),
    serverNow: DateTime.parse(json['serverNow'] as String),
    schedulePolicy: OrderingPolicy.fromJson(<String, dynamic>{
      ...Map<String, dynamic>.from(json['schedulePolicy'] as Map),
      'serverNow': json['serverNow'],
    }),
    lines: (json['lines'] as List)
        .map(
          (value) => OrderLineSnapshot.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList(growable: false),
  );

  final int pricingVersion;
  final String currency;
  final Money subtotal;
  final Money total;
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
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
  });

  factory OrderSnapshot.fromJson(Map<String, dynamic> json) => OrderSnapshot(
    id: json['id'] as String,
    orderNumber: json['orderNumber'].toString(),
    fulfillmentType: FulfillmentType.values.byName(
      json['fulfillmentType'] as String,
    ),
    requestedPickupAt: _date(json['requestedPickupAt']),
    status: OrderStatus.fromJson(json['status']),
    statusVersion: _int(json['statusVersion']),
    currency: json['currency'] as String,
    pricingVersion: _int(json['pricingVersion']),
    subtotal: Money.fromSen(_int(json['subtotalSen'])),
    total: Money.fromSen(_int(json['totalSen'])),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    lines: (json['lines'] as List)
        .map(
          (value) => OrderLineSnapshot.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList(growable: false),
  );

  final String id;
  final String orderNumber;
  final FulfillmentType fulfillmentType;
  final DateTime? requestedPickupAt;
  final OrderStatus status;
  final int statusVersion;
  final String currency;
  final int pricingVersion;
  final Money subtotal;
  final Money total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderLineSnapshot> lines;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}
