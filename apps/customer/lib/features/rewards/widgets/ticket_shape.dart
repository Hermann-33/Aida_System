import 'package:flutter/material.dart';

/// Clips a rounded rectangle with semicircle bite-outs on the left and right
/// edges at [notchFraction] of the height — the classic ticket / coupon shape
/// from the earned-rewards reference.
class TicketClipper extends CustomClipper<Path> {
  const TicketClipper({
    this.notchFraction = 0.72,
    this.notchRadius = 10,
    this.cornerRadius = 20,
  });

  /// Where the perforated seam sits, as a fraction of total height (0–1).
  final double notchFraction;
  final double notchRadius;
  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final r = cornerRadius;
    final n = notchRadius;
    final notchY = size.height * notchFraction;

    final path =
        Path()
          ..moveTo(r, 0)
          ..lineTo(size.width - r, 0)
          ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
          ..lineTo(size.width, notchY - n)
          // Right bite-out — semicircle carved into the card from the edge.
          ..arcToPoint(
            Offset(size.width, notchY + n),
            radius: Radius.circular(n),
            clockwise: false,
          )
          ..lineTo(size.width, size.height - r)
          ..arcToPoint(
            Offset(size.width - r, size.height),
            radius: Radius.circular(r),
          )
          ..lineTo(r, size.height)
          ..arcToPoint(Offset(0, size.height - r), radius: Radius.circular(r))
          ..lineTo(0, notchY + n)
          // Left bite-out.
          ..arcToPoint(
            Offset(0, notchY - n),
            radius: Radius.circular(n),
            clockwise: false,
          )
          ..lineTo(0, r)
          ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
          ..close();

    return path;
  }

  @override
  bool shouldReclip(TicketClipper oldClipper) =>
      oldClipper.notchFraction != notchFraction ||
      oldClipper.notchRadius != notchRadius ||
      oldClipper.cornerRadius != cornerRadius;
}

/// Horizontal dashed seam that sits on the ticket notch line.
class TicketDashPainter extends CustomPainter {
  const TicketDashPainter({
    required this.color,
    this.dashWidth = 5,
    this.dashGap = 4,
    this.strokeWidth = 1.2,
  });

  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(TicketDashPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashGap != dashGap ||
      oldDelegate.strokeWidth != strokeWidth;
}
