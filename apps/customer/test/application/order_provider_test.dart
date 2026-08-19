import 'package:aida_customer/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_order_repository.dart';

void main() {
  test('Realtime signal refetches authoritative order history', () async {
    final repository = TestOrderRepository();
    final container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() {
      container.dispose();
      repository.updates.close();
    });

    container.listen(orderHistoryProvider, (_, __) {});
    await container.read(orderHistoryProvider.future);
    expect(repository.historyFetches, 1);

    repository.updates.add(null);
    await Future<void>.delayed(Duration.zero);
    await container.read(orderHistoryProvider.future);
    expect(repository.historyFetches, 2);
  });
}
