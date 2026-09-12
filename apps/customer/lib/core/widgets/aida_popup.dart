import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/aida_colors.dart';
import '../theme/aida_logo.dart';
import '../theme/aida_type.dart';

/// The single, shared "brief message" popup for the whole app — replaces
/// every screen's own local `_snack`/`_comingSoon` SnackBar helper.
/// Glassmorphism card, slides/fades in from the top (not the bottom, so it
/// never fights the floating nav or cart bar), shows an auto-dismiss
/// progress bar, and can be swiped away early via its close button.
///
/// Only one popup is on screen at a time — a new call replaces whatever's
/// currently showing rather than stacking.
class AidaPopup {
  AidaPopup._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _currentEntry?.remove();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => _AidaPopupWidget(
            title: title,
            message: message,
            duration: duration,
            onDismiss: () {
              entry.remove();
              if (_currentEntry == entry) {
                _currentEntry = null;
              }
            },
          ),
    );

    _currentEntry = entry;
    Overlay.of(context).insert(entry);
  }
}

class _AidaPopupWidget extends StatefulWidget {
  const _AidaPopupWidget({
    required this.title,
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  final String title;
  final String? message;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_AidaPopupWidget> createState() => _AidaPopupWidgetState();
}

class _AidaPopupWidgetState extends State<_AidaPopupWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _progressController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _dismissTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _start();
  }

  Future<void> _start() async {
    await _entryController.forward();
    if (!mounted) return;
    _progressController.forward();
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    await _entryController.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _entryController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 14.0 : 20.0;

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 14,
      left: horizontalPadding,
      right: horizontalPadding,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(color: Colors.transparent, child: _buildPopup()),
        ),
      ),
    );
  }

  Widget _buildPopup() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          decoration: BoxDecoration(
            // Low enough that whatever's behind (blurred by the filter
            // above) actually shows through — 0.90 was nearly opaque, so
            // the blur had nothing visible to do and this just read as a
            // solid white card instead of frosted glass.
            color: AidaColors.cream.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AidaColors.cardWhite.withValues(alpha: 0.80),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AidaColors.espresso.withValues(alpha: 0.12),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AidaColors.latte.withValues(alpha: 0.30),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 38, 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _AidaBadge(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AidaType.sans(
                              size: 16,
                              weight: FontWeight.w700,
                              color: AidaColors.espresso,
                              height: 1.25,
                            ),
                          ),
                          if (widget.message != null &&
                              widget.message!.trim().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              widget.message!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AidaType.sans(
                                size: 14,
                                color: AidaColors.espresso,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: _dismiss,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AidaColors.cardWhite.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _closeIconColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 8,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (_, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: 1 - _progressController.value,
                        minHeight: 3,
                        backgroundColor: AidaColors.latte.withValues(
                          alpha: 0.55,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AidaColors.coffee,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Not an existing brand token — the close icon's muted tone doesn't match
// AidaColors.textMuted exactly, and the reference specified this one for
// this popup only.
const _closeIconColor = Color(0xFF8E6975);

/// The real Aida Café logo (see [AidaLogo]) in a white circular frame with
/// the same gold glow the gradient-and-"A" version had — swapped in place
/// of a monogram once the actual mark was the obvious better choice.
class _AidaBadge extends StatelessWidget {
  const _AidaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AidaColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AidaColors.rewardGold.withValues(alpha: 0.30),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const AidaLogo(height: 50),
    );
  }
}
