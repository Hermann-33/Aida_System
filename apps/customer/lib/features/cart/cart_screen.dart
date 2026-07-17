import 'dart:math';

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

/// Cash, Card, E-wallet, Student Wallet — the real methods already
/// documented in PRD §13.3. Shown here for a complete-feeling checkout, not
/// wired to any processor: this app records a payment method the same way
/// the counter POS does, it never handles a real transaction.
enum _PaymentMethod {
  cash(
    'Cash',
    'Pay at the pickup counter',
    Icons.payments_rounded,
    AidaColors.success,
  ),
  card(
    'Card',
    'Debit or credit card',
    Icons.credit_card_rounded,
    AidaColors.coffee,
  ),
  eWallet(
    'E-wallet',
    'Scan and pay by QR',
    Icons.qr_code_rounded,
    AidaColors.espresso,
  ),
  studentWallet(
    'Student Wallet',
    'Use your student balance',
    Icons.school_rounded,
    AidaColors.cityRed,
  );

  const _PaymentMethod(this.label, this.subtitle, this.icon, this.accent);
  final String label;
  final String subtitle;
  final IconData icon;

  /// A distinct color per method, so the row reads at a glance the way a
  /// real payment sheet's brand marks do — without us faking logos for
  /// processors (Apple Pay, Visa, PayPal) this app doesn't integrate with.
  final Color accent;
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  void _openPaymentSheet(Money total) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentMethodSheet(total: total, onPay: _placeOrder),
    );
  }

  void _placeOrder(_PaymentMethod method) {
    // Order-number generation only, not an order-management system — a mock
    // ID is all a screen with no backend behind it needs. See cart design
    // spec §2.
    final orderNumber = (100000 + Random().nextInt(900000)).toString();

    final cart = ref.read(cartProvider);
    final menu = ref.read(menuItemsProvider).value ?? const <MenuItem>[];
    final subtotal = cart.subtotal(
      (line) => addOnTotalFor(line.addOnIds, menu),
    );

    // Recorded before the cart clears, so My Orders has a real receipt to
    // show later — see the PastOrder doc for why status is always "ready".
    ref
        .read(orderHistoryProvider.notifier)
        .add(
          PastOrder(
            orderNumber: orderNumber,
            placedAt: DateTime.now(),
            lineItems: cart.lineItems,
            subtotal: subtotal,
            paymentMethodLabel: method.label,
          ),
        );

    // Cleared here, at the moment the order is placed — not on the
    // confirmation screen's "Back to Menu" — so the cart is correctly empty
    // regardless of how the customer navigates away from confirmation
    // (the button, or the device back gesture).
    ref.read(cartProvider.notifier).clear();

    Navigator.of(context)
      ..pop() // close the payment sheet
      ..push(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(orderNumber: orderNumber),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder:
                            (_, i) => _CartLineCard(
                              index: i,
                              line: cart.lineItems[i],
                              menu: menu,
                            ),
                      ),
            ),
            if (!cart.isEmpty)
              _CheckoutBar(
                subtotal: subtotal,
                onCheckout: () => _openPaymentSheet(subtotal),
              ),
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

/// One line item as a self-contained card — thumbnail, name, price, and a
/// quantity pill, with size/add-on/note details folded in as captions
/// underneath the price rather than a separate row, since this app's real
/// ordering options (unlike a plain candy-shop cart) can't just be dropped.
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

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AidaColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AidaColors.espresso.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(
                imageUrl: line.item.imageUrl,
                category: line.item.category,
                size: 56,
                borderRadius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.item.name,
                      style: AidaType.sans(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lineTotal.formatted,
                      style: AidaType.sans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AidaColors.coffee,
                      ),
                    ),
                    if (configSummary != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        configSummary,
                        style: AidaType.sans(
                          size: 12,
                          color: AidaColors.textMuted,
                        ),
                      ),
                    ],
                    if (line.note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '"${line.note}"',
                        style: AidaType.sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AidaColors.coffee,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _QuantityPill(
                    quantity: line.quantity,
                    onDecrement:
                        () => notifier.setQuantity(index, line.quantity - 1),
                    onIncrement:
                        () => notifier.setQuantity(index, line.quantity + 1),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => notifier.removeAt(index),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: AidaColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
            width: 26,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AidaType.sans(
                size: 13,
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
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 15, color: AidaColors.textPrimary),
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

/// Subtotal/total summary and the button that opens [_PaymentMethodSheet].
/// Payment method selection lives in its own sheet rather than stacked in
/// here — cramming both into one panel is what the previous design got
/// right feedback about.
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
                'Subtotal',
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
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Total',
                style: AidaType.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AidaColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                subtotal.formatted,
                style: AidaType.sans(
                  size: 19,
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
                'Checkout',
                style: AidaType.sans(size: 15, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment method picker, shown as its own modal sheet triggered from
/// [_CheckoutBar]'s Checkout button — separated from the cart screen so
/// each step only asks the customer for one thing at a time.
class _PaymentMethodSheet extends StatefulWidget {
  const _PaymentMethodSheet({required this.total, required this.onPay});

  final Money total;
  final ValueChanged<_PaymentMethod> onPay;

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  _PaymentMethod _method = _PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AidaColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
              'Payment method',
              style: AidaType.serif(size: 19, color: AidaColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              "Choose how you'd like to pay",
              style: AidaType.sans(size: 13, color: AidaColors.textMuted),
            ),
            const SizedBox(height: 18),
            for (final m in _PaymentMethod.values) ...[
              _MethodRow(
                method: m,
                selected: m == _method,
                onTap: () => setState(() => _method = m),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Total',
                  style: AidaType.sans(size: 13, color: AidaColors.textMuted),
                ),
                const Spacer(),
                Text(
                  widget.total.formatted,
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
                onPressed: () => widget.onPay(_method),
                style: FilledButton.styleFrom(
                  backgroundColor: AidaColors.coffee,
                  foregroundColor: AidaColors.cream,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Pay ${widget.total.formatted}',
                  style: AidaType.sans(size: 15, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? AidaColors.coffee.withValues(alpha: 0.06)
                    : AidaColors.cream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected
                      ? AidaColors.coffee
                      : AidaColors.latte.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: method.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(method.icon, size: 20, color: method.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: AidaType.sans(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                    Text(
                      method.subtitle,
                      style: AidaType.sans(
                        size: 11.5,
                        color: AidaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 22,
                color: selected ? AidaColors.coffee : AidaColors.latte,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
