import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'core/theme/aida_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: AidaApp()));
}

/// Flutter's default [MaterialScrollBehavior] only accepts touch and stylus
/// for drag-to-scroll — a mouse click-drag is ignored. That's invisible on a
/// real phone, but on the web build (a mouse, not a finger) it makes every
/// swipeable widget — the promo carousel above all — look completely dead:
/// vertical lists still respond to the mouse *wheel* (a separate mechanism),
/// so only horizontal, swipe-only widgets appear broken.
class _AidaScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class AidaApp extends StatelessWidget {
  const AidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aida Café',
      debugShowCheckedModeBanner: false,
      theme: AidaTheme.light,
      scrollBehavior: _AidaScrollBehavior(),
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen until [authStateProvider] flips true, then the
/// shell. No splash screen — nothing here needs one yet (no cached-token
/// check, no version gate), so it would just be a delay with nothing to do
/// during it.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authStateProvider);
    return signedIn ? const AppShell() : const LoginScreen();
  }
}
