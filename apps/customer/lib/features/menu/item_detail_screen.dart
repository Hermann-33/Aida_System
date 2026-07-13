import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/model/cart.dart';
import '../../domain/model/item_size.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/money.dart';

/// Opens [ItemDetailScreen] for [item]. Shared by every place an item can be
/// tapped (Home's grid, Menu's list), so navigation stays in one place rather
/// than each caller building its own MaterialPageRoute.
void openItemDetail(BuildContext context, MenuItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
}

/// A menu item's detail page, with real ordering controls. CUS-09; ordering
/// controls per the cart design spec (2026-07-13), which reopened the
/// browse-only v1 boundary after the client asked for this three times.
///
/// Checkout has no backend behind it — see the spec §2. This screen adds a
/// configured [CartLineItem] to the in-memory [cartProvider]; nothing is
/// persisted or sent anywhere.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final MenuItem item;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  ItemSize? _size;
  final _selectedAddOnIds = <String>{};
  int _quantity = 1;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (ItemSize.appliesTo(widget.item.category)) {
      _size = ItemSize.medium;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _addToCart(List<MenuItem> menu) {
    final line = CartLineItem(
      item: widget.item,
      size: _size,
      addOnIds: _selectedAddOnIds.toList(),
      quantity: _quantity,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    ref.read(cartProvider.notifier).add(line);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AidaColors.espresso,
          content: Text(
            'Added ${widget.item.name} to your order',
            style: AidaType.sans(size: 13, color: AidaColors.cream),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final menuAsync = ref.watch(menuItemsProvider);
    final menu = menuAsync.value ?? const <MenuItem>[];

    final compatibleAddOns =
        menu.where((m) => item.compatibleAddOnIds.contains(m.id)).toList();

    final addOnTotal = addOnTotalFor(_selectedAddOnIds.toList(), menu);
    final unitPrice = Money.fromSen(
      item.price.sen + (_size?.delta.sen ?? 0) + addOnTotal.sen,
    );
    final totalPrice = Money.fromSen(unitPrice.sen * _quantity);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Hero(item: item),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                              Text(
                                item.price.formatted,
                                style: AidaType.sans(
                                  size: 20,
                                  weight: FontWeight.w800,
                                  color: AidaColors.coffee,
                                ),
                              ),
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
                              if (item.bonusPoints != null)
                                _Tag(
                                  label: '+${item.bonusPoints} pts',
                                  color: AidaColors.rewardGold,
                                  filled: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            item.description,
                            style: AidaType.sans(
                              size: 14.5,
                              height: 1.5,
                              color: AidaColors.textMuted,
                            ),
                          ),

                          if (_size != null) ...[
                            const SizedBox(height: 28),
                            _SectionLabel('Size'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                for (final s in ItemSize.values) ...[
                                  _SizePill(
                                    size: s,
                                    selected: s == _size,
                                    onTap: () => setState(() => _size = s),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ],
                            ),
                          ],

                          if (compatibleAddOns.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _SectionLabel('Add-ons'),
                            const SizedBox(height: 4),
                            for (final addOn in compatibleAddOns)
                              _AddOnRow(
                                addOn: addOn,
                                selected: _selectedAddOnIds.contains(addOn.id),
                                onChanged:
                                    (v) => setState(() {
                                      if (v) {
                                        _selectedAddOnIds.add(addOn.id);
                                      } else {
                                        _selectedAddOnIds.remove(addOn.id);
                                      }
                                    }),
                              ),
                          ],

                          const SizedBox(height: 28),
                          _SectionLabel('Anything else?'),
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
                              fillColor: AidaColors.cardWhite,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AidaColors.latte.withValues(alpha: 0.8),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AidaColors.latte.withValues(alpha: 0.8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AidaColors.coffee,
                                  width: 1.4,
                                ),
                              ),
                              counterStyle: AidaType.sans(
                                size: 10.5,
                                color: AidaColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomBar(
              available: item.isAvailable,
              quantity: _quantity,
              totalPrice: totalPrice,
              onDecrement: _quantity > 1 ? () => setState(() => _quantity--) : null,
              onIncrement: () => setState(() => _quantity++),
              onAddToCart: () => _addToCart(menu),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final favorites = ref.watch(favoritesProvider);
        final isFavorite = favorites.contains(item.id);

        return Stack(
          children: [
            // Full-width photo, not a circular cutout — the photo is the hero
            // here, so it should fill the space rather than float inside it.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
              child: SizedBox(
                height: 320,
                width: double.infinity,
                child: ProductImage(
                  imageUrl: item.imageUrl,
                  category: item.category,
                  borderRadius: 0,
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _RoundIconButton(
                icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: isFavorite ? AidaColors.cityRed : null,
                onTap: () => ref.read(favoritesProvider.notifier).toggle(item.id),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.iconColor});

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AidaColors.cardWhite.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: iconColor ?? AidaColors.textPrimary),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;

  /// Filled tags (sold-out, bonus points) carry their own meaning at a
  /// glance; outlined tags (category, student eligibility) are informational
  /// rather than states, so they stay quiet.
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AidaType.sans(
        size: 13,
        weight: FontWeight.w700,
        color: AidaColors.textPrimary,
      ),
    );
  }
}

class _SizePill extends StatelessWidget {
  const _SizePill({required this.size, required this.selected, required this.onTap});

  final ItemSize size;
  final bool selected;
  final VoidCallback onTap;

  /// e.g. "+RM 1.50", "−RM 1.00", or null for no price change (Medium).
  static String? _deltaLabel(Money delta) {
    if (delta.sen == 0) return null;
    final sign = delta.sen > 0 ? '+' : '−';
    return '$sign${Money.fromSen(delta.sen.abs()).formatted}';
  }

  @override
  Widget build(BuildContext context) {
    final deltaLabel = _deltaLabel(size.delta);

    return Material(
      color: selected ? AidaColors.espresso : AidaColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? AidaColors.espresso
                      : AidaColors.latte.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                size.label,
                style: AidaType.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: selected ? AidaColors.cream : AidaColors.textPrimary,
                ),
              ),
              if (deltaLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  deltaLabel,
                  style: AidaType.sans(
                    size: 10,
                    color: selected ? AidaColors.latte : AidaColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOnRow extends StatelessWidget {
  const _AddOnRow({required this.addOn, required this.selected, required this.onChanged});

  final MenuItem addOn;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 22,
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
              style: AidaType.sans(size: 13, color: AidaColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quantity stepper and Add to Cart, pinned to the bottom of the screen —
/// not scrolling with the content, matching the reference and every
/// ordering app this pattern is borrowed from.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.available,
    required this.quantity,
    required this.totalPrice,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
  });

  final bool available;
  final int quantity;
  final Money totalPrice;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: AidaColors.cream,
          boxShadow: [
            BoxShadow(
              color: AidaColors.espresso.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (available) ...[
              _StepperButton(icon: Icons.remove_rounded, onTap: onDecrement),
              SizedBox(
                width: 32,
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
              _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: FilledButton(
                onPressed: available ? onAddToCart : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AidaColors.coffee,
                  foregroundColor: AidaColors.cream,
                  disabledBackgroundColor: AidaColors.latte,
                  disabledForegroundColor: AidaColors.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Text(
                  available ? 'Add to Order · ${totalPrice.formatted}' : 'Sold Out',
                  style: AidaType.sans(size: 14.5, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: AidaColors.cardWhite,
      shape: const CircleBorder(side: BorderSide(color: AidaColors.latte)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AidaColors.textPrimary : AidaColors.latte,
          ),
        ),
      ),
    );
  }
}
