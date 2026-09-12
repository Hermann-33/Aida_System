import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/error/result.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/aida_popup.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required bool marketing,
    required bool transactional,
  }) async {
    final result = await ref
        .read(memberRepositoryProvider)
        .savePrivacyPreferences(
          marketingNotificationsEnabled: marketing,
          transactionalNotificationsEnabled: transactional,
        );
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(privacyPreferencesProvider);
      case Err(:final failure):
        AidaPopup.show(context, title: failure.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(privacyPreferencesProvider);
    return Scaffold(
      backgroundColor: AidaColors.cream,
      appBar: AppBar(
        backgroundColor: AidaColors.cream,
        foregroundColor: AidaColors.textPrimary,
        elevation: 0,
        title: Text(
          'Privacy & notifications',
          style: AidaType.serif(size: 21, color: AidaColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Text(
            'Notification choices',
            style: AidaType.serif(size: 22, color: AidaColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Marketing is opt-in. Account creation never opts you into promotional notifications.',
            style: AidaType.sans(size: 13.5, color: AidaColors.textMuted),
          ),
          const SizedBox(height: 14),
          preferences.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AidaColors.coffee),
              ),
            ),
            error: (error, _) => _ErrorCard(
              onRetry: () => ref.invalidate(privacyPreferencesProvider),
            ),
            data: (value) => Card(
              color: AidaColors.cardWhite,
              elevation: 0,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Marketing notifications'),
                    subtitle: const Text(
                      'Offers, promotions and other direct marketing.',
                    ),
                    value: value.marketingNotificationsEnabled,
                    onChanged: (enabled) => _save(
                      context,
                      ref,
                      marketing: enabled,
                      transactional: value.transactionalNotificationsEnabled,
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Transactional notifications'),
                    subtitle: const Text(
                      'Order and account-service updates. No marketing content.',
                    ),
                    value: value.transactionalNotificationsEnabled,
                    onChanged: (enabled) => _save(
                      context,
                      ref,
                      marketing: value.marketingNotificationsEnabled,
                      transactional: enabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Privacy summary',
            style: AidaType.serif(size: 22, color: AidaColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const _PolicyCard(),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: AidaColors.cardWhite,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Privacy preferences are unavailable right now.'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard();

  @override
  Widget build(BuildContext context) => Card(
    color: AidaColors.cardWhite,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What AIDA keeps',
            style: AidaType.sans(
              size: 15,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'While your account is active, AIDA stores the profile and membership data needed to provide membership and ordering features. Order records also contain commercial and operational details such as items, prices, totals, fulfilment status and café location.',
            style: AidaType.sans(size: 13.5, color: AidaColors.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            'When you delete your account',
            style: AidaType.sans(
              size: 15,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your authentication identity, profile, membership, student-verification data and notification preferences are deleted. Historical commercial records may be retained in anonymised form for legitimate transaction, audit and accounting purposes. Retained order records no longer contain your customer, membership or Auth identifier.',
            style: AidaType.sans(size: 13.5, color: AidaColors.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            'Data minimisation',
            style: AidaType.sans(
              size: 15,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AIDA does not use account creation as consent for marketing. Protected device permissions are requested only when a shipping feature requires them.',
            style: AidaType.sans(size: 13.5, color: AidaColors.textMuted),
          ),
        ],
      ),
    ),
  );
}
