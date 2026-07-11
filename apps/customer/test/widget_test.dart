import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/data/repository/mock_member_repository.dart';
import 'package:aida_customer/features/card/membership_card_screen.dart';
import 'package:aida_customer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Zero-latency repository, so tests are not racing the demo delay.
const _fast = MockMemberRepository(latency: Duration.zero);

Widget _wrap(Widget child) => ProviderScope(
  overrides: [memberRepositoryProvider.overrideWithValue(_fast)],
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('app boots into the shell without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [memberRepositoryProvider.overrideWithValue(_fast)],
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

      // QrImageView keeps `data` private, so we assert on the semantics label,
      // which carries the same code and is what a screen reader announces.
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.semanticsLabel, contains('AIDA-2049-7731'));
    });

    testWidgets('shows member name and code', (tester) async {
      await tester.pumpWidget(_wrap(const MembershipCardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Aida Rahman'), findsOneWidget);
      expect(find.text('MEMBER · AIDA-2049-7731'), findsOneWidget);
    });

    testWidgets('shows the verified-student pill for a verified student', (tester) async {
      await tester.pumpWidget(_wrap(const MembershipCardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Verified Student'), findsOneWidget);
    });
  });
}
