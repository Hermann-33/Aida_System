import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/aida_colors.dart';
import '../../main.dart' show AuthGate;

/// Plays the bundled brand video once, then hands off to [AuthGate].
///
/// The video itself (assets/images/splash_screen.mp4) is trimmed to 1.5s
/// with a built-in fade to [AidaColors.cream] at its tail — the same
/// background every real destination (LoginScreen, AppShell) opens on, so
/// the handoff is invisible instead of a dark-splash-to-light-app flash.
/// This screen's own Scaffold stays [AidaColors.espresso] instead — that's
/// the video's own opening tone, and is only ever visible for the brief
/// gap before the video initializes. The route change into [AuthGate] is a
/// plain cross-fade on top of that color match, not the thing doing the
/// smoothing on its own.
///
/// Never gets stuck showing a blank/frozen screen: a failed or missing video
/// (asset error, unsupported codec on some device, plugin unavailable in a
/// test harness) falls through to the app immediately, and a safety timer
/// covers a video that initializes but never reports finishing. Tapping
/// anywhere skips straight to the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final controller = VideoPlayerController.asset(
      'assets/images/splash_screen.mp4',
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.setVolume(0);
      await controller.play();
      controller.addListener(_onTick);
      // The video itself runs 1.5s; this is only a fallback for the rare
      // case its completion callback never fires.
      Future.delayed(const Duration(seconds: 3), _goToApp);
    } catch (_) {
      await controller.dispose();
      _goToApp();
    }
  }

  void _onTick() {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;
    final duration = value.duration;
    if (duration > Duration.zero && value.position >= duration) {
      _goToApp();
    }
  }

  void _goToApp() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: AidaColors.espresso,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToApp,
        child:
            ready
                ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                )
                : const SizedBox.expand(),
      ),
    );
  }
}
