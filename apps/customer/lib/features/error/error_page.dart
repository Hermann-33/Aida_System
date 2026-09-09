import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';

/// Full-page "something went wrong" state. The artwork itself (spilled cup,
/// "Oops!", the message) is one baked-in image rather than composed from
/// separate widgets — simplest thing that works for now. A later pass can
/// split the illustration from the copy so the text becomes real, localized
/// Flutter text instead of pixels.
///
/// [BoxFit.contain] is deliberate, not [BoxFit.cover]: the image already
/// frames everything (plant, gift box, cup, copy) right up to its edges, so
/// cropping to fill the screen risks cutting off the "Oops!" text on
/// devices with a different aspect ratio than the artwork's own 9:16. A
/// contain fit can leave a sliver of empty space above/below on very tall
/// or short screens, which is invisible here because the screen's own
/// background already matches the artwork's background color.
class ErrorPage extends ConsumerWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: Image.asset(
                      'assets/images/aida_error.png',
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Center(
                child: _GoHomeButton(
                  onTap: () {
                    ref.read(selectedTabProvider.notifier).select(AppTab.home);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pill, not a full-width bar — a stretched button read as too
/// heavy sitting on top of already-busy artwork. Sized to its own content,
/// with an icon for a little visual interest instead of text alone.
class _GoHomeButton extends StatelessWidget {
  const _GoHomeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: AidaColors.coffee,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AidaColors.coffee.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.home_rounded,
                size: 16,
                color: AidaColors.cardWhite,
              ),
              const SizedBox(width: 8),
              Text(
                'Go home',
                style: AidaType.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AidaColors.cardWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
