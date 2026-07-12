import 'dart:io';

import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/core/theme/aida_theme.dart';
import 'package:aida_customer/core/theme/aida_type.dart';
import 'package:aida_customer/data/repository/mock_member_repository.dart';
import 'package:aida_customer/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the screens to PNG so they can be reviewed without a device, and so
/// an unintended visual change fails a test rather than reaching the client.
///
/// Regenerate after an intentional design change:
///   flutter test --update-goldens
const _fast = MockMemberRepository(latency: Duration.zero);

/// `flutter test` substitutes a placeholder font for everything, so goldens
/// would render text as blank boxes. Load the real bundled fonts so the golden
/// shows what a customer actually sees.
Future<void> _loadFonts() async {
  Future<void> load(String family, String path) async {
    final bytes = await File(path).readAsBytes();
    await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }

  await load(AidaType.display, 'assets/fonts/${AidaType.display}.ttf');
  await load(AidaType.body, 'assets/fonts/${AidaType.body}.ttf');

  // Icons are also stubbed out in tests. Load the real icon font from the
  // Flutter SDK so the golden shows icons rather than empty squares.
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.path;
  final icons =
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(icons).existsSync()) {
    await load('MaterialIcons', icons);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532) // iPhone 13/14 at 3x
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [memberRepositoryProvider.overrideWithValue(_fast)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AidaTheme.light,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('golden: home', (tester) async {
    await pumpApp(tester);
    await expectLater(find.byType(AppShell), matchesGoldenFile('goldens/home.png'));
  });

  testWidgets('golden: home scrolled (categories + popular picks)', (tester) async {
    await pumpApp(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/home_scrolled.png'),
    );
  });

  testWidgets('golden: menu with a category selected', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('nav_menu')));
    await tester.pumpAndSettle();

    // Selecting Coffee should fill its chip and filter the list to coffee.
    await tester.tap(find.byKey(const ValueKey('menu_cat_c_coffee')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/menu_selected.png'),
    );
  });

  testWidgets('golden: membership card', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('nav_qr')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/membership_card.png'),
    );
  });
}
