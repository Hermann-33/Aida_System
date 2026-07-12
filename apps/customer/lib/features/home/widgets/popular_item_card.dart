import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../core/theme/aida_type.dart';
import '../../../core/widgets/product_image.dart';
import '../../../domain/model/menu_item.dart';

/// A 2-column grid card for Home's "Popular Picks": a circular product photo
/// floating half over a white card underneath it.
///
/// Adapted from a client reference that also had a cart button, a struck-through
/// discount price, and a star rating with a sold-count. None of those are
/// carried over:
///
/// - No cart button — v1 is browse-only (no ordering), so a button that
///   implies "add to order" would promise something the app doesn't do.
///   Tapping the card opens detail instead; there is nothing to add.
/// - No discount price or rating/sold-count — Aida's domain model has no
///   such data. Inventing "4.9 stars, 500+ sold" to make a demo look
///   finished would be fabricating numbers a client could mistake for real
///   figures. The category name and the real bonus-points badge take that
///   slot instead — both are genuine fields on [MenuItem].
class PopularItemCard extends StatelessWidget {
  const PopularItemCard({super.key, required this.item, this.onTap});

  final MenuItem item;
  final VoidCallback? onTap;

  static const _imageSize = 96.0;
  static const _overlap = _imageSize / 2;

  @override
  Widget build(BuildContext context) {
    final unavailable = !item.isAvailable;

    return Opacity(
      // Dim the whole card rather than hiding it: the customer should know
      // the café sells this, just not right now.
      opacity: unavailable ? 0.55 : 1,
      child: GestureDetector(
        onTap: unavailable ? null : onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The white card, starting partway down so the photo can sit half
            // on top of it and half above it on the page background.
            Positioned(
              top: _overlap,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, _overlap + 12, 14, 14),
                decoration: BoxDecoration(
                  color: AidaColors.cardWhite,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AidaTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AidaType.sans(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unavailable ? 'Sold out' : item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AidaType.sans(
                        size: 11,
                        weight: unavailable ? FontWeight.w700 : FontWeight.w500,
                        color: unavailable ? AidaColors.error : AidaColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.price.formatted,
                            overflow: TextOverflow.ellipsis,
                            style: AidaType.sans(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: AidaColors.coffee,
                            ),
                          ),
                        ),
                        if (item.bonusPoints != null) ...[
                          const SizedBox(width: 6),
                          _BonusChip(points: item.bonusPoints!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // The floating photo, drawn last so it sits in front of the card.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: _imageSize,
                  height: _imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AidaColors.espresso.withValues(alpha: 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: ProductImage(
                      imageUrl: item.imageUrl,
                      category: item.category,
                      size: _imageSize,
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

class _BonusChip extends StatelessWidget {
  const _BonusChip({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AidaColors.rewardGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '+$points',
        style: AidaType.sans(
          size: 10,
          weight: FontWeight.w700,
          color: AidaColors.rewardGold,
        ),
      ),
    );
  }
}
