import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_theme.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/entrance.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/member.dart';
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
  final _earnedKey = GlobalKey();
  final _catalogueKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
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
    final member = ref.watch(displayedMemberProvider);

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
                      child: _BalanceCard(
                        points: points,
                        member: member,
                        onVouchers: () => _scrollToSection(_earnedKey),
                        onRedeem: () => _scrollToSection(_catalogueKey),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ScrollReveal(
                      controller: _scrollController,
                      viewportKey: _viewportKey,
                      order: 1,
                      child: KeyedSubtree(
                        key: _earnedKey,
                        child: _SectionTitle(
                          title: 'Earned Rewards',
                          subtitle: 'Show at the counter — staff apply them',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._earnedTickets(vouchers),
                    const SizedBox(height: 32),
                    ScrollReveal(
                      controller: _scrollController,
                      viewportKey: _viewportKey,
                      order: 4,
                      child: KeyedSubtree(
                        key: _catalogueKey,
                        child: _SectionTitle(
                          title: 'Redeem with Points',
                          subtitle: 'Convert points into a voucher in-app',
                        ),
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

/// Same dark card language as the membership/QR card
/// ([MembershipCardScreen]'s `_Card`) — coffee→espresso gradient, 28px
/// radius, cream serif name, "MEMBER · code" footer — so the two feel like
/// one card family rather than two unrelated designs. Layout (chip badge,
/// hide-balance toggle, balance caption, pill action row) follows a
/// wallet-app reference the user shared, with the actions mapped to real
/// in-app destinations — "Vouchers"/"Redeem" scroll to the sections already
/// on this page — rather than invented banking actions that don't apply to
/// a café points card.
class _BalanceCard extends StatefulWidget {
  const _BalanceCard({
    required this.points,
    required this.member,
    required this.onVouchers,
    required this.onRedeem,
  });

  final AsyncValue<Points> points;
  final AsyncValue<Member> member;
  final VoidCallback onVouchers;
  final VoidCallback onRedeem;

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final balance = widget.points.value?.formatted ?? '—';
    final name = widget.member.value?.name ?? 'Aida Member';
    final code = widget.member.value?.memberCode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AidaColors.coffee, AidaColors.espresso],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AidaColors.espresso.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // A large, faint watermark of the café's own logo — the
            // "premium card" texture trick real membership/bank cards use.
            // Circular crop, zoomed in past the source photo's own cream
            // border/edges (it's a photo of a printed sticker, not a clean
            // isolated mark) so only the emblem itself shows, not a
            // rectangular patch of that border reading as blank space.
            Positioned(
              right: -45,
              bottom: -45,
              child: Opacity(
                opacity: 0.14,
                child: ClipOval(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Transform.scale(
                      scale: 1.5,
                      child: Image.asset(
                        'assets/images/aida_logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AidaType.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AidaColors.latte,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _hidden ? '••••' : balance,
                    style: AidaType.serif(
                      size: 52,
                      weight: FontWeight.w700,
                      color: AidaColors.cream,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CardPillButton(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Vouchers',
                          onTap: widget.onVouchers,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CardPillButton(
                          icon: Icons.redeem_rounded,
                          label: 'Redeem',
                          onTap: widget.onRedeem,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    code == null ? 'MEMBER' : 'MEMBER · $code',
                    style: AidaTheme.sectionLabel(color: AidaColors.latte),
                  ),
                ],
              ),
            ),
            // Floats independently of the Column above — it used to sit in
            // its own row there, pushing the name/balance down by its own
            // height for no reason, since it's a small corner control.
            Positioned(
              top: 16,
              right: 22,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _hidden = !_hidden),
                  child: Container(
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
                      _hidden
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 15,
                      color: AidaColors.cardWhite.withValues(alpha: 0.9),
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

/// The "Request"/"Transfer" pill shape from the reference, wired to
/// in-page navigation instead of banking actions.
class _CardPillButton extends StatelessWidget {
  const _CardPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AidaColors.cardWhite.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AidaColors.cardWhite.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AidaColors.cream),
              const SizedBox(width: 6),
              Text(
                label,
                style: AidaType.sans(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: AidaColors.cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
