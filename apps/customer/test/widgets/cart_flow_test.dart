import 'dart:async';
import 'dart:io';

import 'package:aida_customer/application/order_checkout.dart';
import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/core/error/failures.dart';
import 'package:aida_customer/data/repository/mock_member_repository.dart';
import 'package:aida_customer/domain/model/cart.dart';
import 'package:aida_customer/domain/model/order.dart';
import 'package:aida_customer/features/cart/cart_screen.dart';
import 'package:aida_customer/features/cart/order_confirmation_screen.dart';
import 'package:aida_customer/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_catalogue_repository.dart';
import '../support/test_order_repository.dart';

const _fast = MockMemberRepository(latency: Duration.zero);
const _catalogue = TestCatalogueRepository();

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeHttpResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _onePixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  10,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  0,
  1,
  0,
  0,
  5,
  0,
  1,
  13,
  10,
  45,
  180,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];

class _FakeHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _onePixelPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_onePixelPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('configure an item, add to cart, checkout, cart ends up empty', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = _FakeHttpClient.new;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memberRepositoryProvider.overrideWithValue(_fast),
            catalogueRepositoryProvider.overrideWithValue(_catalogue),
            orderRepositoryProvider.overrideWithValue(TestOrderRepository()),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('nav_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salted Caramel Latte'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Large'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Large'));
      await tester.pump();

      await tester.ensureVisible(find.text('Extra Shot'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Extra Shot'));
      await tester.pump();

      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'less ice please');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      final addButton = find.text('Add to cart · RM 34.80');
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      await tester.ensureVisible(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('floating_cart_bar')), findsOneWidget);
      expect(find.text('RM 34.80'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('floating_cart_bar')));
      await tester.pumpAndSettle();

      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('Salted Caramel Latte'), findsOneWidget);
      expect(find.textContaining('Large'), findsWidgets);
      expect(find.textContaining('Extra Shot'), findsOneWidget);
      expect(find.text('"less ice please"'), findsOneWidget);

      await tester.tap(find.text('Review order'));
      await tester.pumpAndSettle();
      expect(find.text('Server total'), findsOneWidget);
      expect(find.text('RM 34.80'), findsWidgets);
      await tester.tap(find.text('Place order · RM 34.80'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderConfirmationScreen), findsOneWidget);
      expect(find.text('Order confirmed'), findsOneWidget);

      await tester.tap(find.text('Back to Menu'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderConfirmationScreen), findsNothing);
      expect(find.byType(CartScreen), findsNothing);
      expect(find.byKey(const ValueKey('floating_cart_bar')), findsNothing);
    } finally {
      // Flutter verifies painting debug globals before package:test teardown
      // callbacks run, so restore this test-only image client in the body.
      debugNetworkImageHttpClientProvider = null;
    }
  });

  testWidgets('placement failure retains cart selections for retry', (
    tester,
  ) async {
    final orders = TestOrderRepository(
      placeFailure: const ServerFailure('Connection lost'),
    );
    final container = ProviderContainer(
      overrides: [
        memberRepositoryProvider.overrideWithValue(_fast),
        catalogueRepositoryProvider.overrideWithValue(_catalogue),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(cartProvider.notifier)
        .add(
          const CartLineItem(
            item: TestCatalogueRepository.latte,
            size: TestCatalogueRepository.large,
            addOnIds: ['p_shot'],
            quantity: 2,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order · RM 34.80'));
    await tester.pumpAndSettle();

    expect(find.text('Connection lost'), findsOneWidget);
    expect(container.read(cartProvider).itemCount, 2);
    expect(orders.placedRequests.single.clientRequestId, isNotNull);
  });

  testWidgets('scheduled checkout submits only a server-policy-derived slot', (
    tester,
  ) async {
    final orders = TestOrderRepository();
    final container = ProviderContainer(
      overrides: [
        memberRepositoryProvider.overrideWithValue(_fast),
        catalogueRepositoryProvider.overrideWithValue(_catalogue),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(cartProvider.notifier)
        .add(
          const CartLineItem(
            item: TestCatalogueRepository.latte,
            size: TestCatalogueRepository.large,
            addOnIds: ['p_shot'],
            quantity: 1,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review order'));
    await tester.pumpAndSettle();

    expect(orders.quotedRequests.single.fulfillmentType, FulfillmentType.asap);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    final scheduled = orders.quotedRequests.last;
    final allowedSlots = derivePickupSlots(TestOrderRepository.policy);
    expect(scheduled.fulfillmentType, FulfillmentType.scheduled);
    expect(scheduled.requestedPickupAt, isNotNull);
    expect(allowedSlots, contains(scheduled.requestedPickupAt));
    expect(
      scheduled.requestedPickupAt!.difference(allowedSlots.first),
      Duration.zero,
    );
  });
}
