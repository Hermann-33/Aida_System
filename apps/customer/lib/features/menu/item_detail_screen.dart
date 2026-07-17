import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/neumorphic_control.dart';
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
  final _scrollController = ScrollController();
  final _customizeKey = GlobalKey();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCustomize() {
    final ctx = _customizeKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _addToCart(List<MenuItem> menu) {
    final line = CartLineItem(
      item: widget.item,
      size: _size,
      addOnIds: _selectedAddOnIds.toList(),
      quantity: _quantity,
      note:
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
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
    final isFavorite = ref.watch(favoritesProvider).contains(item.id);

    final compatibleAddOns =
        menu.where((m) => item.compatibleAddOnIds.contains(m.id)).toList();

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
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 300),
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.rating != null) ...[
                              _RatingBadge(rating: item.rating!),
                              const SizedBox(height: 12),
                            ],
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
                                _PricePill(price: item.price),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Tag(
                                  label: item.category,
                                  color: AidaColors.coffee,
                                ),
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
                            const SizedBox(height: 22),
                            _SectionLabel('Description'),
                            const SizedBox(height: 10),
                            _ExpandableDescription(text: item.description),
                            if (_size != null) ...[
                              const SizedBox(height: 28),
                              _SectionLabel('Beverage size'),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  for (final s in ItemSize.values) ...[
                                    Expanded(
                                      child: _SizeCupTile(
                                        size: s,
                                        selected: s == _size,
                                        iced: item.category == 'Iced Drinks',
                                        onTap: () => setState(() => _size = s),
                                      ),
                                    ),
                                    if (s != ItemSize.values.last)
                                      const SizedBox(width: 12),
                                  ],
                                ],
                              ),
                            ],
                            if (compatibleAddOns.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              KeyedSubtree(
                                key: _customizeKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel('Customize'),
                                    const SizedBox(height: 8),
                                    for (final addOn in compatibleAddOns)
                                      _AddOnRow(
                                        addOn: addOn,
                                        selected: _selectedAddOnIds.contains(
                                          addOn.id,
                                        ),
                                        onChanged:
                                            (v) => setState(() {
                                              if (v) {
                                                _selectedAddOnIds.add(addOn.id);
                                              } else {
                                                _selectedAddOnIds.remove(
                                                  addOn.id,
                                                );
                                              }
                                            }),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            KeyedSubtree(
                              key:
                                  compatibleAddOns.isEmpty
                                      ? _customizeKey
                                      : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                      hintText:
                                          'e.g. less ice, no sugar (optional)',
                                      hintStyle: AidaType.sans(
                                        size: 13.5,
                                        color: AidaColors.textMuted,
                                      ),
                                      filled: true,
                                      fillColor: AidaColors.cream,
                                      contentPadding: const EdgeInsets.all(14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                        borderSide: BorderSide(
                                          color: AidaColors.latte.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                        borderSide: BorderSide(
                                          color: AidaColors.latte.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
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
                            if (item.volumeMl != null) ...[
                              const SizedBox(height: 20),
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
                ),
              ],
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
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
              available: item.isAvailable,
              quantity: _quantity,
              onCustomize: _scrollToCustomize,
              onDecrement:
                  _quantity > 1 ? () => setState(() => _quantity--) : null,
              onIncrement: () => setState(() => _quantity++),
              onAddToCart: () => _addToCart(menu),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo + scrim only — no controls. The back/favorite buttons used to live
/// here, inside this Positioned's own Stack, but that put them *behind* the
/// scrollable content sheet in hit-test order: the sheet is a
/// `Positioned.fill`, so its `SingleChildScrollView` claims the full screen
/// for drag gestures — including the top area where nothing of the sheet is
/// actually visible yet — and silently absorbed every tap meant for these
/// buttons. They now live directly in the outer Stack, placed *after* the
/// scrollable so they're on top for both paint and hit-testing.
class _Hero extends StatelessWidget {
  const _Hero({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ProductImage(imageUrl: item.imageUrl, category: item.category, borderRadius: 0),
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
              stops: const [0.0, 0.45, 1.0],
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

/// Small pill showing the star rating, positioned above the item name.
///
/// TEST DATA ONLY (see [MenuItem.rating]) — there is no review system behind
/// it. It renders here purely so the detail page can be visually reviewed
/// against a design reference that includes one; it must not ship to a real
/// customer without an actual review feature backing it.
///
/// Deliberately not gold: [AidaColors.rewardGold] is documented as reserved
/// for points/stamps/loyalty, and a star rating isn't that — reusing it here
/// would blur the one signal it's meant to carry.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AidaColors.latte.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: AidaColors.coffee),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: AidaType.sans(
              size: 12.5,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Price shown as a soft pill next to the item name, matching the reference.
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

/// Description text clamped to 2 lines with an inline "Read more" / "Read
/// less" trigger appended to the end of the same line — matching the
/// reference, rather than a toggle on its own row below. The cut point is
/// found by measuring text width via [TextPainter] (binary search over the
/// character offset) so the trigger never gets pushed onto a third line.
class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});

  final String text;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const _maxLines = 2;
  static const _moreLabel = 'Read more';
  static const _lessLabel = ' Read less';

  bool _expanded = false;
  late final TapGestureRecognizer _tapRecognizer;

  @override
  void initState() {
    super.initState();
    _tapRecognizer =
        TapGestureRecognizer()
          ..onTap = () => setState(() => _expanded = !_expanded);
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = AidaType.sans(
      size: 14.5,
      height: 1.5,
      color: AidaColors.textMuted,
    );
    final triggerStyle = AidaType.sans(
      size: 14.5,
      height: 1.5,
      weight: FontWeight.w700,
      color: AidaColors.textPrimary,
    );

    if (_expanded) {
      return RichText(
        text: TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: widget.text),
            TextSpan(
              text: _lessLabel,
              style: triggerStyle,
              recognizer: _tapRecognizer,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        final fullPainter = TextPainter(
          text: TextSpan(text: widget.text, style: bodyStyle),
          maxLines: _maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxWidth);

        if (!fullPainter.didExceedMaxLines) {
          return Text(widget.text, style: bodyStyle);
        }

        // Binary search the longest prefix of the text that still fits
        // within _maxLines once "… Read more" is appended to it.
        var low = 0;
        var high = widget.text.length;
        var bestFit = '';
        while (low <= high) {
          final mid = (low + high) ~/ 2;
          final candidate = widget.text.substring(0, mid).trimRight();
          final painter = TextPainter(
            text: TextSpan(
              children: [
                TextSpan(text: '$candidate… ', style: bodyStyle),
                TextSpan(text: _moreLabel, style: triggerStyle),
              ],
            ),
            maxLines: _maxLines,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: maxWidth);

          if (painter.didExceedMaxLines) {
            high = mid - 1;
          } else {
            bestFit = candidate;
            low = mid + 1;
          }
        }

        return RichText(
          text: TextSpan(
            style: bodyStyle,
            children: [
              TextSpan(text: '$bestFit… '),
              TextSpan(
                text: _moreLabel,
                style: triggerStyle,
                recognizer: _tapRecognizer,
              ),
            ],
          ),
        );
      },
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

class _SizeCupTile extends StatelessWidget {
  const _SizeCupTile({
    required this.size,
    required this.selected,
    required this.onTap,
    this.iced = false,
  });

  final ItemSize size;
  final bool selected;
  final VoidCallback onTap;
  final bool iced;

  static double _iconSize(ItemSize size) => switch (size) {
    ItemSize.small => 22,
    ItemSize.medium => 28,
    ItemSize.large => 34,
  };

  @override
  Widget build(BuildContext context) {
    // The label below the cup is part of this control's tap target too —
    // not just the circle — so tapping "Large" selects Large the same way
    // tapping the Add-ons row selects an add-on anywhere on its row.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          NeumorphicControl(
            shape: NeumorphicShape.circle,
            height: 68,
            highContrast: true,
            selected: selected,
            onTap: onTap,
            semanticsLabel: size.label,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  iced ? Icons.local_drink_outlined : Icons.coffee_outlined,
                  size: _iconSize(size),
                  color: selected ? AidaColors.coffee : AidaColors.textMuted,
                ),
                if (selected)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AidaColors.coffee,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AidaColors.cream,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            size.label,
            style: AidaType.sans(
              size: 12,
              weight: FontWeight.w700,
              color: selected ? AidaColors.coffee : AidaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
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

/// Reference-style action row: Customize · QTY · bag — neumorphic like nav.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.available,
    required this.quantity,
    required this.onCustomize,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
  });

  final bool available;
  final int quantity;
  final VoidCallback onCustomize;
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
            Expanded(
              flex: 5,
              child: NeumorphicControl(
                height: 56,
                highContrast: true,
                onTap: available ? onCustomize : null,
                semanticsLabel: 'Customize',
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Customize',
                        style: AidaType.sans(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AidaColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: AidaColors.textMuted.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _QtyStepperBar(
              quantity: quantity,
              enabled: available,
              onDecrement: onDecrement,
              onIncrement: onIncrement,
            ),
            const SizedBox(width: 10),
            NeumorphicControl(
              shape: NeumorphicShape.circle,
              height: 56,
              accent: available,
              onTap: available ? onAddToCart : null,
              semanticsLabel: 'Add to order',
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 22,
                color: available ? AidaColors.cream : AidaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// QTY pill with visible − and + (reference flow, neumorphic shell).
class _QtyStepperBar extends StatelessWidget {
  const _QtyStepperBar({
    required this.quantity,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final bool enabled;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final canDec = enabled && onDecrement != null;

    return NeumorphicControl(
      height: 56,
      width: 148,
      highContrast: true,
      passive: true,
      semanticsLabel: 'Quantity',
      child: Row(
        children: [
          _QtyIconHit(
            icon: Icons.remove_rounded,
            enabled: canDec,
            onTap: onDecrement,
          ),
          Container(
            width: 1,
            height: 26,
            color: AidaColors.coffee.withValues(alpha: 0.15),
          ),
          Expanded(
            child: Text(
              'QTY | $quantity',
              textAlign: TextAlign.center,
              style: AidaType.sans(
                size: 12.5,
                weight: FontWeight.w800,
                color: AidaColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 26,
            color: AidaColors.coffee.withValues(alpha: 0.15),
          ),
          _QtyIconHit(
            icon: Icons.add_rounded,
            enabled: enabled,
            onTap: enabled ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _QtyIconHit extends StatefulWidget {
  const _QtyIconHit({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_QtyIconHit> createState() => _QtyIconHitState();
}

class _QtyIconHitState extends State<_QtyIconHit> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            widget.icon,
            size: 20,
            color:
                !widget.enabled
                    ? AidaColors.textMuted.withValues(alpha: 0.35)
                    : _pressed
                    ? AidaColors.coffee
                    : AidaColors.espresso,
          ),
        ),
      ),
    );
  }
}
