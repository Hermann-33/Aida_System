import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../core/theme/aida_type.dart';
import '../../../core/widgets/product_image.dart';
import '../../../domain/model/promo.dart';

/// Tall hero cards with a peek of the next one.
///
/// The peek is the point: a flat edge reads as the end of the content, whereas
/// a sliver of the next card tells the customer to swipe without a caption
/// saying so.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.promos, this.onTap});

  final List<Promo> promos;
  final void Function(Promo)? onTap;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  // Under 1.0 so the neighbouring card peeks in at the edge.
  late final _controller = PageController(viewportFraction: 0.87);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.promos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder:
                (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _PromoCard(
                    promo: widget.promos[i],
                    onTap: () => widget.onTap?.call(widget.promos[i]),
                  ),
                ),
          ),
        ),
        if (widget.promos.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.promos.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AidaColors.coffee : AidaColors.latte,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.onTap});

  final Promo promo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: AidaTheme.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(
                  imageUrl: promo.imageUrl,
                  category: 'Coffee',
                  borderRadius: 0,
                ),
                // Darken top and bottom only, so a photo stays visible through
                // the middle while the headline and the pill both stay legible
                // whatever image the café uploads later.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AidaColors.espresso.withValues(alpha: 0.72),
                        AidaColors.espresso.withValues(alpha: 0.18),
                        AidaColors.espresso.withValues(alpha: 0.62),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              promo.headline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AidaType.serif(
                                size: 28,
                                color: AidaColors.cream,
                                height: 1.15,
                              ),
                            ),
                          ),
                          if (promo.linkedOfferId != null) ...[
                            const SizedBox(width: 10),
                            const _StudentBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promo.subhead,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AidaType.sans(
                          size: 12.5,
                          height: 1.35,
                          color: AidaColors.latte,
                        ),
                      ),

                      const Spacer(),

                      // Floating CTA. No secondary icon button: the reference's
                      // was a bookmark, and Aida has nothing to bookmark yet.
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        decoration: BoxDecoration(
                          color: AidaColors.cream,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          promo.ctaLabel,
                          style: AidaType.sans(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: AidaColors.espresso,
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
      ),
    );
  }
}

class _StudentBadge extends StatelessWidget {
  const _StudentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AidaColors.cityRed,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_rounded, size: 13, color: AidaColors.cream),
          const SizedBox(width: 5),
          Text(
            'Students',
            style: AidaType.sans(
              size: 11,
              weight: FontWeight.w700,
              color: AidaColors.cream,
            ),
          ),
        ],
      ),
    );
  }
}
