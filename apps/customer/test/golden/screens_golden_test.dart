import 'dart:io';

import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/core/theme/aida_theme.dart';
import 'package:aida_customer/core/theme/aida_type.dart';
import 'package:aida_customer/data/repository/mock_member_repository.dart';
import 'package:aida_customer/features/shell/app_shell.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_catalogue_repository.dart';

const _fast = MockMemberRepository(latency: Duration.zero);
const _catalogue = TestCatalogueRepository();
final _fixedNow = DateTime(2026, 1, 16, 14);

Future<void> _loadFonts() async {
  Future<void> load(String family, String path) async {
    final bytes = await File(path).readAsBytes();
    await (FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }

  await load(AidaType.display, 'assets/fonts/${AidaType.display}.ttf');
  await load(AidaType.body, 'assets/fonts/${AidaType.body}.ttf');

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
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberRepositoryProvider.overrideWithValue(_fast),
          catalogueRepositoryProvider.overrideWithValue(_catalogue),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AidaTheme.light,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Category/hero photos decode on a real async codec that pumpAndSettle
    // alone doesn't reliably drive to completion in a widget test — without
    // this, goldens intermittently capture an image mid-decode.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('golden: home', (tester) async {
    await withClock(Clock.fixed(_fixedNow), () async {
      await pumpApp(tester);
      await expectLater(
        find.byType(AppShell),
        matchesGoldenFile('goldens/home.png'),
      );
    });
  });

  testWidgets('golden: home scrolled (categories + popular picks)', (
    tester,
  ) async {
    await withClock(Clock.fixed(_fixedNow), () async {
      await pumpApp(tester);
      await tester.drag(
        find.byKey(const Key('home_scroll')),
        const Offset(0, -520),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppShell),
        matchesGoldenFile('goldens/home_scrolled.png'),
      );
    });
  });

  testWidgets('golden: menu with a category selected', (tester) async {
    await withClock(Clock.fixed(_fixedNow), () async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('nav_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('menu_cat_c_coffee')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppShell),
        matchesGoldenFile('goldens/menu_selected.png'),
      );
    });
  });

  testWidgets('golden: membership card', (tester) async {
    await withClock(Clock.fixed(_fixedNow), () async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('nav_qr')));
      await tester.pumpAndSettle();
      // The hero photo decodes on a real async codec that pumpAndSettle
      // alone never drives to completion in a widget test — without this,
      // the golden would capture the hero permanently blank.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppShell),
        matchesGoldenFile('goldens/membership_card.png'),
      );
    });
  });
}
