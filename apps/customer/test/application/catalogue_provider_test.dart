import 'dart:async';

import 'package:aida_customer/application/providers.dart';
import 'package:aida_customer/core/error/result.dart';
import 'package:aida_customer/domain/model/catalogue_snapshot.dart';
import 'package:aida_customer/domain/repository/catalogue_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/test.dart';

void main() {
  test(
    'catalogue revision event re-fetches the authoritative snapshot',
    () async {
      final repository = _RevisionCatalogueRepository();
      final container = ProviderContainer(
        overrides: [catalogueRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });

      final refreshed = Completer<CatalogueSnapshot>();
      final subscription = container.listen(catalogueProvider, (_, next) {
        if (next case AsyncData(
          value: final snapshot,
        ) when snapshot.revision == 2) {
          refreshed.complete(snapshot);
        }
      }, fireImmediately: true);
      addTearDown(subscription.close);

      final initial = await container.read(catalogueProvider.future);
      expect(initial.revision, 1);
      expect(repository.fetchCount, 1);

      repository.emitRevision(2);

      final updated = await refreshed.future.timeout(
        const Duration(seconds: 1),
      );
      expect(updated.revision, 2);
      expect(repository.fetchCount, 2);
    },
  );
}

class _RevisionCatalogueRepository implements CatalogueRepository {
  final _revisions = StreamController<int>.broadcast();
  var _revision = 1;
  var fetchCount = 0;

  @override
  Future<Result<CatalogueSnapshot>> getCatalogue() async {
    fetchCount += 1;
    return Ok(
      CatalogueSnapshot(
        revision: _revision,
        categories: const [],
        items: const [],
      ),
    );
  }

  @override
  Stream<int> watchRevision() => _revisions.stream;

  void emitRevision(int revision) {
    _revision = revision;
    _revisions.add(revision);
  }

  Future<void> dispose() => _revisions.close();
}
