import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../core/theme/aida_type.dart';
import '../../../core/widgets/product_image.dart';
import '../../../domain/model/menu_item.dart';

/// A 2-column grid card for Home's "Popular Picks": a tilted, rounded-rect
/// product photo anchored to the top-left corner, floating half over a white
/// card underneath it — a dropped-photo look, not a centred circular badge.
///
/// Adapted from a client reference that also had a cart button, a struck-through
/// discount price, and a star rating with a sold-count. None of those are
/// carried over:
///
/// - The "+" is present for visual parity with the reference, but v1 is
///   browse-only — there is no cart to add to. It performs the same action
///   as tapping the card (open detail) rather than doing nothing, so it is
///   not a dead end, but it is not "add to order" either. Flagged explicitly:
///   a customer will read a "+" as add-to-cart, and real ordering (cart,
///   checkout, payment timing) is CUS-14, deferred out of v1. Revisit before
///   a real customer sees this — either wire it to real ordering or drop it.
/// - No discount price or rating/sold-count — Aida's domain model has no
///   such data. Inventing "4.9 stars, 500+ sold" to make a demo look
///   finished would be fabricating numbers a client could mistake for real
///   figures. The category name and the real bonus-points badge take that
///   slot instead — both are genuine fields on [MenuItem].
class PopularItemCard extends StatelessWidget {
  const PopularItemCard({super.key, required this.item, this.onTap});

  final MenuItem item;
  final VoidCallback? onTap;

  // +50% per request.
  static const _imageSize = 144.0;
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
                // mainAxisAlignment.end, not .min: the Positioned box above
                // gives this Column a tight height, and the name/price block
                // was hugging the top of it — right under the photo — leaving
                // a dead gap below. Anchoring to the bottom uses that space
                // instead of wasting it.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
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
                    // Right-padded so the price/chip never runs under the "+"
                    // button, which floats independently in the corner.
                    Padding(
                      padding: EdgeInsets.only(right: unavailable ? 0 : 38),
                      child: Row(
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
                    ),
                  ],
                ),
              ),
            ),

            // The floating photo, drawn last so it sits in front of the card.
            // Rounded rectangle, anchored to the top-left corner and tilted —
            // not a centred circle. A dropped-photo look, not a badge.
            Positioned(
              top: 0,
              left: 10,
              child: Transform.rotate(
                angle: -0.09,
                child: Container(
                  width: _imageSize,
                  height: _imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AidaColors.espresso.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ProductImage(
                      imageUrl: item.imageUrl,
                      category: item.category,
                      size: _imageSize,
                    ),
                  ),
                ),
              ),
            ),

            // Visual "+" only — see the class doc for why this is not a real
            // add-to-cart action. Same onTap as the card, not a no-op.
            if (!unavailable)
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AidaColors.coffee,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AidaColors.cream,
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
