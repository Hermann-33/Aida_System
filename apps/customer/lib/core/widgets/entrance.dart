import 'package:flutter/material.dart';

/// Fades and rises a section in the moment it actually scrolls into view —
/// not once at page load. A ListView builds every one of its children
/// up front (it isn't lazy the way ListView.builder is), so a load-time
/// animation on a section below the fold finishes before the customer ever
/// scrolls down to see it: they'd only ever see it fully settled, which
/// defeats the point of animating it at all.
///
/// Visibility is tracked against an explicit [controller]/[viewportKey] pair
/// for the *page's* scroll view — not `Scrollable.maybeOf(context)`. Any
/// non-scrolling widget (a `shrinkWrap` `GridView`, say) still creates its
/// own inner `Scrollable`, and that's the one `Scrollable.maybeOf` finds for
/// a card nested inside it — its position never changes, so the reveal never
/// fires. Being explicit about which scroll view actually moves avoids that
/// trap entirely.
///
/// Give sections on a page an increasing [order] and any that become visible
/// in the same frame (e.g. everything already on-screen at first load) still
/// cascade rather than popping in together.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.controller,
    required this.viewportKey,
    required this.child,
    this.order = 0,
  });

  /// The page's own scroll controller — not the controller of any
  /// non-scrolling widget nested inside it.
  final ScrollController controller;

  /// Key on a widget that exactly wraps the scroll view, so its [RenderBox]
  /// gives this widget's position relative to the actual visible viewport.
  final GlobalKey viewportKey;

  final Widget child;

  /// Stagger step, in the rare case more than one of these becomes visible
  /// in the same frame.
  final int order;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  static const _riseMs = 420;
  static const _stepMs = 60;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;

  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    // The stagger delay is baked into the controller's own timeline (a
    // leading dead zone via Interval), not a Future.delayed/Timer — a real
    // Timer would outlive pumpAndSettle in widget tests and fail them as
    // "still pending," while controller time is frame-driven and test-safe.
    final delayMs = _stepMs * widget.order;
    final totalMs = delayMs + _riseMs;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayMs / totalMs, 1, curve: Curves.easeOutCubic),
    );
    _fade = curved;
    _rise = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    widget.controller.addListener(_checkVisibility);
    // Covers the case where this section is already on-screen before any
    // scrolling happens at all (e.g. the greeting, at the very top).
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (_revealed || !mounted) return;

    final box = context.findRenderObject();
    final viewportBox = widget.viewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox ||
        !box.hasSize ||
        viewportBox is! RenderBox ||
        !viewportBox.hasSize) {
      return;
    }

    final top = box.localToGlobal(Offset.zero, ancestor: viewportBox).dy;
    final viewportHeight = viewportBox.size.height;

    // Reveal once the section's top edge has entered the viewport (with a
    // little headroom) rather than waiting for the whole section to clear
    // the bottom edge — a tall grid would otherwise never "arrive" until
    // scrolled almost entirely past.
    if (top < viewportHeight * 0.92) {
      _revealed = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _rise, child: widget.child),
    );
  }
}

/// Shrinks its child slightly while pressed — the standard modern tactile
/// cue. Uses a [Listener] rather than a GestureDetector so it never competes
/// in the gesture arena with the child's own onTap.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
