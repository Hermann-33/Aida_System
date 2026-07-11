import 'package:flutter/material.dart';

import 'aida_colors.dart';
import 'aida_type.dart';

/// App theme. PRD §19.
abstract final class AidaTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AidaColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AidaColors.coffee,
        secondary: AidaColors.rewardGold,
        surface: AidaColors.cardWhite,
        error: AidaColors.error,
        onPrimary: AidaColors.cream,
        onSurface: AidaColors.textPrimary,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: AidaType.serif(size: 32, color: AidaColors.textPrimary),
        headlineMedium: AidaType.serif(size: 26, color: AidaColors.textPrimary),
        headlineSmall: AidaType.serif(size: 22, color: AidaColors.textPrimary),
        titleLarge: AidaType.serif(size: 20, color: AidaColors.textPrimary),
        bodyLarge: AidaType.sans(size: 16, color: AidaColors.textPrimary),
        bodyMedium: AidaType.sans(size: 14, color: AidaColors.textPrimary),
        bodySmall: AidaType.sans(size: 12, color: AidaColors.textMuted),
        labelLarge: AidaType.sans(size: 14, weight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AidaColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  /// Section label: `AIDA POINTS BALANCE`, `BARISTA PICK`.
  static TextStyle sectionLabel({Color color = AidaColors.textMuted}) {
    return AidaType.sans(
      size: 11,
      weight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color,
    );
  }

  /// The soft warm shadow on cards. PRD §19.5.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AidaColors.espresso.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
  ];
}
