import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/member.dart';
import '../../domain/model/loyalty.dart';
import '../menu/widgets/category_chip.dart';
import '../menu/widgets/category_strip.dart';
import 'widgets/loyalty_card.dart';
import 'widgets/popular_item_card.dart';
import 'widgets/promo_carousel.dart';

/// Home.
///
/// Order is deliberate. Loyalty (points, stamps) sits above browse content
/// (promos, categories, popular picks) because that is Aida's differentiator —
/// PRD §20 takes "keep points and rewards highly visible" as the lesson from
/// ZUS. A pure ordering app would invert this; Aida is not one.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Open the Menu tab, optionally filtered to one category.
  ///
  /// Passing the category through is what makes the chip worth tapping: "View
  /// All" clears the filter, while tapping Coffee lands you on Coffee.
  void _openMenu(WidgetRef ref, {String? categoryId}) {
    ref.read(selectedCategoryProvider.notifier).select(categoryId);
    ref.read(selectedTabProvider.notifier).select(AppTab.menu);
  }

  /// Jump to the Rewards tab.
  void _openRewards(WidgetRef ref) =>
      ref.read(selectedTabProvider.notifier).select(AppTab.rewards);

  /// Points and stamps load together. Showing a balance above an empty track
  /// would flash a half-built card, so it waits for both.
  Widget _loyalty(
    WidgetRef ref,
    AsyncValue<Points> points,
    AsyncValue<StampCard> stamps,
  ) {
    final p = points.value;
    final s = stamps.value;

    if (p == null || s == null) return const _Skeleton(height: 290);

    return LoyaltyCard(
      points: p,
      stamps: s,
      onDetails: () => _openRewards(ref),
      onRedeem: () => _openRewards(ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberProvider);
    final points = ref.watch(pointsProvider);
    final stamps = ref.watch(stampCardProvider);
    final promos = ref.watch(promosProvider);
    final categories = ref.watch(categoriesProvider);
    final popular = ref.watch(popularItemsProvider);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AidaColors.coffee,
          onRefresh: () async {
            ref
              ..invalidate(pointsProvider)
              ..invalidate(stampCardProvider)
              ..invalidate(rewardsProvider)
              ..invalidate(promosProvider)
              ..invalidate(categoriesProvider)
              ..invalidate(popularItemsProvider);
          },
          child: ListView(
            // Keyed so tests can target this scroll view specifically — the
            // category strip below also contains a ListView once it has more
            // categories than fit, and `find.byType(ListView)` alone is
            // ambiguous the moment that happens.
            key: const Key('home_scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            // Deep bottom padding: the nav pill floats over the content, so the
            // last item would otherwise sit underneath it.
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              member.when(
                data: (m) => _Greeting(member: m),
                loading: () => const SizedBox(height: 52),
                error: (_, __) => const _Greeting.fallback(),
              ),
              const SizedBox(height: 20),

              // --- Loyalty first ------------------------------------------
              _loyalty(ref, points, stamps),
              const SizedBox(height: 24),

              // --- Then browse --------------------------------------------
              // Active offers are folded into the carousel as slides (see the
              // note on the Promo model) rather than repeated below it in a
              // separate banner list.
              promos.when(
                data: (list) => PromoCarousel(promos: list),
                // Matches the carousel's height, so the page does not jump when
                // the promos land.
                loading: () => const _Skeleton(height: 196),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              categories.when(
                data:
                    (list) =>
                        list.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(
                                  title: 'Explore Our Menu',
                                  onViewAll: () => _openMenu(ref),
                                ),
                                const SizedBox(height: 14),
                                CategoryStrip(
                                  categories: list,
                                  keyPrefix: 'home_cat',
                                  onSelect: (id) => _openMenu(ref, categoryId: id),
                                ),
                              ],
                            ),
                loading: () => const _Skeleton(height: CategoryChip.height + 20),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 22),

              popular.when(
                data:
                    (list) =>
                        list.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(
                                  title: 'Popular Picks',
                                  onViewAll: () => _openMenu(ref),
                                ),
                                const SizedBox(height: 26),
                                // shrinkWrap + disabled physics: this grid is
                                // nested inside Home's own vertical ListView, so it
                                // must size to its content and let the outer list
                                // own the actual scrolling.
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 22,
                                        // Shorter cells make the card's fixed
                                        // top overlap ratio (imageSize / 2)
                                        // eat a bigger share of the cell, so
                                        // this dropped when the image grew
                                        // 96 -> 144 — tuned against the
                                        // golden, not computed exactly.
                                        childAspectRatio: 0.64,
                                      ),
                                  itemCount: list.length,
                                  itemBuilder: (_, i) => PopularItemCard(item: list[i]),
                                ),
                              ],
                            ),
                loading: () => const _Skeleton(height: 220),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section title with a "View All" affordance.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: AidaType.sans(
              size: 17,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Will point at the Menu tab once that screen lands.
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View All',
            style: AidaType.sans(
              size: 12,
              weight: FontWeight.w600,
              color: AidaColors.coffee,
            ),
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.member}) : _fallback = false;
  const _Greeting.fallback() : member = null, _fallback = true;

  final Member? member;
  final bool _fallback;

  /// Malaysia is a single timezone, so the device clock is authoritative.
  static String _partOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = _fallback ? 'Aida Member' : member!.name;
    final initial = _fallback ? 'A' : member!.initial;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _partOfDay(),
                style: AidaType.sans(size: 14, color: AidaColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AidaType.serif(size: 26, color: AidaColors.textPrimary),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AidaColors.latte,
            border: Border.all(color: AidaColors.coffee.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              initial,
              style: AidaType.serif(size: 19, color: AidaColors.coffee),
            ),
          ),
        ),
      ],
    );
  }
}

/// Calm placeholder while data loads. A spinner on every card would make the
/// whole screen flicker.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AidaColors.latte.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}
