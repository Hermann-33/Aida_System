import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../data/repository/mock_member_repository.dart';
import '../domain/model/loyalty.dart';
import '../domain/model/member.dart';
import '../domain/model/menu_item.dart';
import '../domain/model/offer.dart';
import '../domain/repository/member_repository.dart';

/// The single seam between the app and its backend.
///
/// To go live: replace [MockMemberRepository] with the real implementation.
/// That is the whole change. No screen, provider, or model is touched.
final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => const MockMemberRepository(),
);

/// Unwraps a [Result] into a value or throws its failure, so Riverpod's
/// AsyncValue can carry the error into the UI. Widgets match on the failure
/// type rather than inspecting a message string.
Future<T> _unwrap<T>(Future<Result<T>> future) async {
  final result = await future;
  return switch (result) {
    Ok(value: final v) => v,
    Err(failure: final f) => throw f,
  };
}

final memberProvider = FutureProvider<Member>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getMember()),
);

final pointsProvider = FutureProvider<Points>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getPoints()),
);

final stampCardProvider = FutureProvider<StampCard>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getStampCard()),
);

final offersProvider = FutureProvider<List<Offer>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getOffers()),
);

final featuredItemProvider = FutureProvider<MenuItem?>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getFeaturedItem()),
);
