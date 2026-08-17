import '../../core/error/result.dart';
import '../model/catalogue_snapshot.dart';

/// Read-only customer catalogue boundary.
///
/// Admin mutations use the dashboard BFF. The customer app only receives the
/// active/published catalogue allowed by Supabase RLS.
abstract interface class CatalogueRepository {
  Future<Result<CatalogueSnapshot>> getCatalogue();

  /// Emits the singleton database revision whenever Admin changes catalogue
  /// content. Consumers re-fetch [getCatalogue] rather than trusting a change
  /// payload as catalogue authority.
  Stream<int> watchRevision();
}
