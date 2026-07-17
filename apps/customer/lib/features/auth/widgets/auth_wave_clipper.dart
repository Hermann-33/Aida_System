import 'package:flutter/material.dart';

/// Soft S-curve that lifts under the active auth tab. [progress] 0 = Sign In
/// (left peak), 1 = Sign Up (right peak) so the wave can animate between them.
class AuthWaveClipper extends CustomClipper<Path> {
  const AuthWaveClipper({required this.progress});

  /// 0 → Sign In wave, 1 → Sign Up wave.
  final double progress;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final t = progress.clamp(0.0, 1.0);

    const high = 12.0;
    const low = 56.0;

    final startY = high + (low - high) * t;
    final endY = low + (high - low) * t;
    final midY = (startY + endY) / 2;

    final path =
        Path()
          ..moveTo(0, startY)
          ..cubicTo(w * 0.22, startY, w * 0.28, midY, w * 0.5, midY)
          ..cubicTo(w * 0.72, midY, w * 0.78, endY, w, endY)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant AuthWaveClipper oldClipper) =>
      oldClipper.progress != progress;
}
