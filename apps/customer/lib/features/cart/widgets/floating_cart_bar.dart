import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../core/widgets/product_image.dart';
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
/// Always mounted (never [SizedBox.shrink]-and-gone) so [AnimatedSwitcher]
/// has something to transition between — appearing/disappearing instantly
/// otherwise, with no chance to slide or fade in.
class FloatingCartBar extends ConsumerWidget {
  const FloatingCartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final menu = ref.watch(menuItemsProvider).value ?? const <MenuItem>[];
    final subtotal = cart.subtotal(
      (line) => addOnTotalFor(line.addOnIds, menu),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
      child:
          cart.isEmpty
              ? const SizedBox.shrink(key: ValueKey('cart-bar-empty'))
              : _Bar(
                key: const ValueKey('cart-bar-full'),
                lines: cart.lineItems,
                itemCount: cart.itemCount,
                subtotal: subtotal.formatted,
              ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.lines,
    required this.itemCount,
    required this.subtotal,
  });

  final List<CartLineItem> lines;
  final int itemCount;
  final String subtotal;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('floating_cart_bar'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap:
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AidaColors.rewardGold,
                ),
                child: Center(
                  child: Text(
                    '$itemCount',
                    style: AidaType.sans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: AidaColors.espresso,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _ThumbnailStack(lines: lines)),
              Text(
                subtotal,
                style: AidaType.sans(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AidaColors.rewardGold,
                ),
              ),
              const SizedBox(width: 6),
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

/// Overlapping cut-out thumbnails of what's actually in the cart, matching
/// user reference imagery, instead of the old bare "N items" text. A line's
/// key is its identity (item/size/add-ons/note, the same tuple
/// [CartLineItem.sameConfigurationAs] uses) — a fresh key means a genuinely
/// new line, which is what makes [_PopIn] animate only the newest bubble
/// rather than replaying on every rebuild.
class _ThumbnailStack extends StatelessWidget {
  const _ThumbnailStack({required this.lines});

  final List<CartLineItem> lines;

  static const _bubbleSize = 30.0;
  static const _step = 20.0;
  static const _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final shown = lines.take(_maxShown).toList();
    final overflow = lines.length - shown.length;
    final bubbleCount = shown.length + (overflow > 0 ? 1 : 0);
    if (bubbleCount == 0) return const SizedBox.shrink();
    final width = _bubbleSize + _step * (bubbleCount - 1);

    return SizedBox(
      height: _bubbleSize,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _step,
              child: _PopIn(
                key: ValueKey(
                  'thumb_${shown[i].item.id}_${shown[i].size?.id}_'
                  '${shown[i].addOnIds.join(',')}_${shown[i].note}',
                ),
                child: ClipOval(
                  child: ProductImage(
                    imageUrl: shown[i].item.imageUrl,
                    category: shown[i].item.category,
                    size: _bubbleSize - 4,
                    borderRadius: (_bubbleSize - 4) / 2,
                  ),
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * _step,
              child: _PopIn(
                key: ValueKey('thumb_overflow_$overflow'),
                child: Container(
                  width: _bubbleSize - 4,
                  height: _bubbleSize - 4,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AidaColors.coffee,
                  ),
                  child: Text(
                    '+$overflow',
                    style: AidaType.sans(
                      size: 10,
                      weight: FontWeight.w800,
                      color: AidaColors.cream,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A ringed bubble that pops in with a little overshoot the first time its
/// key appears, and just sits still on every rebuild after that.
class _PopIn extends StatelessWidget {
  const _PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.elasticOut,
      builder:
          (context, t, tweenChild) =>
              Transform.scale(scale: t, child: tweenChild),
      child: Container(
        width: _ThumbnailStack._bubbleSize,
        height: _ThumbnailStack._bubbleSize,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AidaColors.espresso,
        ),
        child: child,
      ),
    );
  }
}
