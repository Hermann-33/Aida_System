import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../application/order_checkout.dart';
import '../../core/error/result.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
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
  late final OrderCheckoutSession _session;
  OrderingPolicy? _policy;
  OrderQuote? _quote;
  FulfillmentType _fulfillment = FulfillmentType.asap;
  DateTime? _pickupAt;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
    final result = await widget.repository.getOrderingPolicy();
    if (!mounted) return;
    switch (result) {
      case Ok(value: final policy):
        _policy = policy;
        await _refreshQuote();
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

  Future<void> _refreshQuote() async {
    _setBusy();
    final result = await _session.quote(_request);
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
    final slots =
        _policy == null ? const <DateTime>[] : derivePickupSlots(_policy!);
    setState(() {
      _fulfillment = value;
      _pickupAt =
          value == FulfillmentType.scheduled && slots.isNotEmpty
              ? slots.first
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
    if (_quote == null || _busy) return;
    _setBusy();
    final result = await _session.place(_request);
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
    final policy = _policy;
    final slots =
        policy == null ? const <DateTime>[] : derivePickupSlots(policy);
    final canSchedule = policy?.scheduleEnabled == true && slots.isNotEmpty;

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
                'Choose pickup, then confirm the server total.',
                style: AidaType.sans(size: 13, color: AidaColors.textMuted),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChip(
                      label: 'ASAP',
                      selected: _fulfillment == FulfillmentType.asap,
                      onTap: () => _selectFulfillment(FulfillmentType.asap),
                    ),
                  ),
                  if (canSchedule) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChoiceChip(
                        label: 'Schedule',
                        selected: _fulfillment == FulfillmentType.scheduled,
                        onTap:
                            () => _selectFulfillment(FulfillmentType.scheduled),
                      ),
                    ),
                  ],
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    ),
                child:
                    (_fulfillment == FulfillmentType.scheduled &&
                            policy != null &&
                            slots.isNotEmpty &&
                            _pickupAt != null)
                        ? Padding(
                          key: const ValueKey('pickup-wheel'),
                          padding: const EdgeInsets.only(top: 10),
                          child: _PickupSlotWheel(
                            slots: slots,
                            timezone: policy.timezone,
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
                    const Icon(
                      Icons.storefront_rounded,
                      color: AidaColors.coffee,
                    ),
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
                TextButton(
                  onPressed: _quote == null ? _load : _place,
                  child: const Text('Try again'),
                ),
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
    color:
        selected ? AidaColors.coffee.withValues(alpha: 0.08) : AidaColors.cream,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AidaColors.coffee : AidaColors.latte,
          ),
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

/// Tactile wheel presentation over the authoritative slots produced by
/// [derivePickupSlots]. The redesign keeps the wheel interaction without
/// inventing local opening hours or bypassing [OrderingPolicy.slotIntervalMinutes].
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
  Widget build(BuildContext context) {
    return IgnorePointer(
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
                'PICK TIME',
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
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
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                style: AidaType.sans(
                                  size: selected ? 16 : 13,
                                  weight:
                                      selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                  color:
                                      selected
                                          ? AidaColors.coffee
                                          : AidaColors.textMuted.withValues(
                                            alpha: 0.55,
                                          ),
                                ),
                                child: Text(
                                  _slotLabel(
                                    widget.slots[index],
                                    widget.timezone,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        height: _itemExtent,
                        decoration: BoxDecoration(
                          color: AidaColors.cardWhite.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: AidaColors.coffee.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Times come from the café scheduling policy.',
                style: AidaType.sans(size: 11, color: AidaColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _slotLabel(DateTime slot, String timezone) {
  final local = tz.TZDateTime.from(slot, tz.getLocation(timezone));
  final hour =
      local.hour == 0
          ? 12
          : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  return '${local.day}/${local.month}  $hour:$minute $suffix';
}
