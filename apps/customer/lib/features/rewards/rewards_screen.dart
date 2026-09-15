import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/error/result.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_theme.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/aida_popup.dart';
import '../../core/widgets/entrance.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/member.dart';
import '../../domain/model/reward.dart';
import '../../domain/model/voucher.dart';
import 'widgets/earned_rewards_list.dart';
import 'widgets/reward_ticket_card.dart';

/// Rewards tab backed entirely by the caller-bound Phase 6 loyalty authority.
/// Point redemption is atomic on the server and returns only after a voucher
/// has been issued. The client never computes or persists a resulting balance.
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
  final Set<String> _redeeming = <String>{};

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

  void _snack(String message) => AidaPopup.show(context, title: message);

  Future<void> _redeem(Reward reward) async {
    if (_redeeming.contains(reward.id)) return;
    setState(() => _redeeming.add(reward.id));
    final result = await ref.read(loyaltyRepositoryProvider).redeemReward(reward.id);
    if (!mounted) return;
    setState(() => _redeeming.remove(reward.id));
    switch (result) {
      case Ok<void>():
        ref.invalidate(pointsProvider);
        ref.invalidate(rewardsProvider);
        ref.invalidate(vouchersProvider);
        ref.invalidate(stampCardProvider);
        _snack('${reward.name} added to your vouchers.');
      case Err<void>(failure: final failure):
        _snack(failure.message);
    }
  }

  void _showDetails({required String title, required String body}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AidaColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            Text(title, style: AidaType.serif(size: 22, color: AidaColors.textPrimary)),
            const SizedBox(height: 10),
            Text(body, style: AidaType.sans(size: 14, color: AidaColors.textMuted, height: 1.45)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AidaColors.coffee,
                  foregroundColor: AidaColors.cardWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Text('Got it', style: AidaType.sans(size: 15, weight: FontWeight.w700, color: AidaColors.cardWhite)),
              ),
            ),
          ],
        ),
      ),
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
                    KeyedSubtree(
                      key: _earnedKey,
                      child: const _SectionTitle(
                        title: 'Earned Rewards',
                        subtitle: 'Choose an issued voucher during checkout or present it at the counter',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._earnedTickets(vouchers),
                    const SizedBox(height: 32),
                    KeyedSubtree(
                      key: _catalogueKey,
                      child: const _SectionTitle(
                        title: 'Redeem with Points',
                        subtitle: 'Convert points into a server-issued voucher',
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
      loading: () => const [Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(color: AidaColors.coffee)))],
      error: (_, __) => [Text("Couldn't load your rewards.", style: AidaType.sans(size: 13, color: AidaColors.textMuted))],
      data: (list) {
        if (list.isEmpty) {
          return [Text('No earned rewards yet. Complete a stamp card or redeem points.', style: AidaType.sans(size: 13, color: AidaColors.textMuted))];
        }
        return [
          EarnedRewardsList(
            vouchers: list,
            scrollController: _scrollController,
            viewportKey: _viewportKey,
            revealOrderStart: 2,
            onApply: (_) => _snack('Select this voucher during checkout or show it at the counter.'),
            onDetails: (voucher) => _showDetails(
              title: voucher.title,
              body: '${voucher.description}\n\n${voucher.expiresLabel}.\n\nThe server validates ownership, expiry and item eligibility when the voucher is applied.',
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _catalogueTickets(AsyncValue<List<Reward>> rewards, AsyncValue<Points> points) {
    return rewards.when(
      loading: () => const [Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(color: AidaColors.coffee)))],
      error: (_, __) => [Text("Couldn't load the rewards catalogue.", style: AidaType.sans(size: 13, color: AidaColors.textMuted))],
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
                imageCategory: list[i].kind == RewardKind.freeItem ? 'Pastries' : 'Drinks',
                showRewardBadge: false,
                primaryLabel: _redeeming.contains(list[i].id)
                    ? 'Redeeming…'
                    : list[i].isAffordableAt(balance)
                        ? 'Redeem'
                        : 'Need more',
                primaryEnabled: list[i].isAffordableAt(balance) && !_redeeming.contains(list[i].id),
                onPrimary: list[i].isAffordableAt(balance) && !_redeeming.contains(list[i].id)
                    ? () => _redeem(list[i])
                    : null,
                onDetails: () => _showDetails(
                  title: list[i].name,
                  body: '${_catalogueDescription(list[i])}\n\nCosts ${list[i].pointsCost} points. You currently have $balance. Redemption is atomic and creates a voucher only after the server debits the points.',
                ),
              ),
            ),
          ],
        ];
      },
    );
  }

  String _catalogueDescription(Reward reward) => switch (reward.kind) {
    RewardKind.voucher => 'Convert ${reward.pointsCost} points into a ${reward.name.toLowerCase()} you can use at checkout.',
    RewardKind.freeItem => 'A free-item voucher for ${reward.pointsCost} points.',
    RewardKind.freeDrink => 'A free-drink voucher for ${reward.pointsCost} points.',
  };
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Rewards', style: AidaType.serif(size: 28, color: AidaColors.textPrimary)),
      const SizedBox(height: 4),
      Text('Your vouchers and what you can unlock next.', style: AidaType.sans(size: 13, color: AidaColors.textMuted)),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AidaType.sans(size: 16, weight: FontWeight.w700, color: AidaColors.textPrimary)),
      const SizedBox(height: 2),
      Text(subtitle, style: AidaType.sans(size: 12, color: AidaColors.textMuted)),
    ],
  );
}

class _BalanceCard extends StatefulWidget {
  const _BalanceCard({required this.points, required this.member, required this.onVouchers, required this.onRedeem});
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
        gradient: const LinearGradient(colors: [AidaColors.coffee, AidaColors.espresso], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: AidaColors.espresso.withValues(alpha: 0.25), blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              bottom: -45,
              child: Opacity(
                opacity: 0.14,
                child: ClipOval(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Transform.scale(scale: 1.5, child: Image.asset('assets/images/aida_logo.jpg', fit: BoxFit.cover)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AidaType.sans(size: 14, weight: FontWeight.w600, color: AidaColors.latte)),
                  const SizedBox(height: 6),
                  Text(_hidden ? '••••' : balance, style: AidaType.serif(size: 52, weight: FontWeight.w700, color: AidaColors.cream)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _CardPillButton(icon: Icons.confirmation_number_outlined, label: 'Vouchers', onTap: widget.onVouchers)),
                      const SizedBox(width: 10),
                      Expanded(child: _CardPillButton(icon: Icons.redeem_rounded, label: 'Redeem', onTap: widget.onRedeem)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(code == null ? 'MEMBER' : 'MEMBER · $code', style: AidaTheme.sectionLabel(color: AidaColors.latte)),
                ],
              ),
            ),
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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AidaColors.cardWhite.withValues(alpha: 0.14), border: Border.all(color: AidaColors.cardWhite.withValues(alpha: 0.28))),
                    child: Icon(_hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 15, color: AidaColors.cardWhite.withValues(alpha: 0.9)),
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

class _CardPillButton extends StatelessWidget {
  const _CardPillButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AidaColors.cardWhite.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AidaColors.cardWhite.withValues(alpha: 0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AidaColors.cream),
            const SizedBox(width: 6),
            Text(label, style: AidaType.sans(size: 12.5, weight: FontWeight.w700, color: AidaColors.cream)),
          ],
        ),
      ),
    ),
  );
}
