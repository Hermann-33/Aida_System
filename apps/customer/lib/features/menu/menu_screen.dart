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
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String value) => setState(() => _query = value);

  /// Search and category browsing are two different ways to land on an
  /// item; keeping only one active at a time avoids a category tap
  /// appearing to do nothing while stale search results are still showing.
  void _clearSearch() {
    if (_query.isEmpty) return;
    _searchController.clear();
    setState(() => _query = '');
  }

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
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final items = ref.watch(menuItemsProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final favorites = ref.watch(favoritesProvider);
    final favoritesOnly = ref.watch(favoritesOnlyProvider);
    final query = _query.trim();

    final currentProducts = (items.value ?? const <MenuItem>[])
        .where((item) => item.kind == 'product')
        .toList(growable: false);
    final productCategoryIds =
        currentProducts.map((item) => item.categoryId).toSet();
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
              child: Text(
                'Menu',
                style: AidaType.serif(size: 28, color: AidaColors.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: _SearchField(
                controller: _searchController,
                onChanged: _setQuery,
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
                        selectedId:
                            filtered.any((c) => c.id == selected)
                                ? selected
                                : null,
                        favoritesOnly: favoritesOnly,
                        onSelect: (id) {
                          _clearSearch();
                          ref
                              .read(selectedCategoryProvider.notifier)
                              .select(id);
                          ref.read(favoritesOnlyProvider.notifier).set(false);
                        },
                        onSelectFavorites: () {
                          _clearSearch();
                          ref
                              .read(selectedCategoryProvider.notifier)
                              .select(null);
                          ref.read(favoritesOnlyProvider.notifier).set(true);
                        },
                      );
                    },
                    loading:
                        () => const SizedBox(width: MenuCategoryRail.width),
                    error:
                        (_, __) =>
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

                              if (query.isNotEmpty) {
                                final needle = query.toLowerCase();
                                final matches = products
                                    .where(
                                      (item) =>
                                          item.name.toLowerCase().contains(
                                            needle,
                                          ) ||
                                          item.description
                                              .toLowerCase()
                                              .contains(needle),
                                    )
                                    .toList(growable: false);

                                if (matches.isEmpty) {
                                  return SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: _NoSearchResults(query: query),
                                  );
                                }

                                return SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    12,
                                    20,
                                    16,
                                  ),
                                  sliver: SliverList.list(
                                    children: [
                                      _MenuSectionHeader(
                                        title: 'Results',
                                        count: matches.length,
                                      ),
                                      const SizedBox(height: 12),
                                      for (
                                        var j = 0;
                                        j < matches.length;
                                        j++
                                      ) ...[
                                        if (j > 0)
                                          Divider(
                                            height: 1,
                                            color: AidaColors.latte.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        MenuListItem(
                                          item: matches[j],
                                          onTap:
                                              () => openItemDetail(
                                                context,
                                                matches[j],
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }

                              final categoryName =
                                  browseCategories
                                      ?.where((c) => c.id == selected)
                                      .firstOrNull
                                      ?.name;

                              var visible =
                                  categoryName == null
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
                                      if (i > 0) const SizedBox(height: 22),
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
                                            color: AidaColors.latte.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        MenuListItem(
                                          item: sections[i].$2[j],
                                          onTap:
                                              () => openItemDetail(
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
                            loading:
                                () => const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 60),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AidaColors.coffee,
                                      ),
                                    ),
                                  ),
                                ),
                            error:
                                (_, __) => const SliverToBoxAdapter(
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

/// Rounded pill search field. Matches results against every item's name and
/// description regardless of the selected category — search and category
/// browsing are two separate ways to find something, not filters that
/// combine.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AidaColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AidaColors.latte.withValues(alpha: 0.9)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AidaType.sans(size: 14.5, color: AidaColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search the menu',
          hintStyle: AidaType.sans(size: 14.5, color: AidaColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 21,
            color: AidaColors.coffee,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AidaColors.textMuted,
                ),
              );
            },
          ),
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

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search_off_rounded, size: 64, color: AidaColors.latte),
        const SizedBox(height: 14),
        Text(
          'No matches for "$query"',
          textAlign: TextAlign.center,
          style: AidaType.sans(
            size: 14,
            weight: FontWeight.w700,
            color: AidaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Try a different word, or browse by category instead.',
          textAlign: TextAlign.center,
          style: AidaType.sans(size: 12, color: AidaColors.textMuted),
        ),
      ],
    ),
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

class _MenuUnavailable extends StatelessWidget {
  const _MenuUnavailable();

  @override
  Widget build(BuildContext context) => Padding(
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
