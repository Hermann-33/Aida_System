import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz_data;
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
    final policy = _policy;
    final window = policy == null ? null : _todayPickupWindow(policy);
    setState(() {
      _fulfillment = value;
      _pickupAt =
          value == FulfillmentType.scheduled && window != null
              ? _composePickup(policy!, window.startHour, window.startMinute)
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
    final window = policy == null ? null : _todayPickupWindow(policy);
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
                  if (policy?.scheduleEnabled == true && window != null) ...[
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
                            window != null &&
                            _pickupAt != null)
                        ? Padding(
                          key: const ValueKey('pickup-wheel'),
                          padding: const EdgeInsets.only(top: 8),
                          child: _PickupTimeWheel(
                            policy: policy!,
                            window: window,
                            selected: _pickupAt!,
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

/// The café's opening hours. Not part of [OrderingPolicy] — there's no
/// operating-hours concept anywhere in the ordering system yet, backend
/// included — so this is a UI-only stopgap until that's modelled server-side
/// (at which point this should come from the policy, not be hardcoded here).
const _cafeOpenHour = 8;
const _cafeCloseHour = 17;

typedef _PickupWindow =
    ({int startHour, int startMinute, int endHourExclusive});

/// The stretch of today still bookable: from whichever is later — the lead
/// time cutoff or opening time — through closing. Null once today's window
/// has closed (or the lead time already pushes past today). [startMinute]
/// only constrains [_PickupWindow.startHour] itself; every later hour up to
/// [_PickupWindow.endHourExclusive] offers the full 00–59.
///
/// Deliberately not derived from [derivePickupSlots]/
/// [OrderingPolicy.slotIntervalMinutes] — per product decision, the picker
/// now offers every minute rather than the backend's current 15-minute
/// steps, ahead of the backend team relaxing that interval to match.
bool _tzInitialized = false;

/// [derivePickupSlots] used to be the only caller of [tz.getLocation] in the
/// checkout flow, so it initialized the timezone database as a side effect.
/// This widget calls [tz.getLocation] directly now, so it owns that
/// initialization instead — guarded so repeated builds don't re-parse the
/// embedded database every time.
void _ensureTimeZonesInitialized() {
  if (_tzInitialized) return;
  tz_data.initializeTimeZones();
  _tzInitialized = true;
}

_PickupWindow? _todayPickupWindow(OrderingPolicy policy) {
  _ensureTimeZonesInitialized();
  final location = tz.getLocation(policy.timezone);
  final today = tz.TZDateTime.from(policy.serverNow, location);
  final earliest = tz.TZDateTime.from(
    policy.serverNow.toUtc().add(Duration(minutes: policy.minimumLeadMinutes)),
    location,
  );
  final sameDay =
      earliest.year == today.year &&
      earliest.month == today.month &&
      earliest.day == today.day;
  if (!sameDay) return null;

  var startHour = _cafeOpenHour;
  var startMinute = 0;
  if (earliest.hour > _cafeOpenHour ||
      (earliest.hour == _cafeOpenHour && earliest.minute > 0)) {
    startHour = earliest.hour;
    startMinute = earliest.minute;
  }
  if (startHour >= _cafeCloseHour) return null;
  return (
    startHour: startHour,
    startMinute: startMinute,
    endHourExclusive: _cafeCloseHour,
  );
}

DateTime _composePickup(OrderingPolicy policy, int hour, int minute) {
  final location = tz.getLocation(policy.timezone);
  final today = tz.TZDateTime.from(policy.serverNow, location);
  return tz.TZDateTime(
    location,
    today.year,
    today.month,
    today.day,
    hour,
    minute,
  ).toUtc();
}

/// POS-style pickup-time picker, redesigned per user report that the old
/// horizontal-scrolling pill row felt cramped and made precise times hard to
/// reach. Twin Hour/Minute wheels (native [ListWheelScrollView], no custom
/// painting) so scrolling feels precise and modern. The Minute wheel offers
/// every minute — see [_todayPickupWindow] for why that's no longer tied to
/// [OrderingPolicy.slotIntervalMinutes].
class _PickupTimeWheel extends StatefulWidget {
  const _PickupTimeWheel({
    required this.policy,
    required this.window,
    required this.selected,
    required this.onSelected,
  });

  final OrderingPolicy policy;
  final _PickupWindow window;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_PickupTimeWheel> createState() => _PickupTimeWheelState();
}

class _PickupTimeWheelState extends State<_PickupTimeWheel> {
  static const _itemExtent = 46.0;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _hourIndex;
  late int _minuteIndex;

  List<int> get _hours => [
    for (
      var h = widget.window.startHour;
      h < widget.window.endHourExclusive;
      h++
    )
      h,
  ];

  List<int> _minutesForHour(int hour) => [
    for (
      var m = hour == widget.window.startHour ? widget.window.startMinute : 0;
      m < 60;
      m++
    )
      m,
  ];

  @override
  void initState() {
    super.initState();
    final position = _positionOf(widget.selected);
    _hourIndex = position.hourIndex;
    _minuteIndex = position.minuteIndex;
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _minuteIndex);
  }

  ({int hourIndex, int minuteIndex}) _positionOf(DateTime slot) {
    final local = tz.TZDateTime.from(
      slot,
      tz.getLocation(widget.policy.timezone),
    );
    final hours = _hours;
    final hourIndex = hours.indexOf(local.hour);
    if (hourIndex == -1) return (hourIndex: 0, minuteIndex: 0);
    final minuteIndex = _minutesForHour(hours[hourIndex]).indexOf(local.minute);
    return (
      hourIndex: hourIndex,
      minuteIndex: minuteIndex == -1 ? 0 : minuteIndex,
    );
  }

  @override
  void didUpdateWidget(covariant _PickupTimeWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check on a window change too, even if `selected` is unchanged: a
    // policy refresh (e.g. "Try again" re-fetching after an error) can
    // shrink today's window as time moves on, leaving a remembered index
    // pointing past the end of the new, shorter hour/minute lists.
    if (widget.selected == oldWidget.selected &&
        widget.window == oldWidget.window) {
      return;
    }
    final position = _positionOf(widget.selected);
    if (position.hourIndex != _hourIndex) {
      _hourIndex = position.hourIndex;
      if (_hourController.hasClients) _hourController.jumpToItem(_hourIndex);
    }
    if (position.minuteIndex != _minuteIndex) {
      _minuteIndex = position.minuteIndex;
      if (_minuteController.hasClients) {
        _minuteController.jumpToItem(_minuteIndex);
      }
    }
    // A shrunk window can force a different slot than the one `selected`
    // asked for (e.g. the previously-picked minute no longer exists in the
    // new window). Tell the parent so its stored pickup time matches what's
    // actually shown — deferred a frame since this runs during a build.
    final hour = _hours[_hourIndex];
    final corrected = _composePickup(
      widget.policy,
      hour,
      _minutesForHour(hour)[_minuteIndex],
    );
    if (corrected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelected(corrected);
      });
    }
  }

  void _onHourChanged(int index) {
    HapticFeedback.selectionClick();
    final hour = _hours[index];
    final minute = _minutesForHour(hour).first;
    setState(() {
      _hourIndex = index;
      _minuteIndex = 0;
    });
    _minuteController.jumpToItem(0);
    widget.onSelected(_composePickup(widget.policy, hour, minute));
  }

  void _onMinuteChanged(int index) {
    HapticFeedback.selectionClick();
    final hour = _hours[_hourIndex];
    final minute = _minutesForHour(hour)[index];
    setState(() => _minuteIndex = index);
    widget.onSelected(_composePickup(widget.policy, hour, minute));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int focusedIndex,
    required ValueChanged<int> onChanged,
    required String Function(int index) labelBuilder,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      diameterRatio: 1.4,
      perspective: 0.004,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isFocused = index == focusedIndex;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              style: AidaType.sans(
                size: isFocused ? 30 : 17,
                weight: isFocused ? FontWeight.w800 : FontWeight.w500,
                color:
                    isFocused
                        ? AidaColors.coffee
                        : AidaColors.textMuted.withValues(alpha: 0.6),
              ),
              child: Text(labelBuilder(index).padLeft(2, '0')),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = _hours;
    final minutes = _minutesForHour(hours[_hourIndex]);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AidaColors.cream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AidaColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'PICK TIME',
                style: AidaType.sans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AidaColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 5 * _itemExtent,
            child: ShaderMask(
              shaderCallback:
                  (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.28, 0.72, 1.0],
                  ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Row(
                children: [
                  _divider(),
                  Expanded(
                    child: _wheel(
                      controller: _hourController,
                      itemCount: hours.length,
                      focusedIndex: _hourIndex,
                      onChanged: _onHourChanged,
                      labelBuilder: (index) => '${hours[index]}',
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      'Hr',
                      textAlign: TextAlign.center,
                      style: AidaType.sans(
                        size: 12,
                        color: AidaColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _wheel(
                      controller: _minuteController,
                      itemCount: minutes.length,
                      focusedIndex: _minuteIndex,
                      onChanged: _onMinuteChanged,
                      labelBuilder: (index) => '${minutes[index]}',
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      'Min',
                      textAlign: TextAlign.center,
                      style: AidaType.sans(
                        size: 12,
                        color: AidaColors.textMuted,
                      ),
                    ),
                  ),
                  _divider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: _itemExtent * 0.7, color: AidaColors.latte);
}
