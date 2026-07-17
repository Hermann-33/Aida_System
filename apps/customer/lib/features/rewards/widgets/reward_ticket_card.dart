import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_type.dart';
import '../../../core/widgets/entrance.dart';
import '../../../domain/model/reward.dart';
import 'ticket_shape.dart';

/// Ticket-shaped reward card — Starbucks-style layout, Aida Rose colours.
///
/// Shared by the earned voucher wallet and the points catalogue so both
/// sections feel like one Rewards surface (CUS-06).
class RewardTicketCard extends StatelessWidget {
  const RewardTicketCard({
    super.key,
    required this.title,
    required this.description,
    required this.metaLabel,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onDetails,
    this.kind = RewardKind.voucher,
    this.imageCategory = 'Drinks',
    this.primaryEnabled = true,
    this.showRewardBadge = true,
  });

  final String title;
  final String description;

  /// Expiry line for vouchers, or points cost for the catalogue.
  final String metaLabel;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onDetails;
  final RewardKind kind;
  final String imageCategory;
  final bool primaryEnabled;
  final bool showRewardBadge;

  static const _notchFraction = 0.72;
  static const _notchRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: ClipPath(
        clipper: const TicketClipper(
          notchFraction: _notchFraction,
          notchRadius: _notchRadius,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Soft Rose wash — cream → latte pink with a whisper of gold so
            // the ticket feels branded without drowning the text.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AidaColors.cardWhite,
                AidaColors.cream,
                AidaColors.latte.withValues(alpha: 0.72),
                AidaColors.rewardGold.withValues(alpha: 0.18),
              ],
              stops: const [0.0, 0.35, 0.78, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showRewardBadge) ...[
                            const _RewardBadge(),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            title,
                            style: AidaType.sans(
                              size: 18,
                              weight: FontWeight.w700,
                              color: AidaColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: AidaType.sans(
                              size: 13,
                              color: AidaColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            metaLabel,
                            style: AidaType.sans(
                              size: 11,
                              weight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: AidaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TicketArt(kind: kind),
                  ],
                ),
              ),
              // Dashed seam aligned with the side notches.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _notchRadius + 4,
                ),
                child: CustomPaint(
                  painter: TicketDashPainter(
                    color: AidaColors.coffee.withValues(alpha: 0.22),
                  ),
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Row(
                  children: [
                    _ApplyButton(
                      label: primaryLabel,
                      enabled: primaryEnabled,
                      onTap: onPrimary,
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: onDetails,
                      child: Text(
                        'Details',
                        style: AidaType.sans(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AidaColors.coffee,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AidaColors.coffee,
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
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AidaColors.espresso,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: AidaColors.rewardGold),
          const SizedBox(width: 5),
          Text(
            'REWARD',
            style: AidaType.sans(
              size: 10,
              weight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AidaColors.cardWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AidaColors.coffee : AidaColors.latte,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Text(
            label,
            style: AidaType.sans(
              size: 14,
              weight: FontWeight.w700,
              color: enabled ? AidaColors.cardWhite : AidaColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Geometric accents + a real coffee-cup cutout (transparent PNG).
class _TicketArt extends StatelessWidget {
  const _TicketArt({required this.kind});

  final RewardKind kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 118,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 6,
            right: 2,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 34,
                height: 34,
                color: AidaColors.rewardGold.withValues(alpha: 0.4),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            left: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AidaColors.latte.withValues(alpha: 0.95),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 8,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AidaColors.coffee,
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            right: 8,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AidaColors.rewardGold.withValues(alpha: 0.75),
              ),
            ),
          ),
          // Transparent cutout — sits above the shapes like the reference.
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/coffee_cup.png',
              width: 88,
              height: 112,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder:
                  (_, __, ___) =>
                      Icon(_iconFor(kind), size: 48, color: AidaColors.coffee),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(RewardKind kind) => switch (kind) {
    RewardKind.voucher => Icons.local_offer_rounded,
    RewardKind.freeItem => Icons.bakery_dining_rounded,
    RewardKind.freeDrink => Icons.local_cafe_rounded,
  };
}
