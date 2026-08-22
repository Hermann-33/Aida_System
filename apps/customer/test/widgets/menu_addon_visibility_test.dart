import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/features/menu/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_catalogue_repository.dart';

void main() {
  testWidgets('add-on catalogue rows and add-on-only category are not browsable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogueRepositoryProvider.overrideWithValue(
            const TestCatalogueRepository(),
          ),
        ],
        child: const MaterialApp(home: MenuScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsWidgets);
    expect(find.text('Add-ons'), findsNothing);
    expect(find.text('Extra Shot'), findsNothing);
    expect(find.text('Oat Milk'), findsNothing);
    expect(find.text('Whipped Cream'), findsNothing);
  });
}
