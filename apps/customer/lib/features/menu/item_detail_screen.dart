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
  final _noteController = TextEditingController();
  int _quantity = 1;

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
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ),
        );

    // Adding an item completes this configuration task. Returning immediately
    // to Menu makes configuring several different drinks much faster and avoids
    // accidental duplicate adds from a stale detail screen.
    Navigator.of(context).pop();
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

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: _Hero(item: item),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 285, 0, 126),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AidaColors.cardWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AidaColors.espresso.withValues(alpha: 0.1),
                      blurRadius: 28,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
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
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      style: AidaType.sans(
                        size: 14,
                        height: 1.45,
                        color: AidaColors.textMuted,
                      ),
                    ),
                    if (availableVariants.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      const _SectionLabel('Size'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final variant in availableVariants)
                            _ChoiceTile(
                              label: variant.label,
                              priceDeltaSen: variant.priceDeltaSen,
                              selected: variant.id == _size?.id,
                              onTap: () => setState(() => _size = variant),
                            ),
                        ],
                      ),
                    ],
                    for (final group in item.customizationGroups) ...[
                      const SizedBox(height: 26),
                      _SectionLabel(group.name),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final option in group.availableOptions)
                            _ChoiceTile(
                              key: ValueKey(
                                'drink_option_${group.code}_${option.code}',
                              ),
                              label: option.label,
                              priceDeltaSen: option.priceDeltaSen,
                              selected: _selectedOptionValueIds.contains(
                                option.id,
                              ),
                              onTap: () => _selectOption(group, option),
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
                          onChanged: (selected) => setState(() {
                            if (selected) {
                              _selectedAddOnIds.add(addOn.id);
                            } else {
                              _selectedAddOnIds.remove(addOn.id);
                            }
                          }),
                        ),
                    ],
                    const SizedBox(height: 26),
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
                        hintText: 'e.g. no foam (optional)',
                        hintStyle: AidaType.sans(
                          size: 13.5,
                          color: AidaColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AidaColors.cream,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
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
              available: item.isAvailable && _requiredSelectionsComplete,
              quantity: _quantity,
              total: total,
              onDecrement: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
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
  Widget build(BuildContext context) => Stack(
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
              AidaColors.espresso.withValues(alpha: 0.32),
              Colors.transparent,
              AidaColors.cream.withValues(alpha: 0.12),
            ],
          ),
        ),
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AidaType.sans(
      size: 15,
      weight: FontWeight.w800,
      color: AidaColors.textPrimary,
    ),
  );
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});

  final Money price;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: AidaColors.latte.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      price.formatted,
      style: AidaType.sans(
        size: 14,
        weight: FontWeight.w800,
        color: AidaColors.coffee,
      ),
    ),
  );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    required this.priceDeltaSen,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int priceDeltaSen;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? AidaColors.latte.withValues(alpha: 0.52)
        : AidaColors.cream,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minWidth: 98),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AidaColors.coffee : AidaColors.latte,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: AidaType.sans(
                size: 12.5,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AidaColors.coffee : AidaColors.textPrimary,
              ),
            ),
            if (priceDeltaSen != 0) ...[
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
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!selected),
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
  );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.available,
    required this.quantity,
    required this.total,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
  });

  final bool available;
  final int quantity;
  final Money total;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          _RoundControl(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 42,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AidaType.sans(
                size: 15,
                weight: FontWeight.w800,
                color: AidaColors.textPrimary,
              ),
            ),
          ),
          _RoundControl(icon: Icons.add_rounded, onTap: onIncrement),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton(
              onPressed: available ? onAddToCart : null,
              style: FilledButton.styleFrom(
                backgroundColor: AidaColors.coffee,
                foregroundColor: AidaColors.cream,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                available ? 'Add to cart · ${total.formatted}' : 'Unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AidaType.sans(size: 14, weight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, size: 20),
    color: AidaColors.coffee,
    disabledColor: AidaColors.latte,
    style: IconButton.styleFrom(
      backgroundColor: AidaColors.cream,
      minimumSize: const Size(42, 42),
      side: BorderSide(color: AidaColors.latte),
    ),
  );
}
