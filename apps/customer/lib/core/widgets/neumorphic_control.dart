import 'package:flutter/material.dart';

import '../theme/aida_colors.dart';

/// Raised / pressed soft-UI control — same language as the floating nav.
class NeumorphicControl extends StatefulWidget {
  const NeumorphicControl({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.shape = NeumorphicShape.pill,
    this.width,
    this.height = 56,
    this.selected = false,
    this.accent = false,
    /// Stronger pink fill + border — use on white sheets where cream
    /// neumorphism disappears.
    this.highContrast = false,
    /// Decoration only; [child] handles its own taps (e.g. QTY −/+).
    this.passive = false,
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final NeumorphicShape shape;
  final double? width;
  final double height;
  final bool selected;
  final bool accent;
  final bool highContrast;
  final bool passive;
  final String? semanticsLabel;

  @override
  State<NeumorphicControl> createState() => _NeumorphicControlState();
}

enum NeumorphicShape { pill, circle }

class _NeumorphicControlState extends State<NeumorphicControl> {
  bool _pressed = false;

  bool get _inset => widget.selected || _pressed;

  BorderRadius get _radius => BorderRadius.circular(999);

  LinearGradient get _gradient {
    if (widget.accent) {
      if (_inset) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AidaColors.coffee, AidaColors.coffeeLight],
        );
      }
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AidaColors.coffeeLight, AidaColors.coffee],
      );
    }
    if (widget.highContrast) {
      if (_inset) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AidaColors.latte,
            AidaColors.caramelTint,
          ],
        );
      }
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AidaColors.caramelTint,
          AidaColors.latte.withValues(alpha: 0.85),
        ],
      );
    }
    if (_inset) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AidaColors.latte.withValues(alpha: 0.95),
          AidaColors.caramelTint,
          AidaColors.cream,
        ],
        stops: const [0.0, 0.45, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AidaColors.cardWhite,
        AidaColors.cream,
        AidaColors.latte.withValues(alpha: 0.65),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  List<BoxShadow> _shadows() {
    if (_inset) {
      return [
        BoxShadow(
          color: AidaColors.espresso.withValues(
            alpha: widget.highContrast ? 0.22 : 0.32,
          ),
          offset: const Offset(5, 5),
          blurRadius: 10,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: AidaColors.cardWhite.withValues(alpha: 0.8),
          offset: const Offset(-3, -3),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color:
            widget.highContrast
                ? AidaColors.cardWhite
                : AidaColors.cardWhite,
        offset: const Offset(-4, -4),
        blurRadius: 10,
      ),
      BoxShadow(
        color:
            widget.highContrast
                ? AidaColors.espresso.withValues(alpha: 0.14)
                : AidaColors.latte.withValues(alpha: 0.95),
        offset: const Offset(5, 5),
        blurRadius: widget.highContrast ? 12 : 14,
      ),
      if (!widget.highContrast)
        BoxShadow(
          color: AidaColors.espresso.withValues(alpha: 0.07),
          offset: const Offset(0, 8),
          blurRadius: 16,
        ),
    ];
  }

  Color get _borderColor {
    if (widget.accent) {
      return AidaColors.coffee.withValues(alpha: 0.55);
    }
    if (widget.highContrast) {
      return AidaColors.coffee.withValues(alpha: 0.22);
    }
    return AidaColors.cardWhite.withValues(alpha: 0.65);
  }

  Widget _buildSurface() {
    final size =
        widget.shape == NeumorphicShape.circle ? widget.height : widget.height;

    return AnimatedScale(
      scale: _inset && !widget.passive ? 0.94 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.shape == NeumorphicShape.circle ? size : widget.width,
        height: size,
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: _radius,
          boxShadow: _shadows(),
          border: Border.all(color: _borderColor, width: 1.1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_inset && !widget.accent)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _radius,
                    gradient: RadialGradient(
                      center: const Alignment(-0.55, -0.55),
                      radius: 1.05,
                      colors: [
                        AidaColors.espresso.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding:
                  widget.shape == NeumorphicShape.pill
                      ? const EdgeInsets.symmetric(horizontal: 12)
                      : EdgeInsets.zero,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.passive) {
      return Semantics(
        container: true,
        label: widget.semanticsLabel,
        child: _buildSurface(),
      );
    }

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticsLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: _buildSurface(),
      ),
    );
  }
}
