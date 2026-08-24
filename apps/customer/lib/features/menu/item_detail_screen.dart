import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/neumorphic_control.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/model/cart.dart';
import '../../domain/model/menu_customization.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/menu_variant.dart';
import '../../domain/model/money.dart';

void openItemDetail(BuildContext context, MenuItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
}

/// Catalogue-driven item configuration.
///
/// Size, Temperature, Sweetness and compatible add-ons are all supplied by the
/// shared Supabase catalogue. This screen stages IDs only; checkout re-prices
/// and revalidates every selection server-side before an order is persisted.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final MenuItem item;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  MenuVariant? _size;
  final _selectedAddOnIds = <String>{};
  final _selectedOptionValueIds = <String>{};
  int _quantity = 1;
  final _noteController = TextEditingController();

  /// Drives the bottom bar's brief "Added ✓" state — replaces the old
  /// SnackBar. The confirmation lives right on the button the user just
  /// pressed instead of a separate message at the bottom of the screen.
  bool _justAdded = false;
  Timer? _justAddedTimer;

  @override
  void initState() {
    super.initState();
    _size = widget.item.defaultVariant;
    for (final group in widget.item.customizationGroups) {
      final option = group.defaultOption;
      if (option != null) _selectedOptionValueIds.add(option.id);
    }
  }

  @override
  void dispose() {
    _justAddedTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  bool get _requiredSelectionsComplete {
    for (final group in widget.item.customizationGroups) {
      final available = group.availableOptions;
      if (available.isEmpty) return false;
      if (!available.any(
        (option) => _selectedOptionValueIds.contains(option.id),
      )) {
        return false;
      }
    }
    return true;
  }

  void _selectOption(
    MenuCustomizationGroup group,
    MenuCustomizationOption option,
  ) {
    setState(() {
      for (final candidate in group.options) {
        _selectedOptionValueIds.remove(candidate.id);
      }
      _selectedOptionValueIds.add(option.id);
    });
  }

  Money _configuredUnitPrice(List<MenuItem> menu) {
    final addOns = addOnTotalFor(_selectedAddOnIds.toList(), menu);
    var optionSen = 0;
    for (final group in widget.item.customizationGroups) {
      for (final option in group.options) {
        if (_selectedOptionValueIds.contains(option.id)) {
          optionSen += option.priceDeltaSen;
          break;
        }
      }
    }
    return Money.fromSen(
      widget.item.price.sen +
          (_size?.priceDeltaSen ?? 0) +
          addOns.sen +
          optionSen,
    );
  }

  void _addToCart() {
    if (!_requiredSelectionsComplete) return;
    ref
        .read(cartProvider.notifier)
        .add(
          CartLineItem(
            item: widget.item,
            size: _size,
            addOnIds: _selectedAddOnIds.toList(growable: false),
            optionValueIds: _selectedOptionValueIds.toList(growable: false),
            quantity: _quantity,
            note:
                _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
          ),
        );

    setState(() => _justAdded = true);
    _justAddedTimer?.cancel();
    // Long enough for the checkmark transition to actually be seen, then
    // back to Menu — configuration is required now, so there's no longer a
    // "maybe add another variant" reason to linger on this screen.
    _justAddedTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final menu = ref.watch(menuItemsProvider).value ?? const <MenuItem>[];
    final isFavorite = ref.watch(favoritesProvider).contains(item.id);
    final availableVariants = item.variants
        .where((variant) => variant.isAvailable)
        .toList(growable: false);
    final compatibleAddOns = menu
        .where(
          (candidate) =>
              candidate.kind == 'addon' &&
              candidate.isAvailable &&
              item.compatibleAddOnIds.contains(candidate.id),
        )
        .toList(growable: false);
    final configuredPrice = _configuredUnitPrice(menu);
    final total = Money.fromSen(configuredPrice.sen * _quantity);
    final canAdd = item.isAvailable && _requiredSelectionsComplete;
    final topControlInset = MediaQuery.paddingOf(context).top + 64;

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: _Hero(item: item),
          ),
          Positioned(
            top: topControlInset,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(0, 300 - topControlInset, 0, 130),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AidaColors.cardWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AidaColors.espresso.withValues(alpha: 0.1),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AidaType.serif(
                              size: 26,
                              color: AidaColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _PricePill(price: configuredPrice),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag(label: item.category, color: AidaColors.coffee),
                        if (!item.isAvailable)
                          const _Tag(
                            label: 'Sold out',
                            color: AidaColors.error,
                            filled: true,
                          ),
                        if (item.isStudentEligible)
                          const _Tag(
                            label: 'Student offer eligible',
                            color: AidaColors.cityRed,
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Description'),
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      style: AidaType.sans(
                        size: 14.5,
                        height: 1.5,
                        color: AidaColors.textMuted,
                      ),
                    ),
                    if (availableVariants.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionLabel('Beverage size'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (
                            var index = 0;
                            index < availableVariants.length;
                            index++
                          )
                            _VariantTile(
                              variant: availableVariants[index],
                              index: index,
                              count: availableVariants.length,
                              selected:
                                  availableVariants[index].id == _size?.id,
                              onTap:
                                  () => setState(
                                    () => _size = availableVariants[index],
                                  ),
                            ),
                        ],
                      ),
                    ],
                    for (final group in item.customizationGroups) ...[
                      const SizedBox(height: 28),
                      _SectionLabel(group.name),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final option in group.options)
                            _ChoiceTile(
                              key: ValueKey(
                                'drink_option_${group.code}_${option.code}',
                              ),
                              label: option.label,
                              priceDeltaSen: option.priceDeltaSen,
                              selected: _selectedOptionValueIds.contains(
                                option.id,
                              ),
                              enabled: option.isAvailable,
                              onTap:
                                  option.isAvailable
                                      ? () => _selectOption(group, option)
                                      : null,
                            ),
                        ],
                      ),
                    ],
                    if (compatibleAddOns.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionLabel('Customize'),
                      const SizedBox(height: 8),
                      Text(
                        'Optional extras apply only to this drink.',
                        style: AidaType.sans(
                          size: 12,
                          color: AidaColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final addOn in compatibleAddOns)
                        _AddOnRow(
                          addOn: addOn,
                          selected: _selectedAddOnIds.contains(addOn.id),
                          onChanged:
                              (selected) => setState(() {
                                if (selected) {
                                  _selectedAddOnIds.add(addOn.id);
                                } else {
                                  _selectedAddOnIds.remove(addOn.id);
                                }
                              }),
                        ),
                    ],
                    const SizedBox(height: 28),
                    const _SectionLabel('Anything else?'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      maxLength: 140,
                      style: AidaType.sans(
                        size: 13.5,
                        color: AidaColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. less ice, no sugar (optional)',
                        hintStyle: AidaType.sans(
                          size: 13.5,
                          color: AidaColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AidaColors.cream,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    if (item.volumeMl != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Volume ${item.volumeMl}ml',
                        style: AidaType.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AidaColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            child: NeumorphicControl(
              shape: NeumorphicShape.circle,
              height: 48,
              semanticsLabel: 'Back',
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AidaColors.textPrimary,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 16,
            child: NeumorphicControl(
              shape: NeumorphicShape.circle,
              height: 48,
              selected: isFavorite,
              semanticsLabel: 'Favorite',
              onTap: () => ref.read(favoritesProvider.notifier).toggle(item.id),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 22,
                color: isFavorite ? AidaColors.cityRed : AidaColors.textPrimary,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(
              available: canAdd,
              disabledLabel: item.isAvailable ? 'Choose options' : 'Sold out',
              quantity: _quantity,
              total: total,
              justAdded: _justAdded,
              onDecrement:
                  _quantity > 1 ? () => setState(() => _quantity--) : null,
              onIncrement: () => setState(() => _quantity++),
              onAddToCart: _addToCart,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ProductImage(
          imageUrl: item.imageUrl,
          category: item.category,
          borderRadius: 0,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AidaColors.espresso.withValues(alpha: 0.35),
                Colors.transparent,
                AidaColors.cream.withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.14) : Colors.transparent,
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AidaType.sans(size: 11.5, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});

  final Money price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AidaColors.latte.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        price.formatted,
        style: AidaType.sans(
          size: 15,
          weight: FontWeight.w800,
          color: AidaColors.coffee,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AidaType.sans(
      size: 13,
      weight: FontWeight.w700,
      color: AidaColors.textPrimary,
    ),
  );
}

class _VariantTile extends StatelessWidget {
  const _VariantTile({
    required this.variant,
    required this.index,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final MenuVariant variant;
  final int index;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconSize = count <= 1 ? 28.0 : 22.0 + (12.0 * index / (count - 1));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? AidaColors.latte.withValues(alpha: 0.45)
                  : AidaColors.cream,
          border: Border.all(
            color: selected ? AidaColors.coffee : AidaColors.latte,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_cafe_outlined,
              size: iconSize,
              color: selected ? AidaColors.coffee : AidaColors.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              variant.label,
              textAlign: TextAlign.center,
              style: AidaType.sans(
                size: 12,
                weight: FontWeight.w700,
                color: selected ? AidaColors.coffee : AidaColors.textMuted,
              ),
            ),
            if (variant.priceDeltaSen != 0)
              Text(
                '${variant.priceDeltaSen > 0 ? '+' : ''}${Money.fromSen(variant.priceDeltaSen).formatted}',
                style: AidaType.sans(size: 10.5, color: AidaColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    required this.priceDeltaSen,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final int priceDeltaSen;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    selected: selected,
    excludeSemantics: true,
    label: enabled ? label : '$label, unavailable',
    child: Material(
      color:
          selected
              ? AidaColors.latte.withValues(alpha: 0.52)
              : enabled
              ? AidaColors.cream
              : AidaColors.caramelTint.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minWidth: 98, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AidaColors.coffee : AidaColors.latte,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AidaColors.coffee,
                ),
                const SizedBox(height: 2),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: AidaType.sans(
                  size: 12.5,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      selected
                          ? AidaColors.coffee
                          : enabled
                          ? AidaColors.textPrimary
                          : AidaColors.textMuted,
                ),
              ),
              if (!enabled) ...[
                const SizedBox(height: 2),
                Text(
                  'Unavailable',
                  style: AidaType.sans(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: AidaColors.textMuted,
                  ),
                ),
              ] else if (priceDeltaSen != 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${priceDeltaSen > 0 ? '+' : ''}${Money.fromSen(priceDeltaSen).formatted}',
                  style: AidaType.sans(size: 10.5, color: AidaColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _AddOnRow extends StatelessWidget {
  const _AddOnRow({
    required this.addOn,
    required this.selected,
    required this.onChanged,
  });

  final MenuItem addOn;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: selected,
    label: addOn.name,
    child: InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 23,
              color: selected ? AidaColors.coffee : AidaColors.latte,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                addOn.name,
                style: AidaType.sans(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: AidaColors.textPrimary,
                ),
              ),
            ),
            Text(
              '+${addOn.price.formatted}',
              style: AidaType.sans(
                size: 12.5,
                weight: FontWeight.w700,
                color: AidaColors.coffee,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A single primary CTA — "Add to cart · total" — plus the quantity stepper.
/// Previously this was "Customize" (jump to the add-ons section further down
/// the same scrollable page) next to a separate icon-only "add" button; the
/// two competing actions are now one clean button, since the customize
/// options were already visible on the page either way.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.available,
    required this.disabledLabel,
    required this.quantity,
    required this.total,
    required this.justAdded,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
  });

  final bool available;
  final String disabledLabel;
  final int quantity;
  final Money total;

  /// True for a brief moment right after tapping — swaps the button to a
  /// checkmark confirmation instead of the old bottom SnackBar message.
  final bool justAdded;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: AidaColors.cardWhite,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AidaColors.latte),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: available ? onDecrement : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Text(
                    '$quantity',
                    style: AidaType.sans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: available ? onIncrement : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NeumorphicControl(
                height: 56,
                accent: available,
                accentColors:
                    justAdded
                        ? (AidaColors.success, AidaColors.successLight)
                        : null,
                onTap: available ? onAddToCart : null,
                // No separate semanticsLabel: the visible Text below already
                // says exactly what a screen reader should announce (name
                // plus running total) — an extra static label here would
                // just get merged into a redundant two-line announcement.
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder:
                        (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                    child:
                        justAdded
                            ? Row(
                              key: const ValueKey('added'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: AidaColors.cream,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Added',
                                  style: AidaType.sans(
                                    size: 15,
                                    weight: FontWeight.w700,
                                    color: AidaColors.cream,
                                  ),
                                ),
                              ],
                            )
                            : Text(
                              available
                                  ? 'Add to cart · ${total.formatted}'
                                  : disabledLabel,
                              key: const ValueKey('default'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AidaType.sans(
                                size: 15,
                                weight: FontWeight.w700,
                                color:
                                    available
                                        ? AidaColors.cream
                                        : AidaColors.textMuted,
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
