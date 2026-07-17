import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_theme.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/menu_category.dart';
import '../../domain/model/menu_item.dart';
import 'item_detail_screen.dart';
import 'widgets/category_chip.dart';
import 'widgets/category_strip.dart';
import 'widgets/menu_grid_item.dart';

/// The menu. CUS-09.
///
/// Filtering happens on the client over the already-loaded list. The menu is
/// small, so a request per category would be slower than filtering in place —
/// and it would break browsing on a bad connection, which is most of campus.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  /// Groups [items] by category in server order. When a single category is
  /// filtered, one section is returned with that name.
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
      if (list != null && list.isNotEmpty) {
        sections.add((name, list));
      }
    }
    for (final entry in grouped.entries) {
      if (!order.contains(entry.key)) {
        sections.add((entry.key, entry.value));
      }
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
                          style: AidaType.serif(
                            size: 28,
                            color: AidaColors.textPrimary,
                          ),
                        ),
                      ),
                      _FavoritesToggle(
                        active: favoritesOnly,
                        onTap:
                            () =>
                                ref
                                    .read(favoritesOnlyProvider.notifier)
                                    .toggle(),
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
                              (id) => ref
                                  .read(selectedCategoryProvider.notifier)
                                  .select(id),
                        ),
                    loading:
                        () => const SizedBox(height: CategoryChip.height + 20),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              items.when(
                data: (all) {
                  final categoryName =
                      categories.value
                          ?.where((c) => c.id == selected)
                          .firstOrNull
                          ?.name;

                  var visible =
                      categoryName == null
                          ? all
                          : all
                              .where((i) => i.category == categoryName)
                              .toList();

                  if (favoritesOnly) {
                    visible =
                        visible.where((i) => favorites.contains(i.id)).toList();
                  }

                  if (visible.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyCategory(favoritesOnly: favoritesOnly),
                    );
                  }

                  final sections = _groupSections(
                    visible,
                    categories.value,
                    categoryName,
                  );

                  return SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                      decoration: BoxDecoration(
                        color: AidaColors.cardWhite,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AidaColors.espresso.withValues(alpha: 0.08),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < sections.length; i++) ...[
                            if (i > 0) const SizedBox(height: 22),
                            _MenuSectionHeader(title: sections[i].$1),
                            const SizedBox(height: 14),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.82,
                              ),
                              itemCount: sections[i].$2.length,
                              itemBuilder: (context, j) {
                                final item = sections[i].$2[j];
                                return MenuGridItem(
                                  item: item,
                                  onTap:
                                      () => openItemDetail(context, item),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
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
                    (_, __) =>
                        const SliverToBoxAdapter(child: _MenuUnavailable()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 170)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSectionHeader extends StatelessWidget {
  const _MenuSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
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
      ],
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
