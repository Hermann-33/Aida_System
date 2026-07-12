import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import 'widgets/category_chip.dart';
import 'widgets/category_strip.dart';
import '../home/widgets/popular_item_tile.dart';

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
                  child: Text(
                    'Menu',
                    style: AidaType.serif(size: 28, color: AidaColors.textPrimary),
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
                    loading: () => const SizedBox(height: CategoryChip.height + 16),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              items.when(
                data: (all) {
                  final categoryName =
                      categories.value?.where((c) => c.id == selected).firstOrNull?.name;

                  final visible =
                      categoryName == null
                          ? all
                          : all.where((i) => i.category == categoryName).toList();

                  if (visible.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyCategory(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    sliver: SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, i) => PopularItemTile(item: visible[i]),
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
  const _EmptyCategory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_food_rounded, size: 64, color: AidaColors.latte),
          const SizedBox(height: 14),
          Text(
            'Nothing here just yet',
            style: AidaType.sans(
              size: 14,
              weight: FontWeight.w700,
              color: AidaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This category has no items right now.',
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
