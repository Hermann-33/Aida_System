import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../domain/model/cart.dart';
import '../../../domain/model/menu_item.dart';
import '../cart_screen.dart';

/// Lives in the app shell, visible on any tab once the cart has items. Kept
/// out of the bottom nav's 5 fixed slots per the cart design spec §3 — this
/// preserves the nav exactly as designed, including the QR's centred
/// elevation (CUS-17).
///
/// Visibility is driven directly by whether the cart is empty — there is no
/// separate "show/hide" flag to fall out of sync with the actual cart state.
class FloatingCartBar extends ConsumerWidget {
  const FloatingCartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    final menu = ref.watch(menuItemsProvider).value ?? const <MenuItem>[];
    final subtotal = cart.subtotal(
      (line) => addOnTotalFor(line.addOnIds, menu),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap:
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AidaColors.espresso,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AidaColors.espresso.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AidaColors.rewardGold,
                ),
                child: Center(
                  child: Text(
                    '${cart.itemCount}',
                    style: AidaType.sans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: AidaColors.espresso,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cart.itemCount == 1 ? '1 item' : '${cart.itemCount} items',
                  style: AidaType.sans(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: AidaColors.cream,
                  ),
                ),
              ),
              Text(
                subtotal.formatted,
                style: AidaType.sans(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AidaColors.rewardGold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AidaColors.cream,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
