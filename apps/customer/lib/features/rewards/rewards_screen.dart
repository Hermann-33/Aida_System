import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/entrance.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/reward.dart';
import '../../domain/model/voucher.dart';
import 'widgets/reward_ticket_card.dart';

/// Rewards tab — earned voucher wallet + points catalogue. PRD CUS-06 / CUS-07.
///
/// Layout mirrors the Starbucks earned-rewards ticket list the client shared,
/// recolored to the Rose palette (§19.3): cream page, white tickets, coffee
/// actions, espresso reward badge with gold star.
///
/// "Apply" on an earned voucher is a request to present at the counter —
/// staff still consume the entitlement (CUS-07). "Redeem" on a catalogue
/// tier converts points → voucher; that call is not wired yet, so the button
/// says so honestly rather than pretending the points moved.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  final _scrollController = ScrollController();
  final _viewportKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AidaColors.espresso,
          content: Text(
            message,
            style: AidaType.sans(size: 13, color: AidaColors.cream),
          ),
        ),
      );
  }

  void _showDetails({required String title, required String body}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AidaColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AidaColors.latte,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AidaType.serif(size: 22, color: AidaColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: AidaType.sans(
                  size: 14,
                  color: AidaColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AidaColors.coffee,
                    foregroundColor: AidaColors.cardWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: AidaType.sans(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AidaColors.cardWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vouchers = ref.watch(vouchersProvider);
    final rewards = ref.watch(rewardsProvider);
    final points = ref.watch(pointsProvider);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: _Header(),
            ),
            Expanded(
              child: KeyedSubtree(
                key: _viewportKey,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  children: [
                    ScrollReveal(
                      controller: _scrollController,
                      viewportKey: _viewportKey,
                      order: 0,
                      child: _BalanceCard(points: points),
                    ),
                    // Extra space so the overlapping circles under the
                    // balance card aren't clipped by the next section.
                    const SizedBox(height: 36),
                    ScrollReveal(
                      controller: _scrollController,
                      viewportKey: _viewportKey,
                      order: 1,
                      child: _SectionTitle(
                        title: 'Earned Rewards',
                        subtitle: 'Show at the counter — staff apply them',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._earnedTickets(vouchers),
                    const SizedBox(height: 32),
                    ScrollReveal(
                      controller: _scrollController,
                      viewportKey: _viewportKey,
                      order: 4,
                      child: _SectionTitle(
                        title: 'Redeem with Points',
                        subtitle: 'Convert points into a voucher in-app',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._catalogueTickets(rewards, points),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _earnedTickets(AsyncValue<List<Voucher>> vouchers) {
    return vouchers.when(
      loading:
          () => [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AidaColors.coffee),
              ),
            ),
          ],
      error:
          (_, __) => [
            Text(
              'Couldn\'t load your rewards. Pull to try again later.',
              style: AidaType.sans(size: 13, color: AidaColors.textMuted),
            ),
          ],
      data: (list) {
        if (list.isEmpty) {
          return [
            Text(
              'No earned rewards yet — complete a stamp card or redeem points.',
              style: AidaType.sans(size: 13, color: AidaColors.textMuted),
            ),
          ];
        }
        return [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            ScrollReveal(
              controller: _scrollController,
              viewportKey: _viewportKey,
              order: 2 + i,
              child: RewardTicketCard(
                title: list[i].title,
                description: list[i].description,
                metaLabel: list[i].expiresLabel,
                kind: list[i].kind,
                imageCategory: list[i].imageCategory,
                primaryLabel: 'Apply',
                onPrimary:
                    () => _snack(
                      'Show this reward at the counter — staff will apply it.',
                    ),
                onDetails:
                    () => _showDetails(
                      title: list[i].title,
                      body:
                          '${list[i].description}\n\n'
                          '${list[i].expiresLabel}.\n\n'
                          'Points are not refunded if a voucher expires unused. '
                          'Only staff can apply this at checkout.',
                    ),
              ),
            ),
          ],
        ];
      },
    );
  }

  List<Widget> _catalogueTickets(
    AsyncValue<List<Reward>> rewards,
    AsyncValue<Points> points,
  ) {
    return rewards.when(
      loading:
          () => [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AidaColors.coffee),
              ),
            ),
          ],
      error:
          (_, __) => [
            Text(
              'Couldn\'t load the rewards catalogue.',
              style: AidaType.sans(size: 13, color: AidaColors.textMuted),
            ),
          ],
      data: (list) {
        final balance = points.value?.balance ?? 0;
        return [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            ScrollReveal(
              controller: _scrollController,
              viewportKey: _viewportKey,
              order: 5 + i,
              child: RewardTicketCard(
                title: list[i].name,
                description: _catalogueDescription(list[i]),
                metaLabel: '${list[i].pointsCost} POINTS',
                kind: list[i].kind,
                imageCategory:
                    list[i].kind == RewardKind.freeItem ? 'Pastries' : 'Drinks',
                showRewardBadge: false,
                primaryLabel:
                    list[i].isAffordableAt(balance) ? 'Redeem' : 'Need more',
                primaryEnabled: list[i].isAffordableAt(balance),
                onPrimary:
                    list[i].isAffordableAt(balance)
                        ? () => _snack(
                          'Points-to-voucher redemption is next — '
                          'your balance stays put until then.',
                        )
                        : null,
                onDetails:
                    () => _showDetails(
                      title: list[i].name,
                      body:
                          '${_catalogueDescription(list[i])}\n\n'
                          'Costs ${list[i].pointsCost} points. '
                          'You currently have $balance. '
                          'Redeeming converts points into a voucher; '
                          'staff still apply it at the counter.',
                    ),
              ),
            ),
          ],
        ];
      },
    );
  }

  String _catalogueDescription(Reward reward) => switch (reward.kind) {
    RewardKind.voucher =>
      'Convert ${reward.pointsCost} points into a ${reward.name.toLowerCase()} '
          'you can use at checkout.',
    RewardKind.freeItem =>
      'A free pastry voucher for ${reward.pointsCost} points. '
          'Staff apply it when you order.',
    RewardKind.freeDrink =>
      'A free drink for ${reward.pointsCost} points. '
          'Show the voucher at the counter.',
  };
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rewards',
          style: AidaType.serif(size: 28, color: AidaColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Your vouchers and what you can unlock next.',
          style: AidaType.sans(size: 13, color: AidaColors.textMuted),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AidaType.sans(
            size: 16,
            weight: FontWeight.w700,
            color: AidaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AidaType.sans(size: 12, color: AidaColors.textMuted),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.points});

  final AsyncValue<Points> points;

  @override
  Widget build(BuildContext context) {
    final balance = points.value?.formatted ?? '—';

    // Soft layered circles peeking under the card — same depth trick as
    // the reference balance card's overlapping avatars.
    const bubbles = <(IconData, Color)>[
      (Icons.star_rounded, AidaColors.rewardGold),
      (Icons.local_cafe_rounded, AidaColors.latte),
      (Icons.card_giftcard_rounded, AidaColors.caramelTint),
      (Icons.favorite_rounded, AidaColors.latte),
      (Icons.workspace_premium_rounded, AidaColors.rewardGold),
    ];

    return Padding(
      // Room for the half-circles that hang below the card.
      padding: const EdgeInsets.only(bottom: 22),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AidaColors.coffeeLight,
                  AidaColors.coffee,
                  AidaColors.espresso,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AidaColors.coffee.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AidaColors.cardWhite.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AidaColors.cardWhite.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AidaColors.rewardGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Aida Points',
                      style: AidaType.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AidaColors.cardWhite.withValues(alpha: 0.92),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AidaColors.cardWhite.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AidaColors.cardWhite.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AidaColors.cardWhite.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AidaColors.cardWhite.withValues(alpha: 0.55),
                    ),
                    color: AidaColors.cardWhite.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    'YOUR BALANCE',
                    style: AidaType.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AidaColors.cardWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  balance,
                  style: AidaType.serif(size: 42, color: AidaColors.cardWhite),
                ),
                const SizedBox(height: 4),
                Text(
                  'points ready to redeem',
                  style: AidaType.sans(
                    size: 13,
                    color: AidaColors.cardWhite.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < bubbles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _BalanceBubble(icon: bubbles[i].$1, color: bubbles[i].$2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceBubble extends StatelessWidget {
  const _BalanceBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: AidaColors.cardWhite, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: AidaColors.espresso),
    );
  }
}
