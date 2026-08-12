import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/result.dart';
import '../data/repository/supabase_member_repository.dart';
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

/// Auth and membership use Supabase. The concrete repository explicitly
/// delegates only not-yet-integrated feature families to preview data.
final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => SupabaseMemberRepository(Supabase.instance.client),
);

/// Backend-derived session state. The old mutable demo flag is gone: login,
/// logout and restart state all follow Supabase Auth's persisted session.
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

  void _applySessionState(bool signedIn) {
    state = signedIn;
    ref.read(memberEditsProvider.notifier).clear();
    ref.invalidate(memberProvider);
  }

  /// Re-syncs immediately after a credential operation; the auth stream remains
  /// the ongoing source of truth.
  void logIn() {
    final repository = ref.read(memberRepositoryProvider);
    state = repository is SupabaseMemberRepository && repository.hasActiveSession;
    if (state) {
      ref.read(memberEditsProvider.notifier).clear();
      ref.invalidate(memberProvider);
    }
  }

  void logOut() {
    final repository = ref.read(memberRepositoryProvider);
    state = false;
    ref.read(memberEditsProvider.notifier).clear();
    ref.invalidate(memberProvider);
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

/// The signed-in member comes from public.user_profiles + public.members under
/// owner-scoped RLS. No locally generated member id/code is accepted.
final memberProvider = FutureProvider<Member>(
  (ref) => _unwrap(ref.watch(memberRepositoryProvider).getMember()),
);

/// Edit-profile persistence remains a separate bounded task. This overlay is
/// retained only for that existing screen; authentication/signup never writes
/// to it and never uses it as identity authority.
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

class OrderHistoryState extends Notifier<List<PastOrder>> {
  @override
  List<PastOrder> build() => const [];

  void add(PastOrder order) => state = [order, ...state];
}

final orderHistoryProvider =
    NotifierProvider<OrderHistoryState, List<PastOrder>>(OrderHistoryState.new);
