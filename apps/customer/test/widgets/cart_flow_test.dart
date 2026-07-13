import 'dart:async';
import 'dart:io';

import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/data/repository/mock_member_repository.dart';
import 'package:aida_customer/features/cart/cart_screen.dart';
import 'package:aida_customer/features/cart/order_confirmation_screen.dart';
import 'package:aida_customer/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end: browse to an item, configure it (size, add-on, note,
/// quantity), add it to the cart, see the floating bar update, check out,
/// and confirm the cart is empty again afterward. Exercises the real cart
/// state through the actual screens rather than testing CartState in
/// isolation — this is the sequence a customer actually performs.
const _fast = MockMemberRepository(latency: Duration.zero);

/// Menu items carry real hotlinked photo URLs (Unsplash), and this test
/// visits several screens that render them via Image.network. The test
/// sandbox has no real network access — every request fails, and
/// ProductImage's errorBuilder handles that gracefully in the UI, but the
/// underlying image *stream* also reports the failure to Flutter's global
/// error handling independently of errorBuilder, which the test framework
/// treats as an unexpected exception and fails the test on, even though
/// nothing is actually wrong.
///
/// Fixed via Flutter's own documented hook for exactly this
/// (`debugNetworkImageHttpClientProvider`, in painting/debug.dart) rather
/// than a global `HttpOverrides.global` guess — that first attempt still
/// left NetworkImage's own internal handling throwing, since it wasn't the
/// mechanism Flutter actually checks.
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

// A minimal valid 1x1 transparent PNG.
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

class _FakeHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _onePixelPng.length;

  // consolidateHttpClientResponseBytes (used internally by NetworkImage)
  // switches on this before it ever touches the byte stream — without it,
  // the fallback noSuchMethod throws before a single byte is read.
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
    return Stream<List<int>>.fromIterable([
      _onePixelPng,
    ]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('configure an item, add to cart, checkout, cart ends up empty', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = _FakeHttpClient.new;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [memberRepositoryProvider.overrideWithValue(_fast)],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    // No floating cart bar before anything is added.
    expect(find.textContaining('item'), findsNothing);

    // Go to Menu, open the Salted Caramel Latte.
    await tester.tap(find.byKey(const ValueKey('nav_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salted Caramel Latte'));
    await tester.pumpAndSettle();

    // Size and Add-ons sit below the hero photo, off the initial viewport
    // inside the detail page's SingleChildScrollView. tester.tap() on an
    // off-screen (but still built) widget computes a coordinate outside
    // the visible area and can silently land on the wrong target — scroll
    // each into view first rather than trusting an off-screen tap.
    await tester.ensureVisible(find.text('L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('L'));
    await tester.pump();

    await tester.ensureVisible(find.text('Extra Shot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extra Shot'));
    await tester.pump();

    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'less ice please');
    await tester.pump();

    // Quantity 1 -> 2. The stepper lives in the pinned bottom bar, always
    // on-screen.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();

    // 1290 (base) + 150 (L) + 300 (shot) = 1740/unit; x2 = RM 34.80.
    expect(find.text('Add to Order · RM 34.80'), findsOneWidget);
    await tester.tap(find.text('Add to Order · RM 34.80'));
    await tester.pumpAndSettle();

    // The confirmation SnackBar has a 2-second auto-dismiss Timer, which
    // pumpAndSettle does not wait through (it only waits for scheduled
    // animation frames, and a Timer isn't one) — the SnackBar's overlay
    // was still absorbing taps at the bottom of the screen, exactly where
    // the floating cart bar also lives, and intercepting the next tap.
    // Advance real time past it before doing anything else at the bottom
    // of the screen.
    await tester.pump(const Duration(seconds: 3));

    // Back out to AppShell, where the floating cart bar lives — it's still
    // covered by this pushed detail route. The back button is inside the
    // hero, part of the same scrollable content scrolled away from above.
    await tester.ensureVisible(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // The floating cart bar should now show 2 items and the same total.
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('RM 34.80'), findsWidgets);

    // Open the cart.
    await tester.tap(find.text('2 items'));
    await tester.pumpAndSettle();

    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Salted Caramel Latte'), findsOneWidget);
    expect(find.textContaining('L'), findsWidgets);
    expect(find.textContaining('Extra Shot'), findsOneWidget);
    expect(find.text('"less ice please"'), findsOneWidget);

    // Place the order.
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderConfirmationScreen), findsOneWidget);
    expect(find.text('Order Placed!'), findsOneWidget);

    // Back to Menu — should land back at the root with an empty cart.
    await tester.tap(find.text('Back to Menu'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderConfirmationScreen), findsNothing);
    expect(find.byType(CartScreen), findsNothing);
    expect(find.text('2 items'), findsNothing);

    // Must be the literal last statement, not a tearDown/addTearDown: the
    // framework's invariant check runs inside this same callback's
    // execution, before control ever returns to any teardown mechanism. If
    // an assertion above throws instead, the check is skipped entirely (see
    // `_runTestBody`'s `_pendingExceptionDetails == null` guard), so this
    // only needs to cover the success path.
    debugNetworkImageHttpClientProvider = null;
  });
}
