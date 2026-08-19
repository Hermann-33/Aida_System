import 'package:flutter/material.dart';

import 'aida_colors.dart';

/// The Aida Café logo — a circular photo of the printed mark, so it's
/// clipped to a circle rather than shown as a raw rectangle (the source
/// photo has page/table edges around the emblem that a circular crop hides).
///
/// Every screen that needs the logo uses this widget, so replacing the
/// asset (a better-quality scan, a transparent PNG, etc.) is a one-file
/// change here.
class AidaLogo extends StatelessWidget {
  const AidaLogo({super.key, this.height = 40, this.onDark = false});

  final double height;

  /// Adds a thin cream ring so the logo reads clearly against an espresso
  /// surface instead of blending into it.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            onDark
                ? Border.all(
                  color: AidaColors.cream.withValues(alpha: 0.6),
                  width: 1.5,
                )
                : null,
      ),
      child: ClipOval(
        child: Image.asset('assets/images/aida_logo.jpg', fit: BoxFit.cover),
      ),
    );
  }
}
