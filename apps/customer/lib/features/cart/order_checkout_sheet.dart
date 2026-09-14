import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../application/order_checkout.dart';
import '../../core/error/result.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/branch_pickup.dart';
import '../../domain/model/order.dart';
import '../../domain/repository/order_repository.dart';

class OrderCheckoutSheet extends StatefulWidget {
  const OrderCheckoutSheet({
    super.key,
    required this.repository,
    required this.items,
    required this.onPlaced,
  });

  final OrderRepository repository;
  final List<OrderSelectionLine> items;
  final ValueChanged<OrderSnapshot> onPlaced;

  @override
  State<OrderCheckoutSheet> createState() => _OrderCheckoutSheetState();
}

class _OrderCheckoutSheetState extends State<OrderCheckoutSheet> {
  static const _maximumVisibleSlots = 96;

  late final OrderCheckoutSession _session;
  List<PickupBranch> _branches = const [];
  PickupBranch? _branch;
  List<PickupSlot> _slots = const [];
  OrderQuote? _quote;
  FulfillmentType _fulfillment = FulfillmentType.asap;
  DateTime? _pickupAt;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _session = OrderCheckoutSession(widget.repository);
    _load();
  }

  OrderRequest get _request => OrderRequest(
    fulfillmentType: _fulfillment,
    requestedPickupAt: _pickupAt,
    items: widget.items,
  );

  Future<void> _load() async {
    _setBusy();
    final result = await widget.repository.listPickupBranches();
    if (!mounted) return;
    switch (result) {
      case Ok(value: final branches):
        if (branches.isEmpty) {
          setState(() {
            _busy = false;
            _error = 'No café is available for pickup right now.';
          });
          return;
        }
        _branches = branches;
        final selected = branches.firstWhere(
          (branch) => branch.isDefault,
          orElse: () => branches.first,
        );
        await _loadBranch(selected);
      case Err(failure: final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  void _setBusy() => setState(() {
    _busy = true;
    _error = null;
  });

  Future<void> _loadBranch(PickupBranch branch) async {
    if (_session.pendingClientRequestId != null) return;
    _setBusy();

    final stateResult = await widget.repository.getBranchPickupState(branch.id);
    if (!mounted) return;
    if (stateResult case Err(failure: final failure)) {
      setState(() {
        _branch = branch;
        _slots = const [];
        _quote = null;
        _busy = false;
        _error = failure.message;
      });
      return;
    }

    final state = (stateResult as Ok<BranchPickupState>).value;
    final slots = branch.policy.scheduleEnabled
        ? await _loadAuthoritativeSlots(branch, state.serverNow)
        : const <PickupSlot>[];
    if (!mounted) return;

    final canUseAsap = branch.policy.asapEnabled && state.valid;
    final fulfillment = canUseAsap
        ? FulfillmentType.asap
        : slots.isNotEmpty
        ? FulfillmentType.scheduled
        : FulfillmentType.asap;

    setState(() {
      _branch = branch;
      _slots = slots;
      _fulfillment = fulfillment;
      _pickupAt = fulfillment == FulfillmentType.scheduled ? slots.first.pickupAt : null;
      _quote = null;
      _error =
          !canUseAsap && slots.isEmpty
              ? state.message
              : null;
      _busy = false;
    });

    if (canUseAsap || slots.isNotEmpty) await _refreshQuote();
  }

  Future<List<PickupSlot>> _loadAuthoritativeSlots(
    PickupBranch branch,
    DateTime serverNow,
  ) async {
    final location = tz.getLocation(branch.timezone);
    final localNow = tz.TZDateTime.from(serverNow.toUtc(), location);
    final firstDate = DateTime(localNow.year, localNow.month, localNow.day);
    final slots = <PickupSlot>[];

    for (var day = 0; day <= branch.policy.maximumAdvanceDays; day++) {
      final serviceDate = firstDate.add(Duration(days: day));
      final result = await widget.repository.listBranchPickupSlots(
        branch.id,
        serviceDate,
      );
      if (!mounted) return const [];
      switch (result) {
        case Ok(value: final response):
          slots.addAll(response.slots);
          if (slots.length >= _maximumVisibleSlots) {
            return List.unmodifiable(slots.take(_maximumVisibleSlots));
          }
        case Err():
          // Fail closed for the requested day. A later day can still be valid.
          continue;
      }
    }
    return List.unmodifiable(slots);
  }

  Future<void> _refreshQuote() async {
    final branch = _branch;
    if (branch == null) return;
    _setBusy();
    final result = await _session.quote(_request, branchId: branch.id);
    if (!mounted) return;
    switch (result) {
      case Ok(value: final quote):
        setState(() {
          _quote = quote;
          _busy = false;
        });
      case Err(failure: final failure):
        setState(() {
          _quote = null;
          _busy = false;
          _error = failure.message;
        });
    }
  }

  Future<void> _selectFulfillment(FulfillmentType value) async {
    if (_busy ||
        _session.pendingClientRequestId != null ||
        value == _fulfillment) {
      return;
    }
    setState(() {
      _fulfillment = value;
      _pickupAt =
          value == FulfillmentType.scheduled && _slots.isNotEmpty
              ? _slots.first.pickupAt
              : null;
    });
    await _refreshQuote();
  }

  Future<void> _selectSlot(DateTime slot) async {
    if (_busy || _session.pendingClientRequestId != null || slot == _pickupAt) {
      return;
    }
    setState(() => _pickupAt = slot);
    await _refreshQuote();
  }

  Future<void> _place() async {
    final branch = _branch;
    if (_quote == null || _busy || branch == null) return;
    _setBusy();
    final result = await _session.place(_request, branchId: branch.id);
    if (!mounted) return;
    switch (result) {
      case Ok(value: final order):
        widget.onPlaced(order);
      case Err(failure: final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final branch = _branch;
    final slotTimes = _slots.map((slot) => slot.pickupAt).toList(growable: false);
    final canSchedule = branch?.policy.scheduleEnabled == true && slotTimes.isNotEmpty;
    final canAsap = branch?.policy.asapEnabled == true;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AidaColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AidaColors.latte,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Review your order',
                style: AidaType.serif(size: 19, color: AidaColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a café and an available pickup time.',
                style: AidaType.sans(size: 13, color: AidaColors.textMuted),
              ),
              const SizedBox(height: 18),
              if (_branches.length > 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: branch?.id,
                  decoration: const InputDecoration(labelText: 'Pickup café'),
                  items: _branches
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _busy
                      ? null
                      : (id) {
                          if (id == null || id == branch?.id) return;
                          final selected = _branches.firstWhere((item) => item.id == id);
                          void _loadBranch(selected);
                        },
                ),
                const SizedBox(height: 8),
              ],
              if (branch != null)
                Text(
                  [
                    branch.name,
                    if (branch.addressText?.trim().isNotEmpty == true)
                      branch.addressText!.trim(),
                  ].join(' · '),
                  style: AidaType.sans(size: 12, color: AidaColors.textMuted),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canAsap)
                    Expanded(
                      child: _ChoiceChip(
                        label: 'Now',
                        selected: _fulfillment == FulfillmentType.asap,
                        onTap: () => _selectFulfillment(FulfillmentType.asap),
                      ),
                    ),
                  if (canAsap && canSchedule) const SizedBox(width: 10),
                  if (canSchedule)
                    Expanded(
                      child: _ChoiceChip(
                        label: 'Schedule',
                        selected: _fulfillment == FulfillmentType.scheduled,
                        onTap: () => _selectFulfillment(FulfillmentType.scheduled),
                      ),
                    ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child:
                    (_fulfillment == FulfillmentType.scheduled &&
                            branch != null &&
                            slotTimes.isNotEmpty &&
                            _pickupAt != null)
                        ? Padding(
                          key: const ValueKey('pickup-wheel'),
                          padding: const EdgeInsets.only(top: 10),
                          child: _PickupSlotWheel(
                            slots: slotTimes,
                            timezone: branch.timezone,
                            selected: _pickupAt!,
                            enabled: !_busy,
                            onSelected: _selectSlot,
                          ),
                        )
                        : const SizedBox.shrink(
                          key: ValueKey('pickup-wheel-empty'),
                        ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AidaColors.cream,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: AidaColors.coffee),
                    const SizedBox(width: 12),
                    Text(
                      'Pay at the counter',
                      style: AidaType.sans(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Server total',
                    style: AidaType.sans(size: 13, color: AidaColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    _quote?.total.formatted ?? '—',
                    style: AidaType.sans(
                      size: 18,
                      weight: FontWeight.w800,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _quote == null || _busy ? null : _place,
                  style: FilledButton.styleFrom(
                    backgroundColor: AidaColors.coffee,
                    foregroundColor: AidaColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _busy
                        ? 'Checking…'
                        : _quote != null
                        ? 'Place order · ${_quote!.total.formatted}'
                        : 'Place order',
                    style: AidaType.sans(size: 15, weight: FontWeight.w700),
                  ),
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(color: AidaColors.coffee),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AidaType.sans(size: 12.5, color: AidaColors.error),
                ),
                TextButton(onPressed: _load, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AidaColors.coffee.withValues(alpha: 0.08) : AidaColors.cream,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AidaColors.coffee : AidaColors.latte),
        ),
        child: Text(
          label,
          style: AidaType.sans(
            size: 12.5,
            weight: FontWeight.w700,
            color: selected ? AidaColors.coffee : AidaColors.textMuted,
          ),
        ),
      ),
    ),
  );
}

class _PickupSlotWheel extends StatefulWidget {
  const _PickupSlotWheel({
    required this.slots,
    required this.timezone,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final List<DateTime> slots;
  final String timezone;
  final DateTime selected;
  final bool enabled;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_PickupSlotWheel> createState() => _PickupSlotWheelState();
}

class _PickupSlotWheelState extends State<_PickupSlotWheel> {
  static const _itemExtent = 48.0;
  late FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexFor(widget.selected);
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  int _indexFor(DateTime selected) {
    final index = widget.slots.indexOf(selected);
    return index < 0 ? 0 : index;
  }

  @override
  void didUpdateWidget(covariant _PickupSlotWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _indexFor(widget.selected);
    if (next == _selectedIndex) return;
    _selectedIndex = next;
    if (_controller.hasClients) {
      _controller.animateToItem(
        next,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !widget.enabled,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.enabled ? 1 : 0.72,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: AidaColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AidaColors.latte),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AVAILABLE PICKUP TIMES',
              style: AidaType.sans(
                size: 10.5,
                weight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AidaColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _itemExtent * 3,
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: _itemExtent,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.7,
                perspective: 0.003,
                useMagnifier: true,
                magnification: 1.06,
                onSelectedItemChanged: (index) {
                  if (index == _selectedIndex) return;
                  setState(() => _selectedIndex = index);
                  HapticFeedback.selectionClick();
                  widget.onSelected(widget.slots[index]);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.slots.length,
                  builder: (context, index) {
                    final selected = index == _selectedIndex;
                    return Center(
                      child: Text(
                        _slotLabel(widget.slots[index], widget.timezone),
                        style: AidaType.sans(
                          size: selected ? 16 : 13,
                          weight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? AidaColors.coffee
                              : AidaColors.textMuted.withValues(alpha: 0.55),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Only server-authoritative open slots with remaining capacity are shown.',
              style: AidaType.sans(size: 11, color: AidaColors.textMuted),
            ),
          ],
        ),
      ),
    ),
  );
}

String _slotLabel(DateTime slot, String timezone) {
  final local = tz.TZDateTime.from(slot, tz.getLocation(timezone));
  final hour = local.hour == 0 ? 12 : local.hour > 12 ? local.hour - 12 : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  return '${local.day}/${local.month}  $hour:$minute $suffix';
}
