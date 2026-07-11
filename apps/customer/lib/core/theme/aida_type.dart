import 'package:flutter/material.dart';

/// The two typefaces, bundled as assets (see pubspec.yaml).
///
/// Deliberately not `google_fonts`: that package fetches from the network on
/// first use, which would break the offline membership card (CUS-22) and make
/// the app look broken to a customer on dead campus wifi.
abstract final class AidaType {
  /// Playfair Display — headings, member name, points figures. PRD §19.4.
  static const display = 'PlayfairDisplay';

  /// Plus Jakarta Sans — body and UI. PRD §19.4.
  static const body = 'PlusJakartaSans';

  static TextStyle serif({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle sans({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: body,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
