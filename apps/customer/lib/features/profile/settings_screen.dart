import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/error/result.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/aida_popup.dart';
import '../history/order_history_screen.dart';
import 'edit_profile_screen.dart';
import 'legal_information_screen.dart';
import 'privacy_settings_screen.dart';

const _lavender = Color(0xFFD9D3E6);
const _tan = Color(0xFFEBE1C6);
const _mauve = Color(0xFFDCC7C4);
const _sageLight = Color(0xFFD3DFC7);
const _sageDark = Color(0xFFC3D3B6);
const _mustard = Color(0xFFEACE68);
const _darkIcon = Color(0xFF3A3530);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _toast(BuildContext context, String message) {
    AidaPopup.show(context, title: message);
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final member = ref.read(memberProvider).value;
    final email = member?.email;
    if (email == null || email.isEmpty) {
      _toast(context, 'No email on file for this account');
      return;
    }
    final result = await ref
        .read(memberRepositoryProvider)
        .requestPasswordReset(email: email);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        _toast(context, 'Password reset link sent to $email');
      case Err(:final failure):
        _toast(context, failure.message);
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AidaColors.cardWhite,
            title: Text(
              'Delete your account?',
              style: AidaType.serif(size: 20, color: AidaColors.textPrimary),
            ),
            content: Text(
              'This permanently deletes your sign-in identity, profile, membership, student-verification data and notification preferences. Historical café transaction records may be retained only in anonymised form for legitimate audit and accounting purposes.',
              style: AidaType.sans(size: 13.5, color: AidaColors.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AidaColors.error,
                  foregroundColor: AidaColors.cream,
                ),
                child: const Text('Delete account'),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: AidaColors.coffee),
          ),
    );

    final result = await ref.read(authStateProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (result case Err(:final failure)) {
      _toast(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberProvider).value;
    final points = ref.watch(pointsProvider);
    final stamps = ref.watch(stampCardProvider);
    final orders = ref.watch(orderHistoryProvider);

    final stampsSubtitle = stamps.when(
      data: (s) => '${s.collected}/${s.required_}',
      loading: () => '···',
      error: (_, __) => '—',
    );
    final ordersSubtitle = orders.when(
      data: (list) => '${list.length}',
      loading: () => '···',
      error: (_, __) => '—',
    );

    return Scaffold(
      backgroundColor: AidaColors.cream,
      appBar: AppBar(
        backgroundColor: AidaColors.cream,
        elevation: 0,
        foregroundColor: AidaColors.textPrimary,
        title: Text(
          'Settings',
          style: AidaType.serif(size: 22, color: AidaColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AidaColors.cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AidaColors.espresso.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                points.when(
                  data: (p) => Text(
                    '${p.balance}',
                    style: AidaType.serif(
                      size: 44,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                  loading: () => Text(
                    '···',
                    style: AidaType.serif(
                      size: 44,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                  error: (_, __) => Text(
                    '—',
                    style: AidaType.serif(
                      size: 44,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Aida Points',
                    style: AidaType.sans(
                      size: 17,
                      weight: FontWeight.w700,
                      color: AidaColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PastelTile(
                  icon: Icons.local_cafe_rounded,
                  label: 'Stamps',
                  subtitle: stampsSubtitle,
                  color: _mustard,
                  height: 128,
                  onTap: null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PastelTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  subtitle: ordersSubtitle,
                  color: _tan,
                  height: 128,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PastelTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  subtitle: 'Edit',
                  color: _mauve,
                  height: 128,
                  onTap: member == null
                      ? () => _toast(context, 'Loading your profile…')
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(member: member),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 268,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: _PastelTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Password',
                    subtitle: 'Email reset link',
                    color: _sageLight,
                    height: double.infinity,
                    onTap: () => _changePassword(context, ref),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _PastelTile(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          subtitle: 'This session',
                          color: _sageDark,
                          height: double.infinity,
                          onTap: () =>
                              ref.read(authStateProvider.notifier).logOut(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _PastelTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy',
                          subtitle: 'Preferences',
                          color: _lavender,
                          height: double.infinity,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacySettingsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PastelTile(
                  icon: Icons.gavel_rounded,
                  label: 'Terms',
                  subtitle: 'Read',
                  color: _tan,
                  height: 128,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LegalInformationScreen(
                        kind: LegalInformationKind.terms,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PastelTile(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  subtitle: 'Contact',
                  color: _sageLight,
                  height: 128,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LegalInformationScreen(
                        kind: LegalInformationKind.support,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PastelTile(
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete',
                  subtitle: 'Account',
                  color: AidaColors.error.withValues(alpha: 0.85),
                  height: 128,
                  iconColor: AidaColors.cream,
                  textColor: AidaColors.cream,
                  onTap: () => _confirmDeleteAccount(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Aida Café · Version 1.0.0',
              style: AidaType.sans(size: 12, color: AidaColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastelTile extends StatelessWidget {
  const _PastelTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.height,
    required this.onTap,
    this.iconColor = _darkIcon,
    this.textColor = _darkIcon,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final double height;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.black.withValues(alpha: 0.06),
        highlightColor: Colors.black.withValues(alpha: 0.04),
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 26, color: iconColor),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AidaType.sans(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.75),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AidaType.sans(
                      size: 19,
                      weight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
