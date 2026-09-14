import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/model/menu_item.dart';

/// Public, read-only catalogue for signed-out customers.
///
/// This surface uses the same published Supabase catalogue as the authenticated
/// menu but deliberately exposes no cart, checkout, membership, loyalty or
/// ordering capability. It also creates no anonymous Auth identity.
class GuestCatalogueScreen extends ConsumerWidget {
  const GuestCatalogueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(menuItemsProvider);

    return Scaffold(
      backgroundColor: AidaColors.cream,
      appBar: AppBar(
        backgroundColor: AidaColors.cream,
        surfaceTintColor: AidaColors.cream,
        title: Text(
          'Browse menu',
          style: AidaType.serif(size: 24, color: AidaColors.textPrimary),
        ),
      ),
      body: items.when(
        data: (all) {
          final products = all
              .where((item) => item.kind == 'product')
              .toList(growable: false);
          if (products.isEmpty) {
            return const _GuestCatalogueMessage(
              icon: Icons.local_cafe_outlined,
              title: 'Menu is currently unavailable',
              message: 'Please check again shortly.',
            );
          }

          final grouped = <String, List<MenuItem>>{};
          for (final product in products) {
            grouped.putIfAbsent(product.category, () => <MenuItem>[]).add(product);
          }

          return RefreshIndicator(
            color: AidaColors.coffee,
            onRefresh: () async {
              ref.invalidate(catalogueProvider);
              await ref.read(catalogueProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'No account needed to browse. Sign in only when you want to order or use membership features.',
                  style: AidaType.sans(
                    size: 13,
                    color: AidaColors.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                for (final entry in grouped.entries) ...[
                  Text(
                    entry.key,
                    style: AidaType.serif(
                      size: 22,
                      color: AidaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in entry.value) _GuestMenuItem(item: item),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AidaColors.coffee),
        ),
        error: (_, __) => _GuestCatalogueMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Menu is unavailable',
          message: 'The live catalogue could not be loaded.',
          action: TextButton(
            onPressed: () => ref.invalidate(catalogueProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}

class _GuestMenuItem extends StatelessWidget {
  const _GuestMenuItem({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AidaColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AidaColors.latte.withValues(alpha: 0.65)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: ProductImage(
                  imageUrl: item.imageUrl,
                  category: item.category,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AidaType.sans(
                        size: 15,
                        weight: FontWeight.w800,
                        color: AidaColors.textPrimary,
                      ),
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AidaType.sans(
                          size: 12.5,
                          color: AidaColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          item.price.formatted,
                          style: AidaType.sans(
                            size: 13.5,
                            weight: FontWeight.w800,
                            color: AidaColors.coffee,
                          ),
                        ),
                        if (!item.isAvailable) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Sold out',
                            style: AidaType.sans(
                              size: 11,
                              weight: FontWeight.w700,
                              color: AidaColors.cityRed,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestCatalogueMessage extends StatelessWidget {
  const _GuestCatalogueMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AidaColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AidaType.serif(size: 20, color: AidaColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AidaType.sans(size: 13, color: AidaColors.textMuted),
            ),
            if (action != null) ...[
              const SizedBox(height: 10),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
