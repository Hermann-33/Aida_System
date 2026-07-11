import 'package:flutter/material.dart';

import 'aida_colors.dart';

/// Placeholder for the Aida Café logo, which is not final yet.
///
/// Every screen that needs the logo uses this widget, so dropping in the real
/// asset is a one-file change: add it to `assets/`, swap the body below, and
/// the whole app updates.
///
/// Renders a neutral reserved space rather than a stand-in mark — a wrong logo
/// shown to the client is worse than an obviously empty slot.
class AidaLogo extends StatelessWidget {
  const AidaLogo({super.key, this.height = 40, this.onDark = false});

  final double height;

  /// Inverts the placeholder for use on espresso surfaces.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final tint = onDark ? AidaColors.cream : AidaColors.textMuted;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: tint.withValues(alpha: 0.35),
            style: BorderStyle.solid,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: height * 0.35),
          child: Center(
            child: Text(
              'LOGO',
              style: TextStyle(
                fontSize: height * 0.24,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: tint.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
