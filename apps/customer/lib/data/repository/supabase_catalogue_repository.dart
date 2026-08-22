import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/model/catalogue_snapshot.dart';
import '../../domain/model/menu_category.dart';
import '../../domain/model/menu_customization.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/menu_variant.dart';
import '../../domain/model/money.dart';
import '../../domain/repository/catalogue_repository.dart';

class SupabaseCatalogueRepository implements CatalogueRepository {
  SupabaseCatalogueRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<CatalogueSnapshot>> getCatalogue() async {
    try {
      final raw = await _client.rpc('get_catalogue');
      if (raw is! Map) {
        return const Err(ServerFailure('Catalogue response was invalid'));
      }
      final json = Map<String, dynamic>.from(raw);
      final categoriesRaw = json['categories'];
      final itemsRaw = json['items'];
      if (categoriesRaw is! List || itemsRaw is! List) {
        return const Err(ServerFailure('Catalogue response was incomplete'));
      }

      final categories = categoriesRaw
          .map((value) => _category(Map<String, dynamic>.from(value as Map)))
          .toList(growable: false);
      final items = itemsRaw
          .map((value) => _item(Map<String, dynamic>.from(value as Map)))
          .toList(growable: false);

      return Ok(CatalogueSnapshot(
        revision: _int(json['revision']),
        categories: categories,
        items: items,
      ));
    } catch (_) {
      return const Err(ServerFailure('Unable to load the menu'));
    }
  }

  @override
  Stream<int> watchRevision() {
    return _client
        .from('catalogue_revision')
        .stream(primaryKey: const ['id'])
        .eq('id', 1)
        .where((rows) => rows.isNotEmpty)
        .map((rows) => _int(rows.first['revision']))
        .distinct();
  }

  static MenuCategory _category(Map<String, dynamic> json) => MenuCategory(
        id: _string(json['id']),
        name: _string(json['name']),
        itemCount: _int(json['itemCount']),
        imageUrl: _nullableString(json['imageUrl']),
      );

  static MenuItem _item(Map<String, dynamic> json) {
    final variantsRaw = json['variants'];
    final addOnsRaw = json['compatibleAddOnIds'];
    final groupsRaw = json['customizationGroups'];
    return MenuItem(
      id: _string(json['id']),
      categoryId: _string(json['categoryId']),
      sku: _string(json['sku']),
      kind: _string(json['kind']),
      name: _string(json['name']),
      category: _string(json['categoryName']),
      description: _string(json['description']),
      price: Money.fromSen(_int(json['basePriceSen'])),
      isAvailable: json['isAvailable'] == true,
      isFeatured: json['isFeatured'] == true,
      isBestSeller: json['isBestSeller'] == true,
      isStudentEligible: json['isStudentEligible'] == true,
      isDrink: json['isDrink'] == true,
      imageUrl: _nullableString(json['imageUrl']),
      volumeMl: json['volumeMl'] == null ? null : _int(json['volumeMl']),
      variants: variantsRaw is List
          ? variantsRaw
              .map((value) => _variant(Map<String, dynamic>.from(value as Map)))
              .toList(growable: false)
          : const [],
      compatibleAddOnIds: addOnsRaw is List
          ? addOnsRaw.map(_string).toList(growable: false)
          : const [],
      customizationGroups: groupsRaw is List
          ? groupsRaw
              .map((value) => _customizationGroup(
                    Map<String, dynamic>.from(value as Map),
                  ))
              .toList(growable: false)
          : const [],
    );
  }

  static MenuVariant _variant(Map<String, dynamic> json) => MenuVariant(
        id: _string(json['id']),
        code: _string(json['code']),
        label: _string(json['label']),
        priceDeltaSen: _int(json['priceDeltaSen']),
        isDefault: json['isDefault'] == true,
        isAvailable: json['isAvailable'] == true,
        sortOrder: _int(json['sortOrder']),
      );

  static MenuCustomizationGroup _customizationGroup(
    Map<String, dynamic> json,
  ) {
    final optionsRaw = json['options'];
    return MenuCustomizationGroup(
      id: _string(json['id']),
      code: _string(json['code']),
      name: _string(json['name']),
      sortOrder: _int(json['sortOrder']),
      options: optionsRaw is List
          ? optionsRaw
              .map((value) => _customizationOption(
                    Map<String, dynamic>.from(value as Map),
                  ))
              .toList(growable: false)
          : const [],
    );
  }

  static MenuCustomizationOption _customizationOption(
    Map<String, dynamic> json,
  ) => MenuCustomizationOption(
        id: _string(json['id']),
        code: _string(json['code']),
        label: _string(json['label']),
        priceDeltaSen: _int(json['priceDeltaSen']),
        isDefault: json['isDefault'] == true,
        isAvailable: json['isAvailable'] == true,
        sortOrder: _int(json['sortOrder']),
      );

  static String _string(Object? value) => value?.toString() ?? '';

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
