import 'package:flutter/material.dart';

import '../theme/aida_colors.dart';

/// A product image with a graceful fallback.
///
/// Aida has no product photography yet. Rather than leave holes in the layout,
/// this reserves the correct space and draws a warm category-tinted placeholder
/// — so when real photos arrive, they drop straight in and nothing else moves.
///
/// It also handles the two failure modes a real photo introduces: a slow
/// network (fade in, no jank) and a dead URL (fall back, never a grey X).
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.size,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    /// When false, placeholders are icon-only on transparent pixels — for
    /// grid tiles where the product should float on the page color.
    this.filledPlaceholder = true,
    /// Bundled cut-out or product art when [imageUrl] is missing or fails.
    this.assetFallback,
  });

  final String? imageUrl;
  final String category;

  /// Square when set. Otherwise fills its parent.
  final double? size;
  final double borderRadius;
  final BoxFit fit;
  final bool filledPlaceholder;
  final String? assetFallback;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final child = SizedBox(
      width: size,
      height: size,
      child: _buildContent(),
    );

    if (fit == BoxFit.contain && borderRadius <= 0) {
      return child;
    }

    return ClipRRect(borderRadius: radius, child: child);
  }

  Widget _buildContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: fit,
        errorBuilder: (_, __, ___) => _assetOrPlaceholder(),
        frameBuilder: (_, child, frame, wasSyncLoaded) {
          if (wasSyncLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: frame == null ? _assetOrPlaceholder() : child,
          );
        },
      );
    }
    return _assetOrPlaceholder();
  }

  Widget _assetOrPlaceholder() {
    if (assetFallback != null) {
      return Image.asset(
        assetFallback!,
        fit: fit,
        errorBuilder:
            (_, __, ___) => _Placeholder(
              category: category,
              filled: filledPlaceholder,
            ),
      );
    }
    return _Placeholder(category: category, filled: filledPlaceholder);
  }
}

/// Warm tinted tile with a category-appropriate icon. Deliberately not a grey
/// box — it should read as intentional, not as a missing asset.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.category, this.filled = true});

  final String category;
  final bool filled;

  static IconData _iconFor(String category) {
    return switch (category.toLowerCase()) {
      'coffee' => Icons.coffee_rounded,
      'iced drinks' || 'cold' => Icons.local_drink_rounded,
      'food' => Icons.bakery_dining_rounded,
      'add-ons' || 'add ons' => Icons.add_circle_outline_rounded,
      _ => Icons.local_cafe_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!filled) {
      return Center(
        child: Icon(
          _iconFor(category),
          size: 36,
          color: AidaColors.coffee.withValues(alpha: 0.45),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AidaColors.latte.withValues(alpha: 0.55),
            AidaColors.caramelTint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _iconFor(category),
          size: 28,
          color: AidaColors.coffee.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
