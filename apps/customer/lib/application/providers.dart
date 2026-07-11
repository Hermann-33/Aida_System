import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../data/repository/mock_member_repository.dart';
import '../domain/model/loyalty.dart';
import '../domain/model/member.dart';
import '../domain/model/menu_category.dart';
import '../domain/model/menu_item.dart';
import '../domain/model/offer.dart';
import '../domain/model/promo.dart';
import '../domain/model/reward.dart';
import '../domain/repository/member_repository.dart';

/// The single seam between the app and its backend.
///
/// To go live: replace [MockMemberRepository] with the real implementation.
/// That is the whole change. No screen, provider, or model is touched.
final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => const MockMemberRepository(),
);

/// Tabs, per PRD CUS-16.
enum AppTab { home, rewards, qr, menu, profile }

/// Which tab is showing.
///
/// Lifted out of the shell so any screen can navigate — "View All" on Home
/// jumps to Menu, for instance. A button that looks tappable and does nothing
/// is worse than no button.
class SelectedTab extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}

final selectedTabProvider = NotifierProvider<SelectedTab, AppTab>(SelectedTab.new);

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

final promosProvider = FutureProvider<List<Promo>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getPromos()),
);

final categoriesProvider = FutureProvider<List<MenuCategory>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getCategories()),
);

final popularItemsProvider = FutureProvider<List<MenuItem>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getPopularItems()),
);

final rewardsProvider = FutureProvider<List<Reward>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getRewards()),
);
