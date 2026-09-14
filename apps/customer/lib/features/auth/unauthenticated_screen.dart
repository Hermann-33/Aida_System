import 'package:flutter/material.dart';

import '../../core/theme/aida_colors.dart';
import '../profile/legal_information_screen.dart';
import 'login_screen.dart';

/// Unauthenticated customer boundary.
///
/// Account-only features remain behind AuthGate, while privacy, terms and
/// support information stays reachable without creating or signing into an
/// account. No anonymous Supabase identity is created for this surface.
class UnauthenticatedScreen extends StatelessWidget {
  const UnauthenticatedScreen({super.key});

  void _open(BuildContext context, LegalInformationKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalInformationScreen(kind: kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: const LoginScreen(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: AidaColors.cardWhite,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => _open(
                    context,
                    LegalInformationKind.privacy,
                  ),
                  child: const Text('Privacy'),
                ),
                TextButton(
                  onPressed: () => _open(context, LegalInformationKind.terms),
                  child: const Text('Terms'),
                ),
                TextButton(
                  onPressed: () => _open(
                    context,
                    LegalInformationKind.support,
                  ),
                  child: const Text('Support'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
