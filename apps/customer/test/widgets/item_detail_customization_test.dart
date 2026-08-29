import 'dart:io';

import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/core/error/result.dart';
import 'package:aida_customer/core/theme/aida_theme.dart';
import 'package:aida_customer/core/theme/aida_type.dart';
import 'package:aida_customer/domain/model/catalogue_snapshot.dart';
import 'package:aida_customer/domain/model/menu_category.dart';
import 'package:aida_customer/domain/model/menu_customization.dart';
import 'package:aida_customer/domain/model/menu_item.dart';
import 'package:aida_customer/domain/model/menu_variant.dart';
import 'package:aida_customer/domain/model/money.dart';
import 'package:aida_customer/domain/repository/catalogue_repository.dart';
import 'package:aida_customer/features/menu/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _hotUnavailable = MenuCustomizationOption(
  id: 'hot',
  code: 'hot',
  label: 'Hot',
  priceDeltaSen: 0,
  isDefault: false,
  isAvailable: false,
  sortOrder: 10,
);

const _longIced = MenuCustomizationOption(
  id: 'iced-long',
  code: 'iced',
  label: 'Iced — extra chilled for a brighter, colder finish',
  priceDeltaSen: 125,
  isDefault: true,
  isAvailable: true,
  sortOrder: 20,
);

const _regular = MenuCustomizationOption(
  id: 'regular',
  code: 'regular',
  label: 'Regular',
  priceDeltaSen: 0,
  isDefault: true,
  isAvailable: true,
  sortOrder: 10,
);

const _lessSweet = MenuCustomizationOption(
  id: 'less-sweet',
  code: 'less-sweet',
  label: 'Less sweet',
  priceDeltaSen: 50,
  isDefault: false,
  isAvailable: true,
  sortOrder: 20,
);

const _responsiveDrink = MenuItem(
  id: 'responsive-drink',
  categoryId: 'drinks',
  sku: 'DR-RESP',
  name: 'Iced Campus Latte',
  category: 'Drinks',
  description: 'A chilled espresso drink configured by the café catalogue.',
  price: Money.fromSen(1000),
  isAvailable: true,
  isDrink: true,
  variants: [
    MenuVariant(
      id: 'medium',
      code: 'medium',
      label: 'Medium',
      priceDeltaSen: 0,
      isDefault: true,
      isAvailable: true,
      sortOrder: 10,
    ),
  ],
  compatibleAddOnIds: ['boba'],
  customizationGroups: [
    MenuCustomizationGroup(
      id: 'temperature',
      code: 'temperature',
      name: 'Temperature',
      sortOrder: 10,
      options: [_hotUnavailable, _longIced],
    ),
    MenuCustomizationGroup(
      id: 'sweetness',
      code: 'sweetness',
      name: 'Sweetness',
      sortOrder: 20,
      options: [_regular, _lessSweet],
    ),
  ],
);

const _boba = MenuItem(
  id: 'boba',
  categoryId: 'addons',
  sku: 'AD-BOBA',
  kind: 'addon',
  name: 'Boba',
  category: 'Add-ons',
  description: 'Chewy tapioca pearls',
  price: Money.fromSen(200),
  isAvailable: true,
);

class _ResponsiveCatalogue implements CatalogueRepository {
  const _ResponsiveCatalogue();

  @override
  Future<Result<CatalogueSnapshot>> getCatalogue() async => const Ok(
    CatalogueSnapshot(
      revision: 1,
      categories: [MenuCategory(id: 'drinks', name: 'Drinks', itemCount: 1)],
      items: [_responsiveDrink, _boba],
    ),
  );

  @override
  Stream<int> watchRevision() => const Stream.empty();
}

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

Future<void> _pumpItemDetail(
  WidgetTester tester,
  Size viewport, {
  double textScale = 1.2,
}) async {
  tester.view
    ..physicalSize = viewport
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogueRepositoryProvider.overrideWithValue(
          const _ResponsiveCatalogue(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AidaTheme.light,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
        home: const ItemDetailScreen(item: _responsiveDrink),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  for (final viewport in const [Size(390, 844), Size(430, 932)]) {
    testWidgets(
      'item detail is usable at ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        await _pumpItemDetail(tester, viewport);

        expect(find.text('Beverage size'), findsOneWidget);
        expect(find.text('Temperature'), findsOneWidget);
        expect(find.text('Sweetness'), findsOneWidget);
        expect(find.text('Customize'), findsOneWidget);
        expect(find.text('Hot'), findsOneWidget);
        expect(find.text('Unavailable'), findsOneWidget);
        expect(find.text('+RM 1.25'), findsOneWidget);

        final hot = find.byKey(const ValueKey('drink_option_temperature_hot'));
        final iced = find.byKey(
          const ValueKey('drink_option_temperature_iced'),
        );
        expect(find.text(_longIced.label), findsOneWidget);
        // Selection reads through border/text color now, not a checkmark
        // badge — Temperature options do get a recognizable hot/cold icon.
        expect(
          find.descendant(
            of: iced,
            matching: find.byIcon(Icons.ac_unit_rounded),
          ),
          findsOneWidget,
        );

        await tester.ensureVisible(hot);
        await tester.tap(hot, warnIfMissed: false);
        await tester.pump();
        expect(find.text('Add to cart · RM 11.25'), findsOneWidget);

        await tester.ensureVisible(find.text('Less sweet'));
        await tester.tap(find.text('Less sweet'));
        await tester.pump();
        await tester.ensureVisible(find.text('Boba'));
        await tester.tap(find.text('Boba'));
        await tester.pump();
        expect(find.text('Add to cart · RM 13.75'), findsOneWidget);

        final note = find.byType(TextField);
        await tester.ensureVisible(note);
        await tester.enterText(note, 'No straw, please');
        await tester.showKeyboard(note);
        await tester.pump();

        final icedRect = tester.getRect(iced);
        expect(icedRect.left, greaterThanOrEqualTo(0));
        expect(icedRect.right, lessThanOrEqualTo(viewport.width));
        expect(icedRect.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('golden: item detail customization at 390x844', (tester) async {
    await _pumpItemDetail(tester, const Size(390, 844), textScale: 1);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -430),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ItemDetailScreen),
      matchesGoldenFile('../golden/goldens/item_detail_customization_390.png'),
    );
  });

  testWidgets('golden: item detail customization at 430x932', (tester) async {
    await _pumpItemDetail(tester, const Size(430, 932));
    await tester.ensureVisible(find.text('Less sweet'));
    await tester.tap(find.text('Less sweet'));
    await tester.pump();
    await tester.ensureVisible(find.text('Boba'));
    await tester.tap(find.text('Boba'));
    await tester.pump();

    await expectLater(
      find.byType(ItemDetailScreen),
      matchesGoldenFile('../golden/goldens/item_detail_customization_430.png'),
    );
  });
}
