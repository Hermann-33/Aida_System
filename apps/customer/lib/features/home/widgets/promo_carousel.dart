import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../core/theme/aida_type.dart';
import '../../../core/widgets/product_image.dart';
import '../../../domain/model/promo.dart';

/// Swipeable hero promotions with page dots.
///
/// The CTA is browse-only — it never adds to a cart. Ordering is out of v1
/// scope, and a button that appears to order but does not would be worse than
/// no button at all.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.promos, this.onTap});

  final List<Promo> promos;
  final void Function(Promo)? onTap;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // An empty carousel takes no space rather than showing a blank frame.
    if (widget.promos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          // Tall enough for a 2-line headline + 2-line subhead + CTA without
          // Flexible squeezing the headline. Headlines carry an explicit "\n",
          // so two lines is the norm, not the exception.
          height: 196,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.promos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder:
                (_, i) => _PromoCard(
                  promo: widget.promos[i],
                  onTap: () => widget.onTap?.call(widget.promos[i]),
                ),
          ),
        ),
        if (widget.promos.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.promos.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 20 : 6,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: AidaTheme.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    imageUrl: promo.imageUrl,
                    category: 'Coffee',
                    borderRadius: 0,
                  ),
                  // Scrim: guarantees the headline stays legible whatever photo
                  // the café uploads later. Without it, a light image would
                  // make white text vanish.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AidaColors.espresso.withValues(alpha: 0.88),
                          AidaColors.espresso.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            promo.headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AidaType.serif(
                              size: 24,
                              color: AidaColors.cream,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            promo.subhead,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AidaType.sans(
                              size: 12,
                              height: 1.35,
                              color: AidaColors.latte,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AidaColors.rewardGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            promo.ctaLabel,
                            style: AidaType.sans(
                              size: 12,
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
      ),
    );
  }
}
