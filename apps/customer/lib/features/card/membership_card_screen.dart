import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_logo.dart';
import '../../core/theme/aida_theme.dart';
import '../../core/widgets/aida_popup.dart';
import '../../domain/model/member.dart';
import '../../core/theme/aida_type.dart';
import '../rewards/widgets/ticket_shape.dart';

/// The membership card. CUS-04, CUS-17, CUS-22.
///
/// This is the screen a customer opens with a barista waiting, so it must
/// render with no network. The member code is immutable after registration and
/// comes from local storage — the QR never needs a server (spec §2.3).
class MembershipCardScreen extends ConsumerWidget {
  const MembershipCardScreen({super.key});

  static const _heroHeight = 260.0;
  static const _cardOverlap = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(displayedMemberProvider);
    final points = ref.watch(pointsProvider);

    // Fixed, non-scrolling layout by design: this is a single ticket, shown
    // once with a barista waiting, not a page of content to scroll through.
    return Scaffold(
      backgroundColor: AidaColors.latte,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _heroHeight,
            child: _Hero(),
          ),
          Positioned(
            top: _heroHeight - _cardOverlap,
            left: 20,
            right: 20,
            // AppShell's Scaffold uses extendBody: true, so nothing reserves
            // space for the floating nav automatically — clear it by the
            // same amount FloatingCartBar does (80 tall nav + 14 bottom
            // padding, rounded up).
            bottom: 112,
            child: member.when(
              data:
                  (m) => _Card(
                    member: m,
                    pointsLabel: points.maybeWhen(
                      data: (p) => p.formatted,
                      orElse: () => '—',
                    ),
                  ),
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: AidaColors.coffee),
                  ),
              error: (_, __) => const Center(child: _CardUnavailable()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo hero + fade, same device as the Item detail hero.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/qr_hero.webp',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AidaColors.espresso.withValues(alpha: 0.55),
                AidaColors.espresso.withValues(alpha: 0.15),
                AidaColors.latte,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My QR',
                  style: AidaType.serif(size: 24, color: AidaColors.cream),
                ),
                const AidaLogo(height: 34, onDark: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.member, required this.pointsLabel});

  final Member member;
  final String pointsLabel;

  static const _notchRadius = 10.0;

  /// Fixed height for the name/code/points block below the seam — enough
  /// to hold the optional Verified Student pill without the QR region
  /// above having to guess at it too, but no more than that; both 208 and
  /// 168 still read as too much empty space once the name row was
  /// replaced by the Share button.
  static const _detailsHeight = 156.0;

  Future<void> _copyMemberCode(BuildContext context, Member member) async {
    await Clipboard.setData(ClipboardData(text: member.memberCode));
    if (context.mounted) {
      AidaPopup.show(context, title: 'Membership code copied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final notchFraction =
            totalHeight > 0
                ? (1 - (_detailsHeight / totalHeight)).clamp(0.35, 0.85)
                : 0.62;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: TicketClipper(
                notchFraction: notchFraction,
                notchRadius: _notchRadius,
                cornerRadius: 28,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (member.tierName != null)
                              _TierPill(label: member.tierName!),
                            Expanded(
                              child: Center(
                                child: _QrPanel(memberCode: member.memberCode),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Dashed seam aligned with the side notches — the same
                    // ticket perforation used by the Rewards voucher cards.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _notchRadius + 4,
                      ),
                      child: CustomPaint(
                        painter: TicketDashPainter(
                          color: AidaColors.cream.withValues(alpha: 0.35),
                        ),
                        child: const SizedBox(
                          height: 1,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _detailsHeight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEMBER · ${member.memberCode}',
                              style: AidaTheme.sectionLabel(
                                color: AidaColors.latte,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  pointsLabel,
                                  style: AidaType.serif(
                                    size: 26,
                                    weight: FontWeight.w700,
                                    color: AidaColors.rewardGold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Aida Points',
                                  style: AidaType.sans(
                                    size: 13,
                                    color: AidaColors.latte,
                                  ),
                                ),
                              ],
                            ),
                            if (member.isVerifiedStudent) ...[
                              const SizedBox(height: 12),
                              const _VerifiedStudentPill(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Inset from the true corner, not flush against it — sitting
            // right at the edge read as cramped.
            Positioned(
              right: 16,
              bottom: 16,
              child: _ShareCornerButton(onTap: () => _copyMemberCode(context, member)),
            ),
          ],
        );
      },
    );
  }
}

/// The QR itself, sized to fill the space freed by removing the in-card
/// logo. Quiet zone is a soft brand pink instead of stark white — still
/// light enough for scanners, matching the app's palette instead of a
/// generic white card.
class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.memberCode});

  final String memberCode;

  static const _maxSize = 260.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide.clamp(120.0, _maxSize);
        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AidaColors.latte,
            borderRadius: BorderRadius.circular(20),
          ),
          child: QrImageView(
            data: memberCode,
            version: QrVersions.auto,
            backgroundColor: AidaColors.latte,
            // A screen-reader user cannot see the code. Announce it.
            semanticsLabel: 'Membership QR code for $memberCode',
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AidaColors.espresso,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AidaColors.espresso,
            ),
          ),
        );
      },
    );
  }
}

/// Glossy pill matching the client's own exact corner spec — left side
/// fully rounded, top-right a sharp square corner, bottom-right a distinct,
/// more moderate round (not matching either the left side or the top-right).
/// Every corner is independently specified per their latest correction;
/// nothing here is a guessed/derived shape. Colors, border, and shadow are
/// the client's own working Flutter code, given directly.
class _ShareCornerButton extends StatelessWidget {
  const _ShareCornerButton({required this.onTap});

  final VoidCallback onTap;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(30),
    bottomLeft: Radius.circular(30),
    topRight: Radius.circular(6),
    bottomRight: Radius.circular(20),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: _radius,
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: _radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AidaColors.coffee,
                AidaColors.latte,
                AidaColors.caramelTint,
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AidaColors.coffee.withValues(alpha: 0.32),
                blurRadius: 20,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Text(
            'Copy',
            style: AidaType.sans(
              size: 17,
              weight: FontWeight.w400,
              color: AidaColors.espresso,
            ),
          ),
        ),
      ),
    );
  }
}

class _TierPill extends StatelessWidget {
  const _TierPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AidaColors.rewardGold, width: 1.2),
      ),
      child: Text(
        label.toUpperCase(),
        style: AidaTheme.sectionLabel(color: AidaColors.rewardGold),
      ),
    );
  }
}

class _VerifiedStudentPill extends StatelessWidget {
  const _VerifiedStudentPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AidaColors.cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_rounded, size: 15, color: AidaColors.cityRed),
          const SizedBox(width: 7),
          Text(
            'Verified Student',
            style: AidaType.sans(
              size: 12.5,
              weight: FontWeight.w700,
              color: AidaColors.cityRed,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown only if the member code is genuinely unavailable, which should be
/// impossible once a member has registered on this device.
class _CardUnavailable extends StatelessWidget {
  const _CardUnavailable();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_2_rounded, size: 48, color: AidaColors.latte),
        const SizedBox(height: 12),
        Text(
          'Your card is not available yet.\nSign in to see your membership QR.',
          textAlign: TextAlign.center,
          style: AidaType.sans(size: 13, color: AidaColors.textMuted),
        ),
      ],
    );
  }
}
