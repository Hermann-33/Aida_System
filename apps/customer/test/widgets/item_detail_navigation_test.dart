import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/data/repository/mock_member_repository.dart';
import 'package:aida_customer/domain/model/menu_item.dart';
import 'package:aida_customer/domain/model/money.dart';
import 'package:aida_customer/features/home/widgets/popular_item_card.dart';
import 'package:aida_customer/features/menu/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_catalogue_repository.dart';

const _fast = MockMemberRepository(latency: Duration.zero);
const _catalogue = TestCatalogueRepository();

void main() {
  const item = MenuItem(
    id: 'p1',
    name: 'Salted Caramel Latte',
    category: 'Coffee',
    description: 'Silky espresso, caramel, a pinch of sea salt',
    price: Money.fromSen(1290),
    isAvailable: true,
    isStudentEligible: true,
  );

  testWidgets(
    'tapping the card opens detail with the right item, and back returns',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memberRepositoryProvider.overrideWithValue(_fast),
            catalogueRepositoryProvider.overrideWithValue(_catalogue),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PopularItemCard(
                item: item,
                onTap:
                    () => openItemDetail(
                      tester.element(find.byType(Scaffold)),
                      item,
                    ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ItemDetailScreen), findsNothing);

      await tester.tap(find.byType(PopularItemCard));
      await tester.pumpAndSettle();

      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(find.text('Salted Caramel Latte'), findsOneWidget);
      expect(find.text('RM 12.90'), findsOneWidget);
      expect(find.text('Student offer eligible'), findsOneWidget);
      expect(find.textContaining('pts'), findsNothing);

      await tester.ensureVisible(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ItemDetailScreen), findsNothing);
    },
  );

  testWidgets('sold-out item shows the Sold out tag', (tester) async {
    const soldOut = MenuItem(
      id: 'p2',
      name: 'Butter Croissant',
      category: 'Food',
      description: 'Flaky, buttery, baked this morning',
      price: Money.fromSen(750),
      isAvailable: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberRepositoryProvider.overrideWithValue(_fast),
          catalogueRepositoryProvider.overrideWithValue(_catalogue),
        ],
        child: const MaterialApp(home: ItemDetailScreen(item: soldOut)),
      ),
    );
    await tester.pumpAndSettle();

    // The redesign intentionally repeats the unavailable state in the product
    // tag and in the disabled bottom action so it remains visible at both ends
    // of the scrollable detail screen.
    expect(find.text('Sold out'), findsNWidgets(2));
  });
}
