import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/data/repository/mock_member_repository.dart';
import 'package:aida_customer/features/card/membership_card_screen.dart';
import 'package:aida_customer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/test_catalogue_repository.dart';

const _fast = MockMemberRepository(latency: Duration.zero);
const _catalogue = TestCatalogueRepository();

Widget _wrap(Widget child) => ProviderScope(
  overrides: [
    memberRepositoryProvider.overrideWithValue(_fast),
    catalogueRepositoryProvider.overrideWithValue(_catalogue),
  ],
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('app boots into the shell without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberRepositoryProvider.overrideWithValue(_fast),
          catalogueRepositoryProvider.overrideWithValue(_catalogue),
        ],
        child: const AidaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('Membership card', () {
    testWidgets('encodes the member code into the QR', (tester) async {
      await tester.pumpWidget(_wrap(const MembershipCardScreen()));
      await tester.pumpAndSettle();

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.semanticsLabel, contains('AIDA-2049-7731'));
    });

    testWidgets('shows member code and the default copy action', (tester) async {
      await tester.pumpWidget(_wrap(const MembershipCardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MEMBER · AIDA-2049-7731'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('shows the verified-student pill for a verified student', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const MembershipCardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Verified Student'), findsOneWidget);
    });
  });
}
