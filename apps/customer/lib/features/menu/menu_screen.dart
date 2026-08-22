import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_theme.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/menu_category.dart';
import '../../domain/model/menu_item.dart';
import 'item_detail_screen.dart';
import 'widgets/menu_category_rail.dart';
import 'widgets/menu_list_item.dart';

/// The customer-facing menu. Only product rows are browsable; `addon` catalogue
/// rows remain in the shared snapshot so an individual product can resolve its
/// compatible extras during configuration.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  static List<(String title, List<MenuItem> items)> _groupSections(
    List<MenuItem> items,
    List<MenuCategory>? categories,
    String? selectedCategoryName,
  ) {
    if (selectedCategoryName != null) {
      return [(selectedCategoryName, items)];
    }

    final order = categories?.map((c) => c.name).toList() ?? const [];
    final grouped = <String, List<MenuItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final sections = <(String, List<MenuItem>)>[];
    for (final name in order) {
      final list = grouped[name];
      if (list != null && list.isNotEmpty) sections.add((name, list));
    }
    for (final entry in grouped.entries) {
      if (!order.contains(entry.key)) sections.add((entry.key, entry.value));
    }
    return sections;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final items = ref.watch(menuItemsProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final favorites = ref.watch(favoritesProvider);
    final favoritesOnly = ref.watch(favoritesOnlyProvider);

    final currentProducts = (items.value ?? const <MenuItem>[])
        .where((item) => item.kind == 'product')
        .toList(growable: false);
    final productCategoryIds = currentProducts
        .map((item) => item.categoryId)
        .toSet();
    final browseCategories = categories.value
        ?.where((category) => productCategoryIds.contains(category.id))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Menu',
                      style: AidaType.serif(
                        size: 28,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                  ),
                  _FavoritesToggle(
                    active: favoritesOnly,
                    onTap: () =>
                        ref.read(favoritesOnlyProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  categories.when(
                    data: (list) {
                      final filtered = list
                          .where(
                            (category) =>
                                productCategoryIds.contains(category.id),
                          )
                          .toList(growable: false);
                      return MenuCategoryRail(
                        categories: filtered,
                        selectedId: filtered.any((c) => c.id == selected)
                            ? selected
                            : null,
                        favoritesOnly: favoritesOnly,
                        onSelect: (id) {
                          ref
                              .read(selectedCategoryProvider.notifier)
                              .select(id);
                          ref.read(favoritesOnlyProvider.notifier).set(false);
                        },
                        onSelectFavorites: () {
                          ref
                              .read(selectedCategoryProvider.notifier)
                              .select(null);
                          ref.read(favoritesOnlyProvider.notifier).set(true);
                        },
                      );
                    },
                    loading: () =>
                        const SizedBox(width: MenuCategoryRail.width),
                    error: (_, __) =>
                        const SizedBox(width: MenuCategoryRail.width),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AidaColors.coffee,
                      onRefresh: () async {
                        ref.invalidate(catalogueProvider);
                        await ref.read(catalogueProvider.future);
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          items.when(
                            data: (all) {
                              final products = all
                                  .where((item) => item.kind == 'product')
                                  .toList(growable: false);
                              final categoryName = browseCategories
                                  ?.where((c) => c.id == selected)
                                  .firstOrNull
                                  ?.name;

                              var visible = categoryName == null
                                  ? products
                                  : products
                                      .where(
                                        (item) =>
                                            item.category == categoryName,
                                      )
                                      .toList(growable: false);

                              if (favoritesOnly) {
                                visible = visible
                                    .where(
                                      (item) => favorites.contains(item.id),
                                    )
                                    .toList(growable: false);
                              }

                              if (visible.isEmpty) {
                                return SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _EmptyCategory(
                                    favoritesOnly: favoritesOnly,
                                  ),
                                );
                              }

                              final sections = _groupSections(
                                visible,
                                browseCategories,
                                categoryName,
                              );

                              return SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  4,
                                  12,
                                  20,
                                  16,
                                ),
                                sliver: SliverList.list(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < sections.length;
                                      i++
                                    ) ...[
                                      if (i > 0)
                                        const SizedBox(height: 22),
                                      _MenuSectionHeader(
                                        title: sections[i].$1,
                                        count: sections[i].$2.length,
                                      ),
                                      const SizedBox(height: 12),
                                      for (
                                        var j = 0;
                                        j < sections[i].$2.length;
                                        j++
                                      ) ...[
                                        if (j > 0)
                                          Divider(
                                            height: 1,
                                            color: AidaColors.latte
                                                .withValues(alpha: 0.5),
                                          ),
                                        MenuListItem(
                                          item: sections[i].$2[j],
                                          onTap: () => openItemDetail(
                                            context,
                                            sections[i].$2[j],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              );
                            },
                            loading: () => const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(top: 60),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AidaColors.coffee,
                                  ),
                                ),
                              ),
                            ),
                            error: (_, __) => const SliverToBoxAdapter(
                              child: _MenuUnavailable(),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 170),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSectionHeader extends StatelessWidget {
  const _MenuSectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title.toUpperCase(),
        style: AidaTheme.sectionLabel(color: AidaColors.coffee),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Divider(
          height: 1,
          color: AidaColors.latte.withValues(alpha: 0.85),
        ),
      ),
      if (count != null) ...[
        const SizedBox(width: 10),
        Text(
          '$count',
          style: AidaType.sans(
            size: 12,
            weight: FontWeight.w700,
            color: AidaColors.textMuted,
          ),
        ),
      ],
    ],
  );
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          favoritesOnly
              ? Icons.favorite_border_rounded
              : Icons.no_food_rounded,
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

class _MenuUnavailable extends StatelessWidget {
  const _MenuUnavailable();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        const Icon(
          Icons.wifi_off_rounded,
          size: 40,
          color: AidaColors.latte,
        ),
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

class _FavoritesToggle extends StatelessWidget {
  const _FavoritesToggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
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
