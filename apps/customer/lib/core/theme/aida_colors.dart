import 'package:flutter/material.dart';

/// Palette from PRD §19.3 — warm premium café.
abstract final class AidaColors {
  /// Primary background.
  static const cream = Color(0xFFF5EFE8);

  /// Secondary surfaces.
  static const latteBeige = Color(0xFFECDDCF);

  /// Primary actions and brand text.
  static const coffeeBrown = Color(0xFF5F3E29);

  /// High-contrast headers and controls.
  static const deepEspresso = Color(0xFF1C1108);

  /// Secondary accents.
  static const caramel = Color(0xFFCDAD8E);

  /// Student offers, promotions, brand continuity.
  static const aidaPink = Color(0xFFD98A8A);

  /// Reserved exclusively for points, rewards, tiers, and loyalty emphasis.
  /// Using this for anything else erodes the signal customers rely on.
  static const rewardGold = Color(0xFFC99A45);

  /// Cards and elevated surfaces.
  static const cardWhite = Color(0xFFFFFFFF);
}
