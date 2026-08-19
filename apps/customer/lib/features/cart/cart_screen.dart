import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/model/cart.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/money.dart';
import '../../domain/model/order.dart';
import 'order_confirmation_screen.dart';
import 'order_checkout_sheet.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  void _openCheckoutSheet() {
    final cart = ref.read(cartProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => OrderCheckoutSheet(
            repository: ref.read(orderRepositoryProvider),
            items: cart.toOrderSelection(),
            onPlaced: _orderPlaced,
          ),
    );
  }

  void _orderPlaced(OrderSnapshot order) {
    ref.read(cartProvider.notifier).clear();
    ref.invalidate(orderHistoryProvider);

    Navigator.of(context)
      ..pop()
      ..push(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final menuAsync = ref.watch(menuItemsProvider);
    final menu = menuAsync.value ?? const <MenuItem>[];

    final subtotal = cart.subtotal(
      (line) => addOnTotalFor(line.addOnIds, menu),
    );

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                  Text(
                    'My Cart',
                    style: AidaType.serif(
                      size: 22,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                  if (!cart.isEmpty) ...[
                    const SizedBox(width: 10),
                    _CountBadge(count: cart.itemCount),
                  ],
                ],
              ),
            ),
            Expanded(
              child:
                  cart.isEmpty
                      ? const _EmptyCart()
                      : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                        itemCount: cart.lineItems.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              height: 17,
                              color: AidaColors.latte.withValues(alpha: 0.5),
                            ),
                        itemBuilder:
                            (_, i) => _CartLineCard(
                              index: i,
                              line: cart.lineItems[i],
                              menu: menu,
                            ),
                      ),
            ),
            if (!cart.isEmpty)
              _CheckoutBar(subtotal: subtotal, onCheckout: _openCheckoutSheet),
          ],
        ),
      ),
    );
  }
}

/// "N items" pill next to the title, matching the floating cart bar's own
/// singular/plural wording so the count never reads differently in two
/// places.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AidaColors.latte.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        count == 1 ? '1 item' : '$count items',
        style: AidaType.sans(
          size: 12,
          weight: FontWeight.w700,
          color: AidaColors.coffee,
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: AidaColors.latte,
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: AidaType.sans(
                size: 15,
                weight: FontWeight.w700,
                color: AidaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add something from the menu to get started.',
              textAlign: TextAlign.center,
              style: AidaType.sans(size: 12.5, color: AidaColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line item — thumbnail, name, price, and a quantity pill, sitting flat
/// on the page (no card box) with size/add-on/note details folded in as
/// captions underneath the price rather than a separate row, since this
/// app's real ordering options (unlike a plain candy-shop cart) can't just
/// be dropped. Swipe left to remove — see [Dismissible] below.
class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    required this.index,
    required this.line,
    required this.menu,
  });

  final int index;
  final CartLineItem line;
  final List<MenuItem> menu;

  @override
  Widget build(BuildContext context) {
    final addOns = addOnTotalFor(line.addOnIds, menu);
    final lineTotal = line.lineTotal(addOns);
    final configSummary = line.configSummary(menu);

    return Consumer(
      builder: (context, ref, _) {
        final notifier = ref.read(cartProvider.notifier);

        return Dismissible(
          // Identity, not position: the index shifts under a line once any
          // earlier line is removed, but the item/size/add-ons/note tuple
          // (the same identity `sameConfigurationAs` uses) doesn't.
          key: ValueKey(
            '${line.item.id}_${line.size?.id}_${line.addOnIds.join(',')}_${line.note}',
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => notifier.removeAt(index),
          background: const _DeleteReveal(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProductImage(
                  imageUrl: line.item.imageUrl,
                  category: line.item.category,
                  size: 72,
                  borderRadius: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.item.name,
                        style: AidaType.sans(
                          size: 16.5,
                          weight: FontWeight.w700,
                          color: AidaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lineTotal.formatted,
                        style: AidaType.sans(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: AidaColors.coffee,
                        ),
                      ),
                      if (configSummary != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          configSummary,
                          style: AidaType.sans(
                            size: 13,
                            color: AidaColors.textMuted,
                          ),
                        ),
                      ],
                      if (line.note != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '"${line.note}"',
                          style: AidaType.sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AidaColors.coffee,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _QuantityPill(
                  quantity: line.quantity,
                  onDecrement:
                      () => notifier.setQuantity(index, line.quantity - 1),
                  onIncrement:
                      () => notifier.setQuantity(index, line.quantity + 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Revealed as a line is swiped left — soft, not a jarring solid-red bar, to
/// match the flat/smooth style the rest of the row already carries.
class _DeleteReveal extends StatelessWidget {
  const _DeleteReveal();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AidaColors.error.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AidaColors.error,
          size: 20,
        ),
      ),
    );
  }
}

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AidaColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AidaColors.latte.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(icon: Icons.remove_rounded, onTap: onDecrement),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AidaType.sans(
                size: 14.5,
                weight: FontWeight.w700,
                color: AidaColors.textPrimary,
              ),
            ),
          ),
          _QtyButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AidaColors.cardWhite,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 17, color: AidaColors.textPrimary),
        ),
      ),
    );
  }
}

/// Promo code affordance shown in the reference. There is no promo/coupon
/// system in this app — tapping it says so plainly rather than doing
/// nothing, which would read as a bug rather than an unbuilt feature.
class _PromoRow extends StatelessWidget {
  const _PromoRow();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AidaColors.latte.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () =>
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AidaColors.espresso,
                      content: Text(
                        "Promo codes aren't available in this demo yet",
                        style: AidaType.sans(size: 13, color: AidaColors.cream),
                      ),
                    ),
                  ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.sell_outlined,
                size: 18,
                color: AidaColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Do you have any promo code?',
                  style: AidaType.sans(size: 13, color: AidaColors.textMuted),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AidaColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Local catalogue estimate and entry to the authoritative quote step.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.subtotal, required this.onCheckout});

  final Money subtotal;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PromoRow(),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Estimated subtotal',
                style: AidaType.sans(size: 13, color: AidaColors.textMuted),
              ),
              const Spacer(),
              Text(
                subtotal.formatted,
                style: AidaType.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AidaColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: AidaColors.coffee,
                foregroundColor: AidaColors.cream,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Review order',
                style: AidaType.sans(size: 15, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
