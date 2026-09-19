class PickupBranchPolicy {
  const PickupBranchPolicy({
    required this.asapEnabled,
    required this.scheduleEnabled,
    required this.minimumLeadMinutes,
    required this.preparationLeadMinutes,
    required this.slotIntervalMinutes,
    required this.maximumAdvanceDays,
    this.slotCapacityOrders,
  });

  factory PickupBranchPolicy.fromJson(Map<String, dynamic> json) =>
      PickupBranchPolicy(
        asapEnabled: json['asapEnabled'] == true,
        scheduleEnabled: json['scheduleEnabled'] == true,
        minimumLeadMinutes: _int(json['minimumLeadMinutes']),
        preparationLeadMinutes: _int(json['preparationLeadMinutes']),
        slotIntervalMinutes: _int(json['slotIntervalMinutes']),
        maximumAdvanceDays: _int(json['maximumAdvanceDays']),
        slotCapacityOrders:
            json['slotCapacityOrders'] == null
                ? null
                : _int(json['slotCapacityOrders']),
      );

  final bool asapEnabled;
  final bool scheduleEnabled;
  final int minimumLeadMinutes;
  final int preparationLeadMinutes;
  final int slotIntervalMinutes;
  final int maximumAdvanceDays;
  final int? slotCapacityOrders;
}

class PickupBranch {
  const PickupBranch({
    required this.id,
    required this.code,
    required this.name,
    required this.timezone,
    this.addressText,
    this.phone,
    required this.isDefault,
    required this.policy,
  });

  factory PickupBranch.fromJson(Map<String, dynamic> json) => PickupBranch(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    timezone: json['timezone'] as String,
    addressText: json['addressText'] as String?,
    phone: json['phone'] as String?,
    isDefault: json['isDefault'] == true,
    policy: PickupBranchPolicy.fromJson(
      Map<String, dynamic>.from(json['policy'] as Map),
    ),
  );

  final String id;
  final String code;
  final String name;
  final String timezone;
  final String? addressText;
  final String? phone;
  final bool isDefault;
  final PickupBranchPolicy policy;
}

class PickupSlot {
  const PickupSlot({
    required this.pickupAt,
    required this.prepareAt,
    this.remainingOrders,
  });

  factory PickupSlot.fromJson(Map<String, dynamic> json) => PickupSlot(
    pickupAt: DateTime.parse(json['pickupAt'] as String).toUtc(),
    prepareAt: DateTime.parse(json['prepareAt'] as String).toUtc(),
    remainingOrders:
        json['remainingOrders'] == null ? null : _int(json['remainingOrders']),
  );

  final DateTime pickupAt;
  final DateTime prepareAt;
  final int? remainingOrders;
}

class BranchPickupSlots {
  const BranchPickupSlots({
    required this.serverNow,
    required this.branchId,
    required this.serviceDate,
    required this.timezone,
    required this.slotIntervalMinutes,
    required this.slots,
  });

  factory BranchPickupSlots.fromJson(Map<String, dynamic> json) =>
      BranchPickupSlots(
        serverNow: DateTime.parse(json['serverNow'] as String).toUtc(),
        branchId: json['branchId'] as String,
        serviceDate: DateTime.parse(json['serviceDate'] as String),
        timezone: json['timezone'] as String,
        slotIntervalMinutes: _int(json['slotIntervalMinutes']),
        slots: (json['slots'] as List)
            .map(
              (value) => PickupSlot.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList(growable: false),
      );

  final DateTime serverNow;
  final String branchId;
  final DateTime serviceDate;
  final String timezone;
  final int slotIntervalMinutes;
  final List<PickupSlot> slots;
}

class BranchPickupState {
  const BranchPickupState({
    required this.serverNow,
    required this.valid,
    required this.code,
    required this.message,
  });

  factory BranchPickupState.fromJson(Map<String, dynamic> json) =>
      BranchPickupState(
        serverNow: DateTime.parse(json['serverNow'] as String).toUtc(),
        valid: json['valid'] == true,
        code: json['code'] as String,
        message: json['message'] as String,
      );

  final DateTime serverNow;
  final bool valid;
  final String code;
  final String message;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}
