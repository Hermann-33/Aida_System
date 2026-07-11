import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_logo.dart';
import '../../core/theme/aida_theme.dart';
import '../../domain/model/member.dart';
import '../../core/theme/aida_type.dart';

/// The membership card. CUS-04, CUS-17, CUS-22.
///
/// This is the screen a customer opens with a barista waiting, so it must
/// render with no network. The member code is immutable after registration and
/// comes from local storage — the QR never needs a server (spec §2.3).
class MembershipCardScreen extends ConsumerWidget {
  const MembershipCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberProvider);
    final points = ref.watch(pointsProvider);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My QR',
                    style: AidaType.serif(
                      size: 24,
                      weight: FontWeight.w700,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                  const AidaLogo(height: 34),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
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
                        () => const CircularProgressIndicator(color: AidaColors.coffee),
                    error: (_, __) => const _CardUnavailable(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Show this to the barista to earn points and use rewards',
                  textAlign: TextAlign.center,
                  style: AidaType.sans(size: 12, color: AidaColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.member, required this.pointsLabel});

  final Member member;
  final String pointsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AidaLogo(height: 32, onDark: true),
              if (member.tierName != null) _TierPill(label: member.tierName!),
            ],
          ),
          const SizedBox(height: 22),

          // White quiet zone around the QR. Scanners need the margin, and a
          // gradient behind the code would defeat many of them.
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: member.memberCode,
                version: QrVersions.auto,
                size: 168,
                backgroundColor: Colors.white,
                // A screen-reader user cannot see the code. Announce it.
                semanticsLabel: 'Membership QR code for ${member.memberCode}',
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AidaColors.espresso,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AidaColors.espresso,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          Text(
            member.name,
            style: AidaType.serif(
              size: 24,
              weight: FontWeight.w700,
              color: AidaColors.cream,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'MEMBER · ${member.memberCode}',
            style: AidaTheme.sectionLabel(color: AidaColors.latte),
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
                style: AidaType.sans(size: 13, color: AidaColors.latte),
              ),
            ],
          ),

          if (member.isVerifiedStudent) ...[
            const SizedBox(height: 16),
            const _VerifiedStudentPill(),
          ],
        ],
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
