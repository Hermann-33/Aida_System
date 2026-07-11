import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/aida_theme.dart';
import 'features/shell/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: AidaApp()));
}

class AidaApp extends StatelessWidget {
  const AidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aida Café',
      debugShowCheckedModeBanner: false,
      theme: AidaTheme.light,
      // Auth (C2) is not built yet, so the app opens straight into the shell
      // with demo data. The splash → login → shell flow lands with C2.
      home: const AppShell(),
    );
  }
}
