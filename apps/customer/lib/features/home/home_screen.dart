import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/member.dart';
import '../../domain/model/loyalty.dart';
import 'widgets/category_row.dart';
import 'widgets/loyalty_card.dart';
import 'widgets/offer_banner.dart';
import 'widgets/popular_item_tile.dart';
import 'widgets/promo_carousel.dart';

/// Home.
///
/// Order is deliberate. Loyalty (points, stamps) sits above browse content
/// (promos, categories, popular picks) because that is Aida's differentiator —
/// PRD §20 takes "keep points and rewards highly visible" as the lesson from
/// ZUS. A pure ordering app would invert this; Aida is not one.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Jump to the Menu tab. Used by "View All" and the category chips.
  void _openMenu(WidgetRef ref) =>
      ref.read(selectedTabProvider.notifier).select(AppTab.menu);

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
    final offers = ref.watch(offersProvider);
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
              ..invalidate(offersProvider)
              ..invalidate(promosProvider)
              ..invalidate(categoriesProvider)
              ..invalidate(popularItemsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
              promos.when(
                data: (list) => PromoCarousel(promos: list),
                // Matches the carousel's height, so the page does not jump when
                // the promos land.
                loading: () => const _Skeleton(height: 196),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              offers.when(
                data:
                    (list) => Column(
                      children: [
                        for (final o in list) ...[
                          OfferBanner(offer: o),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                loading: () => const _Skeleton(height: 80),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),

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
                                CategoryRow(
                                  categories: list,
                                  onTap: (_) => _openMenu(ref),
                                ),
                              ],
                            ),
                loading: () => const _Skeleton(height: 92),
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
                                const SizedBox(height: 4),
                                for (final item in list) PopularItemTile(item: item),
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
