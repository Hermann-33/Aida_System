import 'package:flutter/material.dart';

import '../../../core/theme/aida_colors.dart';
import '../../../core/theme/aida_theme.dart';
import '../../../domain/model/offer.dart';
import '../../../core/theme/aida_type.dart';

/// A promotion banner.
///
/// Student offers wear City Red — the City U identity colour. Everything else
/// wears coffee. The colour is chosen from what the server already decided the
/// offer is; the client never evaluates eligibility itself.
class OfferBanner extends StatelessWidget {
  const OfferBanner({super.key, required this.offer, this.onTap});

  final Offer offer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isStudent = offer.isStudentOffer;
    final background = isStudent ? AidaColors.cityRed : AidaColors.coffee;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AidaTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AidaColors.cream.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isStudent ? Icons.school_rounded : Icons.local_offer_rounded,
                  color: AidaColors.cream,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.title,
                      style: AidaType.sans(
                        size: 15,
                        weight: FontWeight.w700,
                        color: AidaColors.cream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.subtitle,
                      style: AidaType.sans(
                        size: 12,
                        height: 1.35,
                        color: AidaColors.cream.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AidaColors.cream.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
