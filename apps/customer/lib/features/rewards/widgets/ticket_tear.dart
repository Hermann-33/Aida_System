import 'package:flutter/material.dart';

/// Splits [child] into two pieces along a jagged, perforation-style
/// *vertical* edge, positioned just left of [RewardTicketCard]'s coffee-cup
/// art — and tears them apart as [progress] runs 0→1.
///
/// Matches the reference tear (assets/Torn Ticket.mp4): a quick snap with a
/// touch of overshoot, not a piece flying off-screen. Both halves separate
/// a modest amount and rotate apart, then *hold* there — long enough for
/// the tear to actually register — before fading together to make way for
/// the card's reorder to the bottom of the list.
class TicketTear extends StatelessWidget {
  const TicketTear({super.key, required this.progress, required this.child});

  final double progress;
  final Widget child;

  // Just left of where the cup art starts, so the whole image tears away
  // as one piece instead of the seam slicing through the bitmap itself.
  static const _seamFraction = 0.66;

  // The snap itself: quick, with a slight overshoot as if the seam gives
  // way under tension — then settles, holding the separated pose through
  // the rest of the interval.
  static const _separate = Interval(0.0, 0.4, curve: Curves.easeOutBack);

  // Both halves fade out together, late, once the tear has had time to
  // read.
  static const _fade = Interval(0.66, 1.0, curve: Curves.easeIn);

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final motion = _separate.transform(p);
    final opacity = (1 - _fade.transform(p)).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Left piece — the ticket body: badge, title, description, and the
        // Apply/Applied button. Settles just slightly.
        Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.centerRight,
            transform:
                Matrix4.identity()
                  ..translateByDouble(-8.0 * motion, 4.0 * motion, 0, 1)
                  ..rotateZ(-0.08 * motion),
            child: ClipPath(
              clipper: const _TornEdgeClipper(
                left: true,
                seamFraction: _seamFraction,
              ),
              child: child,
            ),
          ),
        ),
        // Right piece — the coffee cup. Snaps away and rotates clear.
        Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform:
                Matrix4.identity()
                  ..translateByDouble(18.0 * motion, -11.0 * motion, 0, 1)
                  ..rotateZ(0.18 * motion),
            child: ClipPath(
              clipper: const _TornEdgeClipper(
                left: false,
                seamFraction: _seamFraction,
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// Clips to one side of a jagged zigzag line at [seamFraction] across the
/// width — a torn-paper edge instead of a clean cut. The left and right
/// clippers share the exact same zigzag coordinates, so at rest (no
/// transform applied) the two pieces interlock back into a seamless whole.
class _TornEdgeClipper extends CustomClipper<Path> {
  const _TornEdgeClipper({required this.left, required this.seamFraction});

  final bool left;
  final double seamFraction;

  static const _teeth = 9;
  static const _amplitude = 8.0;

  @override
  Path getClip(Size size) {
    final seamX = size.width * seamFraction;
    final toothHeight = size.height / _teeth;

    final path = Path();
    if (left) {
      path.moveTo(0, 0);
      path.lineTo(seamX, 0);
      for (var i = 0; i <= _teeth; i++) {
        final y = i * toothHeight;
        final x = seamX + (i.isEven ? _amplitude : -_amplitude);
        path.lineTo(x, y);
      }
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(seamX, 0);
      for (var i = 0; i <= _teeth; i++) {
        final y = i * toothHeight;
        final x = seamX + (i.isEven ? _amplitude : -_amplitude);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TornEdgeClipper oldClipper) =>
      oldClipper.left != left || oldClipper.seamFraction != seamFraction;
}
