import 'package:flutter/material.dart';

import '../../core/theme/aida_colors.dart';
import '../menu/guest_catalogue_screen.dart';
import '../profile/legal_information_screen.dart';
import 'login_screen.dart';

/// Unauthenticated customer boundary.
///
/// The published catalogue plus privacy, terms and support stay reachable
/// without creating or signing into an account. Ordering, cart, membership,
/// loyalty and customer history remain behind AuthGate. No anonymous Supabase
/// Auth identity is created for this surface.
class UnauthenticatedScreen extends StatelessWidget {
  const UnauthenticatedScreen({super.key});

  void _openLegal(BuildContext context, LegalInformationKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalInformationScreen(kind: kind),
      ),
    );
  }

  void _openGuestMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GuestCatalogueScreen()),
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
                  onPressed: () => _openGuestMenu(context),
                  child: const Text('Browse menu'),
                ),
                TextButton(
                  onPressed: () => _openLegal(
                    context,
                    LegalInformationKind.privacy,
                  ),
                  child: const Text('Privacy'),
                ),
                TextButton(
                  onPressed: () => _openLegal(
                    context,
                    LegalInformationKind.terms,
                  ),
                  child: const Text('Terms'),
                ),
                TextButton(
                  onPressed: () => _openLegal(
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
