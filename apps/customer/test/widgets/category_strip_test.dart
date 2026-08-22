import 'package:aida_customer/domain/model/menu_category.dart';
import 'package:aida_customer/features/menu/widgets/category_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The strip's centre-or-scroll switch (category_strip.dart) is a real
/// layout decision, not just visual polish — verify both branches directly
/// rather than trusting the arithmetic.
void main() {
  const categories = [
    MenuCategory(id: 'c1', name: 'Coffee', itemCount: 4),
    MenuCategory(id: 'c2', name: 'Iced Drinks', itemCount: 4),
    MenuCategory(id: 'c3', name: 'Food', itemCount: 4),
    MenuCategory(id: 'c4', name: 'Add-ons', itemCount: 3),
  ];

  Future<void> pump(WidgetTester tester, double width) async {
    tester.view
      ..physicalSize = Size(width, 300)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: const CategoryStrip(categories: categories)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('centres the row with no scrolling when everything fits', (
    tester,
  ) async {
    // 4 tiles at CategoryChip.width plus gaps is ~436; give it generous room.
    await pump(tester, 900);

    expect(find.byType(ListView), findsNothing);
    expect(find.byType(Row), findsWidgets);
    // All four are laid out simultaneously — nothing is scrolled offstage.
    for (final c in categories) {
      expect(find.text(c.name), findsOneWidget);
    }
  });

  testWidgets('scrolls when the tiles do not fit the available width', (
    tester,
  ) async {
    // Narrower than the ~436 four tiles need.
    await pump(tester, 320);

    expect(find.byType(ListView), findsOneWidget);
  });
}
