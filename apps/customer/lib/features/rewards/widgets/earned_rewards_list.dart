import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/entrance.dart';
import '../../../domain/model/voucher.dart';
import 'reward_ticket_card.dart';
import 'ticket_tear.dart';

/// The "Earned Rewards" ticket list. Owns its own [AnimatedList] so tapping
/// Apply visually tears that card along its own dashed seam — see
/// [TicketTear] — then it resettles at the bottom of the list, rather than
/// an instant jump.
///
/// Purely local/cosmetic: there's no used/applied status on [Voucher] (staff
/// still consume the entitlement at the counter — see rewards_screen.dart's
/// class doc), so "applied" here only lasts for this screen's lifetime and
/// resyncs to the server list whenever it actually changes underneath.
class EarnedRewardsList extends StatefulWidget {
  const EarnedRewardsList({
    super.key,
    required this.vouchers,
    required this.onApply,
    required this.onDetails,
    required this.scrollController,
    required this.viewportKey,
    required this.revealOrderStart,
  });

  final List<Voucher> vouchers;
  final ValueChanged<Voucher> onApply;
  final ValueChanged<Voucher> onDetails;
  final ScrollController scrollController;
  final GlobalKey viewportKey;
  final int revealOrderStart;

  @override
  State<EarnedRewardsList> createState() => _EarnedRewardsListState();
}

class _EarnedRewardsListState extends State<EarnedRewardsList> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<Voucher> _order;
  final _applied = <String>{};

  @override
  void initState() {
    super.initState();
    _order = List.of(widget.vouchers);
  }

  @override
  void didUpdateWidget(covariant EarnedRewardsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = _order.map((v) => v.id).toSet();
    final newIds = widget.vouchers.map((v) => v.id).toSet();
    if (setEquals(oldIds, newIds)) return;

    // The provider's own list changed underneath us (a new voucher earned,
    // one expired, etc.) — diff it into the AnimatedList's model with real
    // insert/remove calls rather than a blind rebuild, since AnimatedList
    // tracks its item count independently of ours.
    final removedIndices = <int>[];
    for (var i = 0; i < _order.length; i++) {
      if (!newIds.contains(_order[i].id)) removedIndices.add(i);
    }
    for (final i in removedIndices.reversed) {
      final removed = _order.removeAt(i);
      _applied.remove(removed.id);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => const SizedBox.shrink(),
        duration: const Duration(milliseconds: 200),
      );
    }

    for (final voucher in widget.vouchers) {
      if (oldIds.contains(voucher.id)) continue;
      _order.add(voucher);
      _listKey.currentState?.insertItem(
        _order.length - 1,
        duration: const Duration(milliseconds: 320),
      );
    }
  }

  void _handleApply(Voucher voucher) {
    widget.onApply(voucher);
    if (_applied.contains(voucher.id)) return;
    setState(() => _applied.add(voucher.id));
  }

  void _handleTornAway(Voucher voucher) {
    final removeAt = _order.indexOf(voucher);
    if (removeAt == -1) return;

    _order.removeAt(removeAt);
    _listKey.currentState?.removeItem(
      removeAt,
      (context, animation) => const SizedBox.shrink(),
      duration: const Duration(milliseconds: 120),
    );

    final insertAt = _order.length;
    _order.add(voucher);
    _listKey.currentState?.insertItem(
      insertAt,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_order.isEmpty) return const SizedBox.shrink();

    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _order.length,
      itemBuilder: (context, index, animation) {
        final voucher = _order[index];
        final isLast = index == _order.length - 1;
        return _AnimatedTicket(
          animation: animation,
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: ScrollReveal(
              controller: widget.scrollController,
              viewportKey: widget.viewportKey,
              order: widget.revealOrderStart + index,
              child: _EarnedTicketItem(
                key: ValueKey(voucher.id),
                voucher: voucher,
                applied: _applied.contains(voucher.id),
                onApply: _handleApply,
                onDetails: widget.onDetails,
                onTornAway: _handleTornAway,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One ticket in the list. Plays its own [TicketTear] the moment [applied]
/// flips true, then reports back via [onTornAway] once the tear finishes so
/// the parent list can relocate it to the bottom.
class _EarnedTicketItem extends StatefulWidget {
  const _EarnedTicketItem({
    super.key,
    required this.voucher,
    required this.applied,
    required this.onApply,
    required this.onDetails,
    required this.onTornAway,
  });

  final Voucher voucher;
  final bool applied;
  final ValueChanged<Voucher> onApply;
  final ValueChanged<Voucher> onDetails;
  final ValueChanged<Voucher> onTornAway;

  @override
  State<_EarnedTicketItem> createState() => _EarnedTicketItemState();
}

class _EarnedTicketItemState extends State<_EarnedTicketItem>
    with SingleTickerProviderStateMixin {
  // Lands in TicketTear's held plateau (fully separated, fully opaque,
  // past the fade) — the resting "torn" mark left behind once a card has
  // settled at the bottom, so it stays visibly used rather than reverting
  // to a whole card.
  static const _restTornProgress = 0.5;

  late final AnimationController _tear;

  @override
  void initState() {
    super.initState();
    _tear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener(_onTearStatus);
  }

  void _onTearStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onTornAway(widget.voucher);
    }
  }

  @override
  void didUpdateWidget(covariant _EarnedTicketItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.applied && !oldWidget.applied) {
      _tear.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tear.removeStatusListener(_onTearStatus);
    _tear.dispose();
    super.dispose();
  }

  Widget _card() {
    return RewardTicketCard(
      title: widget.voucher.title,
      description: widget.voucher.description,
      metaLabel: widget.voucher.expiresLabel,
      kind: widget.voucher.kind,
      imageCategory: widget.voucher.imageCategory,
      primaryLabel: widget.applied ? 'Applied' : 'Apply',
      primaryEnabled: !widget.applied,
      applied: widget.applied,
      onPrimary: widget.applied ? null : () => widget.onApply(widget.voucher),
      onDetails: () => widget.onDetails(widget.voucher),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tear,
      builder: (context, _) {
        final progress = _tear.value;
        if (progress > 0) {
          return TicketTear(progress: progress, child: _card());
        }
        // Already applied when this item was created — it's the fresh
        // instance that landed at the bottom after its tear finished, not
        // one mid-animation. Show it permanently torn.
        return widget.applied
            ? TicketTear(progress: _restTornProgress, child: _card())
            : _card();
      },
    );
  }
}

class _AnimatedTicket extends StatelessWidget {
  const _AnimatedTicket({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        alignment: const AlignmentDirectional(0, -1),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
