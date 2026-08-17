import 'package:aida_customer/domain/model/menu_item.dart';
import 'package:aida_customer/domain/model/money.dart';
import 'package:aida_customer/features/home/widgets/popular_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Home grid's row height must come from a fixed `mainAxisExtent`, not a
/// `childAspectRatio`. An aspect ratio makes cell height scale with cell
/// width — fine on a phone, but `flutter run -d chrome` opens at whatever
/// width the browser tab happens to be, and on a wide desktop window that
/// stretched each card's height far past what its fixed-size photo and few
/// lines of text actually need, leaving a large dead gap.
void main() {
  const items = [
    MenuItem(
      id: 'p1',
      name: 'Salted Caramel Latte',
      category: 'Coffee',
      description: 'Silky espresso, caramel, a pinch of sea salt',
      price: Money.fromSen(1290),
      isAvailable: true,
    ),
    MenuItem(
      id: 'p2',
      name: 'Cappuccino',
      category: 'Coffee',
      description: 'Smooth espresso with rich, velvety foam',
      price: Money.fromSen(950),
      isAvailable: true,
    ),
  ];

  Widget buildGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 22,
        mainAxisExtent: 250,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => PopularItemCard(item: items[i]),
    );
  }

  Future<double> renderAtWidth(WidgetTester tester, double width) async {
    tester.view
      ..physicalSize = Size(width, 900)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: buildGrid())));
    await tester.pump();

    return tester.getSize(find.byType(PopularItemCard).first).height;
  }

  testWidgets(
    'card height stays fixed whether the window is phone-narrow or desktop-wide',
    (tester) async {
      final phoneHeight = await renderAtWidth(tester, 390);
      final desktopHeight = await renderAtWidth(tester, 1400);

      expect(phoneHeight, closeTo(250, 0.5));
      expect(desktopHeight, closeTo(250, 0.5));
    },
  );
}
