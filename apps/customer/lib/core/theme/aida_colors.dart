import 'package:flutter/material.dart';

/// The Aida core palette.
///
/// Supersedes the palette in PRD §19.3, which specified Aida/Floral Pink
/// `#D98A8A`. There is no pink in the core palette; City Red replaces it.
///
/// Hex values were read from the client's palette board on 11 Jul 2026 and are
/// approximate. Correct them here — nothing else hardcodes a colour.
abstract final class AidaColors {
  /// City U identity. Student offers, student badges, campus affiliation.
  ///
  /// NOT an error colour. See [error] — a customer must be able to tell
  /// "20% off" from "something went wrong" without reading the text.
  static const cityRed = Color(0xFFAF2626);

  /// Primary background.
  static const cream = Color(0xFFFCF8F5);

  /// Secondary surfaces, dividers, muted fills.
  static const latte = Color(0xFFE0D5C3);

  /// Primary actions and brand text.
  static const coffee = Color(0xFF7A5B44);

  /// High-contrast headers, the membership card, and dark surfaces.
  static const espresso = Color(0xFF1C120E);

  /// Reserved exclusively for points, stamps, rewards, and loyalty emphasis.
  ///
  /// Using this anywhere else erodes the one signal customers scan for.
  static const rewardGold = Color(0xFFC9A24E);

  /// Cards and elevated surfaces.
  static const cardWhite = Color(0xFFFFFFFF);

  /// Soft warm tint for image placeholders and empty states.
  static const caramelTint = Color(0xFFEADFCF);

  // --- Derived / functional ---------------------------------------------

  /// A deeper shade of [rewardGold], for gold-on-gold gradients (the stamp
  /// icon, the QR nav button). Same hue and saturation, just darker — not a
  /// second gold. The PRD palette defines exactly one gold; this keeps it
  /// that way instead of inventing a nearby hex value.
  static Color get rewardGoldDeep {
    final hsl = HSLColor.fromColor(rewardGold);
    return hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
  }

  /// Body text on light surfaces.
  static const textPrimary = espresso;

  /// Secondary text, captions, "Good morning".
  static const textMuted = Color(0xFF8A7360);

  /// Errors and destructive actions. Deliberately distinct from [cityRed] so
  /// a failure never reads as a promotion.
  static const error = Color(0xFF8C3A2E);

  /// Success, verification, confirmation.
  static const success = Color(0xFF4F6B4A);
}
