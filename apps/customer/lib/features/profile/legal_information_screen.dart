import 'package:flutter/material.dart';

import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';

enum LegalInformationKind { terms, support }

class LegalInformationScreen extends StatelessWidget {
  const LegalInformationScreen({required this.kind, super.key});

  final LegalInformationKind kind;

  @override
  Widget build(BuildContext context) {
    final isTerms = kind == LegalInformationKind.terms;
    return Scaffold(
      backgroundColor: AidaColors.cream,
      appBar: AppBar(
        backgroundColor: AidaColors.cream,
        foregroundColor: AidaColors.textPrimary,
        elevation: 0,
        title: Text(
          isTerms ? 'Terms of use' : 'Support',
          style: AidaType.serif(size: 21, color: AidaColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: isTerms ? const [_TermsContent()] : const [_SupportContent()],
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) => _InfoCard(
    title: 'AIDA Café customer terms',
    children: const [
      'AIDA Café provides customer membership, catalogue browsing and café ordering services for physical food and drink.',
      'Prices, availability and accepted orders are determined by the authoritative AIDA backend. Client-displayed preview or cached information does not override server-confirmed commercial data.',
      'Customer accounts must be used only by the account holder. Membership QR or member-code possession is not authentication.',
      'Orders may be prepared or fulfilled according to the status and pickup information confirmed by AIDA. External processor settlement, refunds and delivery are not part of the current customer contract.',
      'Customers may delete their account from Settings. Identity and profile data are deleted; historical transaction records may be retained only in anonymised form for legitimate transaction, audit and accounting purposes.',
    ],
  );
}

class _SupportContent extends StatelessWidget {
  const _SupportContent();

  @override
  Widget build(BuildContext context) => const _InfoCard(
    title: 'City University Malaysia support',
    children: [
      'General contact: +603 7949 1600 / +603 7949 1624',
      'Address: Menara City U, No. 8, Jalan 51A/223, 46100 Petaling Jaya, Selangor, Malaysia.',
      'Official contact page: city.edu.my/about/contact-us/',
      'For an account or order issue, provide only the minimum information needed to identify the problem. Never send your password or reusable authentication token.',
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<String> children;

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
            title,
            style: AidaType.serif(size: 22, color: AidaColors.textPrimary),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            Text(
              children[i],
              style: AidaType.sans(size: 13.5, color: AidaColors.textMuted),
            ),
            if (i != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}
