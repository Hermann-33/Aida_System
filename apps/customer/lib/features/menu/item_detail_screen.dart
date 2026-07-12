import 'package:flutter/material.dart';

import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/model/menu_item.dart';

/// Opens [ItemDetailScreen] for [item]. Shared by every place an item can be
/// tapped (Home's grid, Menu's list), so navigation stays in one place rather
/// than each caller building its own MaterialPageRoute.
void openItemDetail(BuildContext context, MenuItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
}

/// A menu item's detail page. CUS-09.
///
/// Adapted from a client reference built for an ordering app — it had a Size
/// picker, an Add-ons checklist, a quantity stepper, and an "Add to Cart"
/// button. None of that is real here:
///
/// - No size variants or add-on customisation — [MenuItem] doesn't model
///   either, and Aida's own "Add-ons" (§12.2) are separate purchasable menu
///   items (Extra Shot, Oat Milk), not per-drink customisation options.
/// - No quantity stepper or Add to Cart — v1 is browse-only, no cart exists.
///   A large, central "Add to Cart" button on its own dedicated screen would
///   be the single most prominent broken promise in the app if it did
///   nothing, more so than the small "+" already flagged on the Home grid.
/// - No favourite/heart icon either — there's no favourites feature or
///   storage anywhere in the app. Adding a third decorative icon that does
///   nothing would compound the exact pattern this file is trying to avoid.
///
/// What's real and kept: the hero photo, name, price, description, and
/// whatever badges the item actually carries (category, student eligibility,
/// bonus points, sold-out state) — all genuine fields on [MenuItem].
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(item: item),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AidaType.serif(
                              size: 26,
                              color: AidaColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.price.formatted,
                          style: AidaType.sans(
                            size: 20,
                            weight: FontWeight.w800,
                            color: AidaColors.coffee,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag(label: item.category, color: AidaColors.coffee),
                        if (!item.isAvailable)
                          const _Tag(
                            label: 'Sold out',
                            color: AidaColors.error,
                            filled: true,
                          ),
                        if (item.isStudentEligible)
                          const _Tag(
                            label: 'Student offer eligible',
                            color: AidaColors.cityRed,
                          ),
                        if (item.bonusPoints != null)
                          _Tag(
                            label: '+${item.bonusPoints} pts',
                            color: AidaColors.rewardGold,
                            filled: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.description,
                      style: AidaType.sans(
                        size: 14.5,
                        height: 1.5,
                        color: AidaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-width photo, not a circular cutout — the photo is the hero
        // here, so it should fill the space rather than float inside it.
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
          child: SizedBox(
            height: 320,
            width: double.infinity,
            child: ProductImage(
              imageUrl: item.imageUrl,
              category: item.category,
              borderRadius: 0,
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AidaColors.cardWhite.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AidaColors.textPrimary),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;

  /// Filled tags (sold-out, bonus points) carry their own meaning at a
  /// glance; outlined tags (category, student eligibility) are informational
  /// rather than states, so they stay quiet.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.14) : Colors.transparent,
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AidaType.sans(size: 11.5, weight: FontWeight.w700, color: color),
      ),
    );
  }
}
