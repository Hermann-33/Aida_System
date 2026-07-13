import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../data/repository/mock_member_repository.dart';
import '../domain/model/cart.dart';
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

/// The category the Menu screen is filtered to. Null means "All".
///
/// Lives here rather than inside the Menu screen so tapping a category on Home
/// can pre-select it — the chip then does something real instead of merely
/// switching tabs.
class SelectedCategory extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? categoryId) => state = categoryId;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategory, String?>(
  SelectedCategory.new,
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

final menuItemsProvider = FutureProvider<List<MenuItem>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getMenuItems()),
);

/// The cart. In-memory only, cleared on app restart — see the cart design
/// spec §2. No backend exists yet for this app to persist an order to, so
/// this follows the same pattern as everything else: build against what's
/// real today.
class CartState extends Notifier<Cart> {
  @override
  Cart build() => const Cart();

  /// Adds [line]. Merges into an existing line — incrementing its quantity —
  /// only if one with the exact same configuration already exists.
  void add(CartLineItem line) {
    final lines = state.lineItems;
    final matchIndex = lines.indexWhere(line.sameConfigurationAs);

    if (matchIndex == -1) {
      state = Cart(lineItems: [...lines, line]);
      return;
    }

    final merged = lines[matchIndex].copyWith(
      quantity: lines[matchIndex].quantity + line.quantity,
    );
    final updated = [...lines];
    updated[matchIndex] = merged;
    state = Cart(lineItems: updated);
  }

  /// Sets the line at [index] to [quantity]. Zero or below removes it —
  /// a quantity stepper going to 0 is how a customer removes an item, not a
  /// separate action they have to find.
  void setQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeAt(index);
      return;
    }
    final updated = [...state.lineItems];
    updated[index] = updated[index].copyWith(quantity: quantity);
    state = Cart(lineItems: updated);
  }

  void removeAt(int index) {
    final updated = [...state.lineItems]..removeAt(index);
    state = Cart(lineItems: updated);
  }

  /// Called after a mock order is placed.
  void clear() => state = const Cart();
}

final cartProvider = NotifierProvider<CartState, Cart>(CartState.new);

/// Favorited item IDs. In-memory, session-only — an explicit client choice
/// (cart design spec §3), not an oversight: favorites reset when the app
/// closes.
class FavoritesState extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String itemId) {
    final updated = {...state};
    if (!updated.remove(itemId)) updated.add(itemId);
    state = updated;
  }

  bool contains(String itemId) => state.contains(itemId);
}

final favoritesProvider = NotifierProvider<FavoritesState, Set<String>>(
  FavoritesState.new,
);
