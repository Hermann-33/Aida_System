import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/cart.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/money.dart';
import 'order_confirmation_screen.dart';

/// Cash, Card, E-wallet, Student Wallet — the real methods already
/// documented in PRD §13.3. Shown here for a complete-feeling checkout, not
/// wired to any processor: this app records a payment method the same way
/// the counter POS does, it never handles a real transaction.
enum _PaymentMethod {
  cash('Cash', Icons.payments_rounded),
  card('Card', Icons.credit_card_rounded),
  eWallet('E-wallet', Icons.qr_code_rounded),
  studentWallet('Student Wallet', Icons.school_rounded);

  const _PaymentMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  _PaymentMethod _method = _PaymentMethod.cash;

  void _placeOrder() {
    // Order-number generation only, not an order-management system — a mock
    // ID is all a screen with no backend behind it needs. See cart design
    // spec §2.
    final orderNumber = (100000 + Random().nextInt(900000)).toString();

    // Cleared here, at the moment the order is placed — not on the
    // confirmation screen's "Back to Menu" — so the cart is correctly empty
    // regardless of how the customer navigates away from confirmation
    // (the button, or the device back gesture).
    ref.read(cartProvider.notifier).clear();

    Navigator.of(context).push(
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

    final subtotal = cart.subtotal((line) => addOnTotalFor(line.addOnIds, menu));

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
                    'Your Order',
                    style: AidaType.serif(size: 22, color: AidaColors.textPrimary),
                  ),
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
                            (_, __) => const Divider(height: 24, color: AidaColors.latte),
                        itemBuilder:
                            (_, i) => _CartLineTile(
                              index: i,
                              line: cart.lineItems[i],
                              menu: menu,
                            ),
                      ),
            ),
            if (!cart.isEmpty)
              _CheckoutBar(
                subtotal: subtotal,
                method: _method,
                onMethodChanged: (m) => setState(() => _method = m),
                onPlaceOrder: _placeOrder,
              ),
          ],
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
            const Icon(Icons.shopping_bag_outlined, size: 48, color: AidaColors.latte),
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

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.index, required this.line, required this.menu});

  final int index;
  final CartLineItem line;
  final List<MenuItem> menu;

  String? get _configSummary {
    final parts = <String>[];
    if (line.size != null) parts.add(line.size!.label);
    if (line.addOnIds.isNotEmpty) {
      final names = line.addOnIds
          .map((id) {
            for (final m in menu) {
              if (m.id == id) return m.name;
            }
            return null;
          })
          .whereType<String>()
          .join(', ');
      if (names.isNotEmpty) parts.add(names);
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final addOns = addOnTotalFor(line.addOnIds, menu);

    return Consumer(
      builder: (context, ref, _) {
        final notifier = ref.read(cartProvider.notifier);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  if (_configSummary != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _configSummary!,
                      style: AidaType.sans(size: 12, color: AidaColors.textMuted),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove_rounded,
                        onTap: () => notifier.setQuantity(index, line.quantity - 1),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${line.quantity}',
                          textAlign: TextAlign.center,
                          style: AidaType.sans(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AidaColors.textPrimary,
                          ),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add_rounded,
                        onTap: () => notifier.setQuantity(index, line.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  line.lineTotal(addOns).formatted,
                  style: AidaType.sans(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AidaColors.coffee,
                  ),
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
        );
      },
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
      shape: const CircleBorder(side: BorderSide(color: AidaColors.latte)),
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

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.subtotal,
    required this.method,
    required this.onMethodChanged,
    required this.onPlaceOrder,
  });

  final Money subtotal;
  final _PaymentMethod method;
  final ValueChanged<_PaymentMethod> onMethodChanged;
  final VoidCallback onPlaceOrder;

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
          Text(
            'Payment method',
            style: AidaType.sans(
              size: 11.5,
              weight: FontWeight.w700,
              color: AidaColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _PaymentMethod.values)
                _MethodChip(
                  method: m,
                  selected: m == method,
                  onTap: () => onMethodChanged(m),
                ),
            ],
          ),
          const SizedBox(height: 18),
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
                  size: 18,
                  weight: FontWeight.w800,
                  color: AidaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPlaceOrder,
              style: FilledButton.styleFrom(
                backgroundColor: AidaColors.coffee,
                foregroundColor: AidaColors.cream,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                'Place Order',
                style: AidaType.sans(size: 15, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method, required this.selected, required this.onTap});

  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AidaColors.coffee : AidaColors.cream,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                method.icon,
                size: 15,
                color: selected ? AidaColors.cream : AidaColors.coffee,
              ),
              const SizedBox(width: 6),
              Text(
                method.label,
                style: AidaType.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: selected ? AidaColors.cream : AidaColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
