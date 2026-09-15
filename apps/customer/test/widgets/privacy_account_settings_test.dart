import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/core/error/failures.dart';
import 'package:aida_customer/core/error/result.dart';
import 'package:aida_customer/data/repository/mock_member_repository.dart';
import 'package:aida_customer/domain/model/privacy_preferences.dart';
import 'package:aida_customer/features/auth/unauthenticated_screen.dart';
import 'package:aida_customer/features/profile/legal_information_screen.dart';
import 'package:aida_customer/features/profile/privacy_settings_screen.dart';
import 'package:aida_customer/features/profile/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_order_repository.dart';

class _Phase3MemberRepository extends MockMemberRepository {
  _Phase3MemberRepository({this.deleteFailure})
    : super(latency: Duration.zero);

  final Failure? deleteFailure;
  var preferences = const PrivacyPreferences(
    marketingNotificationsEnabled: false,
    transactionalNotificationsEnabled: true,
  );
  int deleteCalls = 0;
  int saveCalls = 0;

  @override
  Future<Result<void>> deleteAccount() async {
    deleteCalls += 1;
    final failure = deleteFailure;
    return failure == null ? const Ok(null) : Err(failure);
  }

  @override
  Future<Result<PrivacyPreferences>> getPrivacyPreferences() async =>
      Ok(preferences);

  @override
  Future<Result<PrivacyPreferences>> savePrivacyPreferences({
    required bool marketingNotificationsEnabled,
    required bool transactionalNotificationsEnabled,
  }) async {
    saveCalls += 1;
    preferences = PrivacyPreferences(
      marketingNotificationsEnabled: marketingNotificationsEnabled,
      transactionalNotificationsEnabled: transactionalNotificationsEnabled,
      updatedAt: DateTime.utc(2026, 9, 12),
    );
    return Ok(preferences);
  }
}

Widget _app({
  required Widget child,
  required _Phase3MemberRepository members,
  TestOrderRepository? orders,
}) => ProviderScope(
  overrides: [
    memberRepositoryProvider.overrideWithValue(members),
    if (orders != null) orderRepositoryProvider.overrideWithValue(orders),
  ],
  child: MaterialApp(home: child),
);

Future<void> _openDeleteDialog(WidgetTester tester) async {
  final delete = find.text('Delete');
  await tester.scrollUntilVisible(delete, 300);
  await tester.pumpAndSettle();
  await tester.tap(delete);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('privacy preferences default marketing off and persist opt-in', (
    tester,
  ) async {
    final members = _Phase3MemberRepository();
    await tester.pumpWidget(
      _app(child: const PrivacySettingsScreen(), members: members),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Marketing is opt-in. Account creation never opts you into promotional notifications.',
      ),
      findsOneWidget,
    );

    final marketingTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Marketing notifications'),
    );
    final transactionalTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Transactional notifications'),
    );
    expect(marketingTile.value, isFalse);
    expect(transactionalTile.value, isTrue);

    await tester.tap(find.text('Marketing notifications'));
    await tester.pumpAndSettle();

    expect(members.saveCalls, 1);
    expect(members.preferences.marketingNotificationsEnabled, isTrue);
    expect(members.preferences.transactionalNotificationsEnabled, isTrue);
  });

  testWidgets('settings deletion explains retention and calls backend once', (
    tester,
  ) async {
    final members = _Phase3MemberRepository();
    final orders = TestOrderRepository();
    addTearDown(orders.updates.close);

    await tester.pumpWidget(
      _app(
        child: const SettingsScreen(),
        members: members,
        orders: orders,
      ),
    );
    await tester.pumpAndSettle();

    await _openDeleteDialog(tester);

    expect(find.text('Delete your account?'), findsOneWidget);
    expect(
      find.textContaining('retained only in anonymised form'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(members.deleteCalls, 1);
  });

  testWidgets('failed account deletion leaves error visible', (tester) async {
    final members = _Phase3MemberRepository(
      deleteFailure: const ServerFailure('Deletion failed'),
    );
    final orders = TestOrderRepository();
    addTearDown(orders.updates.close);

    await tester.pumpWidget(
      _app(
        child: const SettingsScreen(),
        members: members,
        orders: orders,
      ),
    );
    await tester.pumpAndSettle();

    await _openDeleteDialog(tester);
    await tester.tap(find.text('Delete account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(members.deleteCalls, 1);
    expect(find.text('Deletion failed'), findsOneWidget);
  });

  testWidgets('signed-out boundary exposes privacy terms and support', (
    tester,
  ) async {
    final members = _Phase3MemberRepository();
    await tester.pumpWidget(
      _app(child: const UnauthenticatedScreen(), members: members),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(
      find.text(
        'When you delete your account from Settings, AIDA deletes the authentication identity, profile, membership, student-verification data and notification preferences associated with that account.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('terms and support surfaces contain real customer guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalInformationScreen(kind: LegalInformationKind.terms),
      ),
    );
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.textContaining('physical food and drink'), findsOneWidget);
    expect(find.textContaining('anonymised form'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: LegalInformationScreen(kind: LegalInformationKind.support),
      ),
    );
    expect(find.text('Support'), findsOneWidget);
    expect(find.textContaining('+603 7949 1600'), findsOneWidget);
    expect(find.textContaining('Never send your password'), findsOneWidget);
  });
}
