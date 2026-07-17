import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../data/repository/mock_member_repository.dart';
import '../domain/model/cart.dart';
import '../domain/model/loyalty.dart';
import '../domain/model/member.dart';
import '../domain/model/menu_category.dart';
import '../domain/model/menu_item.dart';
import '../domain/model/offer.dart';
import '../domain/model/order.dart';
import '../domain/model/promo.dart';
import '../domain/model/reward.dart';
import '../domain/model/voucher.dart';
import '../domain/repository/member_repository.dart';

/// The single seam between the app and its backend.
///
/// To go live: replace [MockMemberRepository] with the real implementation.
/// That is the whole change. No screen, provider, or model is touched.
final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => const MockMemberRepository(),
);

/// Whether the customer is signed in. Starts false — [AuthGate] shows the
/// login screen until this flips, then shows the shell. Session-only: there
/// is no real token to persist across app restarts yet.
class AuthState extends Notifier<bool> {
  @override
  bool build() => false;

  void logIn() => state = true;

  /// Also clears any local profile edits — a fresh sign-in should see the
  /// mock repository's own data, not a previous session's edited name.
  void logOut() {
    state = false;
    ref.read(memberEditsProvider.notifier).clear();
  }
}

final authStateProvider = NotifierProvider<AuthState, bool>(AuthState.new);

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

final selectedTabProvider = NotifierProvider<SelectedTab, AppTab>(
  SelectedTab.new,
);

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

/// Whether Menu is filtered to favorites only.
///
/// Lives here rather than inside the Menu screen, same reason as
/// [SelectedCategory] — Home's "Favorites" quick action can turn this on
/// before switching to the Menu tab, landing the customer directly on their
/// saved items instead of a plain, unfiltered menu.
class FavoritesOnly extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final favoritesOnlyProvider = NotifierProvider<FavoritesOnly, bool>(
  FavoritesOnly.new,
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

/// Local edits from the Edit Profile form — session-only, same as cart and
/// favorites: there is no backend yet to persist a real profile edit to, so
/// a save applies for the rest of this session and no further.
class MemberEdits extends Notifier<Member?> {
  @override
  Member? build() => null;

  void apply(Member edited) => state = edited;

  void clear() => state = null;
}

final memberEditsProvider = NotifierProvider<MemberEdits, Member?>(
  MemberEdits.new,
);

/// The member as every screen should display them: the mock repository's
/// data, with any local session edits layered on top. Every screen that
/// shows member details (Home's header, the membership card, Profile) reads
/// this instead of [memberProvider] directly, so an edit shows up everywhere
/// at once rather than only on the Profile screen that made it.
final displayedMemberProvider = Provider<AsyncValue<Member>>((ref) {
  final base = ref.watch(memberProvider);
  final edits = ref.watch(memberEditsProvider);
  if (edits == null) return base;
  return AsyncValue.data(edits);
});

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

final vouchersProvider = FutureProvider<List<Voucher>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getVouchers()),
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

/// Past orders, most recent first. In-memory, session-only — same as cart
/// and favorites: there is no backend to persist this to yet.
class OrderHistoryState extends Notifier<List<PastOrder>> {
  @override
  List<PastOrder> build() => const [];

  void add(PastOrder order) => state = [order, ...state];
}

final orderHistoryProvider =
    NotifierProvider<OrderHistoryState, List<PastOrder>>(OrderHistoryState.new);
