import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/result.dart';
import '../data/repository/supabase_catalogue_repository.dart';
import '../data/repository/supabase_loyalty_repository.dart';
import '../data/repository/supabase_member_repository.dart';
import '../data/repository/supabase_order_repository.dart';
import '../domain/model/cart.dart';
import '../domain/model/catalogue_snapshot.dart';
import '../domain/model/loyalty.dart';
import '../domain/model/member.dart';
import '../domain/model/menu_category.dart';
import '../domain/model/menu_item.dart';
import '../domain/model/offer.dart';
import '../domain/model/order.dart';
import '../domain/model/privacy_preferences.dart';
import '../domain/model/promo.dart';
import '../domain/model/reward.dart';
import '../domain/model/voucher.dart';
import '../domain/repository/catalogue_repository.dart';
import '../domain/repository/loyalty_repository.dart';
import '../domain/repository/member_repository.dart';
import '../domain/repository/order_repository.dart';

final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => SupabaseMemberRepository(Supabase.instance.client),
);

/// Customer loyalty is its own caller-bound capability. Live providers never
/// fall back to the legacy preview values that remain inside the member
/// repository for UI-preview isolation.
final loyaltyRepositoryProvider = Provider<LoyaltyRepository>(
  (ref) => SupabaseLoyaltyRepository(Supabase.instance.client),
);

/// Catalogue is a separate capability from membership. It never falls back to
/// preview menu data when Supabase is unavailable.
final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => SupabaseCatalogueRepository(Supabase.instance.client),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => SupabaseOrderRepository(Supabase.instance.client),
);

class AuthState extends Notifier<bool> {
  StreamSubscription<bool>? _subscription;

  @override
  bool build() {
    final repository = ref.watch(memberRepositoryProvider);
    _subscription?.cancel();

    if (repository is! SupabaseMemberRepository) {
      return false;
    }

    _subscription = repository.authStateChanges.listen(_applySessionState);
    ref.onDispose(() => _subscription?.cancel());
    return repository.hasActiveSession;
  }

  void _invalidateCustomerIdentityState() {
    ref.read(memberEditsProvider.notifier).clear();
    ref.invalidate(memberProvider);
    ref.invalidate(privacyPreferencesProvider);
    ref.invalidate(pointsProvider);
    ref.invalidate(stampCardProvider);
    ref.invalidate(rewardsProvider);
    ref.invalidate(vouchersProvider);
    ref.invalidate(orderUpdatesProvider);
    ref.invalidate(orderHistoryProvider);
  }

  void _applySessionState(bool signedIn) {
    state = signedIn;
    _invalidateCustomerIdentityState();
  }

  void logIn() {
    final repository = ref.read(memberRepositoryProvider);
    state =
        repository is SupabaseMemberRepository && repository.hasActiveSession;
    if (state) _invalidateCustomerIdentityState();
  }

  Future<Result<void>> deleteAccount() async {
    final repository = ref.read(memberRepositoryProvider);
    final result = await repository.deleteAccount();
    if (result is Ok<void>) {
      state = false;
      _invalidateCustomerIdentityState();
    }
    return result;
  }

  void logOut() {
    final repository = ref.read(memberRepositoryProvider);
    state = false;
    _invalidateCustomerIdentityState();
    if (repository is SupabaseMemberRepository) {
      unawaited(repository.logOut());
    }
  }
}

final authStateProvider = NotifierProvider<AuthState, bool>(AuthState.new);

enum AppTab { home, rewards, qr, menu, profile }

class SelectedTab extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}

final selectedTabProvider = NotifierProvider<SelectedTab, AppTab>(
  SelectedTab.new,
);

class SelectedCategory extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? categoryId) => state = categoryId;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategory, String?>(
  SelectedCategory.new,
);

class FavoritesOnly extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final favoritesOnlyProvider = NotifierProvider<FavoritesOnly, bool>(
  FavoritesOnly.new,
);

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

final privacyPreferencesProvider = FutureProvider<PrivacyPreferences>(
  (ref) =>
      _unwrap(ref.watch(memberRepositoryProvider).getPrivacyPreferences()),
);

class MemberEdits extends Notifier<Member?> {
  @override
  Member? build() => null;

  void apply(Member edited) => state = edited;

  void clear() => state = null;
}

final memberEditsProvider = NotifierProvider<MemberEdits, Member?>(
  MemberEdits.new,
);

final displayedMemberProvider = Provider<AsyncValue<Member>>((ref) {
  final base = ref.watch(memberProvider);
  final edits = ref.watch(memberEditsProvider);
  if (edits == null) return base;
  return AsyncValue.data(edits);
});

final pointsProvider = FutureProvider<Points>(
  (ref) => _unwrap(ref.watch(loyaltyRepositoryProvider).getPoints()),
);

final stampCardProvider = FutureProvider<StampCard>(
  (ref) => _unwrap(ref.watch(loyaltyRepositoryProvider).getStampCard()),
);

final offersProvider = FutureProvider<List<Offer>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getOffers()),
);

final promosProvider = FutureProvider<List<Promo>>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getPromos()),
);

/// Supabase Realtime exposes only a singleton revision signal. Every revision
/// change causes a fresh RLS-filtered snapshot fetch; change payloads never
/// become catalogue authority in the client.
final catalogueRevisionProvider = StreamProvider<int>(
  (ref) => ref.watch(catalogueRepositoryProvider).watchRevision(),
);

final catalogueProvider = FutureProvider<CatalogueSnapshot>((ref) {
  ref.watch(catalogueRevisionProvider);
  return _unwrap(ref.watch(catalogueRepositoryProvider).getCatalogue());
});

final featuredItemProvider = FutureProvider<MenuItem?>((ref) async {
  final catalogue = await ref.watch(catalogueProvider.future);
  return catalogue.featuredItem;
});

final categoriesProvider = FutureProvider<List<MenuCategory>>((ref) async {
  final catalogue = await ref.watch(catalogueProvider.future);
  return catalogue.categories;
});

final popularItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final catalogue = await ref.watch(catalogueProvider.future);
  return catalogue.popularItems;
});

final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final catalogue = await ref.watch(catalogueProvider.future);
  return catalogue.items;
});

final rewardsProvider = FutureProvider<List<Reward>>(
  (ref) => _unwrap(ref.watch(loyaltyRepositoryProvider).getRewards()),
);

final vouchersProvider = FutureProvider<List<Voucher>>(
  (ref) => _unwrap(ref.watch(loyaltyRepositoryProvider).getVouchers()),
);

class CartState extends Notifier<Cart> {
  @override
  Cart build() => const Cart();

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

  void clear() => state = const Cart();
}

final cartProvider = NotifierProvider<CartState, Cart>(CartState.new);

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

final orderUpdatesProvider = StreamProvider<void>(
  (ref) => ref.watch(orderRepositoryProvider).watchMyOrders(),
);

/// Realtime is an invalidation signal only. The list is always rebuilt from
/// the owner-scoped get_my_orders() snapshot RPC.
final orderHistoryProvider = FutureProvider<List<OrderSnapshot>>((ref) {
  ref.watch(orderUpdatesProvider);
  return _unwrap(ref.watch(orderRepositoryProvider).getMyOrders());
});

final orderProvider = FutureProvider.family<OrderSnapshot, String>((ref, id) {
  ref.watch(orderUpdatesProvider);
  return _unwrap(ref.watch(orderRepositoryProvider).getOrder(id));
});
