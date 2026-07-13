import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../home/widgets/popular_item_tile.dart';
import 'item_detail_screen.dart';
import 'widgets/category_chip.dart';
import 'widgets/category_strip.dart';

/// The menu. CUS-09.
///
/// Filtering happens on the client over the already-loaded list. The menu is
/// small, so a request per category would be slower than filtering in place —
/// and it would break browsing on a bad connection, which is most of campus.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final items = ref.watch(menuItemsProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final favorites = ref.watch(favoritesProvider);
    final favoritesOnly = ref.watch(_favoritesOnlyProvider);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AidaColors.coffee,
          onRefresh: () async {
            ref
              ..invalidate(categoriesProvider)
              ..invalidate(menuItemsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Menu',
                          style: AidaType.serif(size: 28, color: AidaColors.textPrimary),
                        ),
                      ),
                      // Favorites are session-only by explicit client choice
                      // (cart design spec §3) — this is the only way to view
                      // them, since there's no dedicated favorites screen.
                      _FavoritesToggle(
                        active: favoritesOnly,
                        onTap: () => ref.read(_favoritesOnlyProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: categories.when(
                    data:
                        (list) => CategoryStrip(
                          categories: list,
                          selectedId: selected,
                          showAll: true,
                          keyPrefix: 'menu_cat',
                          onSelect:
                              (id) =>
                                  ref.read(selectedCategoryProvider.notifier).select(id),
                        ),
                    loading: () => const SizedBox(height: CategoryChip.height + 20),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              items.when(
                data: (all) {
                  final categoryName =
                      categories.value?.where((c) => c.id == selected).firstOrNull?.name;

                  var visible =
                      categoryName == null
                          ? all
                          : all.where((i) => i.category == categoryName).toList();

                  if (favoritesOnly) {
                    visible = visible.where((i) => favorites.contains(i.id)).toList();
                  }

                  if (visible.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyCategory(favoritesOnly: favoritesOnly),
                    );
                  }

                  return SliverPadding(
                    // 170, not 110: the floating cart bar sits above the nav
                    // when the cart has items, and 110 only ever cleared the
                    // nav on its own.
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 170),
                    sliver: SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder:
                          (_, i) => PopularItemTile(
                            item: visible[i],
                            onTap: () => openItemDetail(context, visible[i]),
                          ),
                    ),
                  );
                },
                loading:
                    () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: CircularProgressIndicator(color: AidaColors.coffee),
                        ),
                      ),
                    ),
                error: (_, __) => const SliverToBoxAdapter(child: _MenuUnavailable()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            favoritesOnly ? Icons.favorite_border_rounded : Icons.no_food_rounded,
            size: 64,
            color: AidaColors.latte,
          ),
          const SizedBox(height: 14),
          Text(
            favoritesOnly ? 'No favorites yet' : 'Nothing here just yet',
            style: AidaType.sans(
              size: 14,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            favoritesOnly
                ? 'Tap the heart on an item to save it here.'
                : 'This category has no items right now.',
            textAlign: TextAlign.center,
            style: AidaType.sans(size: 12, color: AidaColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MenuUnavailable extends StatelessWidget {
  const _MenuUnavailable();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AidaColors.latte),
          const SizedBox(height: 14),
          Text(
            "We couldn't load the menu",
            style: AidaType.sans(
              size: 14,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to try again.',
            style: AidaType.sans(size: 12, color: AidaColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Screen-local UI state — resets to off each time Menu is reopened, same as
/// most filter toggles. Not shared app-wide like [selectedCategoryProvider],
/// since nothing else needs to know whether this filter is active.
class _FavoritesOnly extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final _favoritesOnlyProvider = NotifierProvider<_FavoritesOnly, bool>(_FavoritesOnly.new);

class _FavoritesToggle extends StatelessWidget {
  const _FavoritesToggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AidaColors.cityRed : AidaColors.cardWhite,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 20,
            color: active ? AidaColors.cream : AidaColors.textMuted,
          ),
        ),
      ),
    );
  }
}
