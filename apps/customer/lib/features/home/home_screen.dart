import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../domain/model/member.dart';
import 'widgets/featured_item_card.dart';
import 'widgets/offer_banner.dart';
import 'widgets/points_balance_card.dart';
import 'widgets/stamp_card_widget.dart';
import '../../core/theme/aida_type.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberProvider);
    final points = ref.watch(pointsProvider);
    final stamps = ref.watch(stampCardProvider);
    final offers = ref.watch(offersProvider);
    final featured = ref.watch(featuredItemProvider);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AidaColors.coffee,
          onRefresh: () async {
            ref.invalidate(pointsProvider);
            ref.invalidate(stampCardProvider);
            ref.invalidate(offersProvider);
            ref.invalidate(featuredItemProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              member.when(
                data: (m) => _Greeting(member: m),
                loading: () => const _GreetingSkeleton(),
                error: (_, __) => const _Greeting.fallback(),
              ),
              const SizedBox(height: 20),

              points.when(
                data: (p) => PointsBalanceCard(points: p),
                loading: () => const _CardSkeleton(height: 96),
                error: (_, __) => const _CardSkeleton(height: 96),
              ),
              const SizedBox(height: 16),

              stamps.when(
                data: (s) => StampCardWidget(card: s),
                loading: () => const _CardSkeleton(height: 190),
                error: (_, __) => const _CardSkeleton(height: 190),
              ),
              const SizedBox(height: 16),

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
                loading: () => const _CardSkeleton(height: 80),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 4),

              featured.when(
                data:
                    (item) =>
                        item == null
                            ? const SizedBox.shrink()
                            : FeaturedItemCard(item: item),
                loading: () => const _CardSkeleton(height: 150),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.member}) : _fallback = false;
  const _Greeting.fallback() : member = null, _fallback = true;

  final Member? member;
  final bool _fallback;

  /// Time-of-day greeting. Malaysia is a single timezone, so the device clock
  /// is authoritative here.
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
                style: AidaType.serif(
                  size: 26,
                  weight: FontWeight.w700,
                  color: AidaColors.textPrimary,
                ),
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
              style: AidaType.serif(
                size: 19,
                weight: FontWeight.w700,
                color: AidaColors.coffee,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GreetingSkeleton extends StatelessWidget {
  const _GreetingSkeleton();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 52);
}

/// A neutral placeholder while data loads. Deliberately calm — a spinner on
/// every card makes the whole screen flicker.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});

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
