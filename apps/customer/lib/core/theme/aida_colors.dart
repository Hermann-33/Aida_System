import 'package:flutter/material.dart';

/// The Aida palette — v3 "Rose": red / pink / white, per client direction on
/// 16 Jul 2026. Supersedes the v2.2 Core Palette (cream/coffee tones) the
/// same way that palette superseded the original pink one; see PRD §19.3.
///
/// Identifier names (cream, latte, coffee, espresso) are kept from the
/// coffee-toned palette so no screen needed touching in the switch — the
/// doc comment on each is its actual role, and the role is what governs use.
///
/// Values are provisional, chosen to demo the direction. Correct them here —
/// nothing else hardcodes a colour.
abstract final class AidaColors {
  /// City U identity. Student offers, student badges, campus affiliation.
  ///
  /// NOT an error colour, and deliberately a deeper brick red than [coffee]
  /// so the student signal stays its own thing in a red-accented UI.
  static const cityRed = Color(0xFFAF2626);

  /// Primary background. Blush-tinted white.
  static const cream = Color(0xFFFDF6F7);

  /// Secondary surfaces, dividers, muted fills. Soft pink.
  static const latte = Color(0xFFF2CFD6);

  /// Primary actions and brand text. Raspberry red — warmer and brighter
  /// than [cityRed] so buttons never read as a student badge.
  static const coffee = Color(0xFFC13A52);

  /// High-contrast headers, the membership card, and dark surfaces.
  /// Near-black with a plum undertone to sit naturally under the pinks.
  static const espresso = Color(0xFF27121A);

  /// Reserved exclusively for points, stamps, rewards, and loyalty emphasis.
  ///
  /// Using this anywhere else erodes the one signal customers scan for.
  /// Kept from the previous palette — loyalty gold is a functional signal,
  /// not a theme colour.
  static const rewardGold = Color(0xFFC9A24E);

  /// Cards and elevated surfaces.
  static const cardWhite = Color(0xFFFFFFFF);

  /// Soft pink tint for image placeholders and empty states.
  static const caramelTint = Color(0xFFF7DEE3);

  // --- Derived / functional ---------------------------------------------

  /// A deeper shade of [rewardGold], for gold-on-gold gradients (the stamp
  /// icon, the QR nav button). Same hue and saturation, just darker — not a
  /// second gold. The palette defines exactly one gold; this keeps it
  /// that way instead of inventing a nearby hex value.
  static Color get rewardGoldDeep {
    final hsl = HSLColor.fromColor(rewardGold);
    return hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
  }

  /// A lighter tint of [coffee], for primary-action gradients (the selected
  /// size pill). Same hue/saturation as the action colour, just lighter —
  /// not a second accent, the same way [rewardGoldDeep] isn't a second gold.
  static Color get coffeeLight {
    final hsl = HSLColor.fromColor(coffee);
    return hsl.withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0)).toColor();
  }

  /// Body text on light surfaces.
  static const textPrimary = espresso;

  /// Secondary text, captions, "Good morning". Muted mauve.
  static const textMuted = Color(0xFF976B77);

  /// Errors and destructive actions. Deliberately distinct from [cityRed]
  /// and [coffee] — burnt sienna rather than a third red — so a failure
  /// never reads as a promotion or a button.
  static const error = Color(0xFF8C3A2E);

  /// Success, verification, confirmation.
  static const success = Color(0xFF4F6B4A);

  /// A lighter tint of [success], for the same reason [coffeeLight] exists —
  /// a gradient's light stop, not a second success colour.
  static Color get successLight {
    final hsl = HSLColor.fromColor(success);
    return hsl.withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0)).toColor();
  }
}
