import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'application/providers.dart';
import 'core/theme/aida_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';

const _supabaseUrl = String.fromEnvironment(
  'AIDA_SUPABASE_URL',
  defaultValue: 'https://eswovqxqzfevcdwwcmuh.supabase.co',
);

// Supabase publishable keys are intentionally public client configuration,
// unlike service-role/secret keys. Keeping the active AIDA publishable key as
// the default removes a fragile build-time requirement for installed demo
// builds while still allowing CI/development to override it with --dart-define.
const _supabasePublishableKey = String.fromEnvironment(
  'AIDA_SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_7WXAYCzC5ed6AdHTmskD6w_lapuztIT',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabasePublishableKey.isEmpty) {
    runApp(const _MissingBackendConfigurationApp());
    return;
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );

  runApp(const ProviderScope(child: AidaApp()));
}

class _MissingBackendConfigurationApp extends StatelessWidget {
  const _MissingBackendConfigurationApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'AIDA backend configuration is missing. '
              'Provide AIDA_SUPABASE_PUBLISHABLE_KEY at build/run time.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

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
      home: const SplashScreen(destination: AuthGate()),
    );
  }
}

/// Session state is restored by Supabase before the app starts and then kept
/// current by the AuthState listener. No client-only login flag survives here.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authStateProvider);
    return signedIn ? const AppShell() : const LoginScreen();
  }
}
