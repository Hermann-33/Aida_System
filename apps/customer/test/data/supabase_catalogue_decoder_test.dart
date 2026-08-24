import 'package:aida_customer/data/repository/supabase_catalogue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes drink groups, defaults, availability, and price deltas', () {
    final snapshot = SupabaseCatalogueRepository.decodeCatalogue({
      'revision': 43,
      'categories': [
        {'id': 'drinks', 'name': 'Drinks', 'itemCount': 1, 'imageUrl': null},
      ],
      'items': [
        {
          'id': 'latte',
          'categoryId': 'drinks',
          'categoryName': 'Drinks',
          'sku': 'DR-LAT',
          'kind': 'product',
          'name': 'Latte',
          'description': 'Espresso and milk',
          'basePriceSen': 1000,
          'isAvailable': true,
          'isFeatured': false,
          'isBestSeller': false,
          'isStudentEligible': false,
          'isDrink': true,
          'imageUrl': null,
          'volumeMl': 240,
          'variants': const [],
          'compatibleAddOnIds': const [],
          'customizationGroups': [
            {
              'id': 'temperature',
              'code': 'temperature',
              'name': 'Temperature',
              'sortOrder': 10,
              'options': [
                {
                  'id': 'hot',
                  'code': 'hot',
                  'label': 'Hot',
                  'priceDeltaSen': 0,
                  'isDefault': false,
                  'isAvailable': false,
                  'sortOrder': 10,
                },
                {
                  'id': 'iced',
                  'code': 'iced',
                  'label': 'Iced',
                  'priceDeltaSen': 120,
                  'isDefault': true,
                  'isAvailable': true,
                  'sortOrder': 20,
                },
              ],
            },
            {
              'id': 'sweetness',
              'code': 'sweetness',
              'name': 'Sweetness',
              'sortOrder': 20,
              'options': [
                {
                  'id': 'regular',
                  'code': 'regular',
                  'label': 'Regular',
                  'priceDeltaSen': 0,
                  'isDefault': true,
                  'isAvailable': true,
                  'sortOrder': 10,
                },
              ],
            },
          ],
        },
      ],
    });

    final drink = snapshot.items.single;
    expect(snapshot.revision, 43);
    expect(drink.isDrink, isTrue);
    expect(drink.customizationGroups.map((group) => group.name), [
      'Temperature',
      'Sweetness',
    ]);

    final temperature = drink.customizationGroups.first;
    expect(temperature.options.first.isAvailable, isFalse);
    expect(temperature.defaultOption?.code, 'iced');
    expect(temperature.defaultOption?.priceDeltaSen, 120);
    expect(temperature.availableOptions.map((option) => option.code), ['iced']);
    expect(drink.customizationGroups.last.defaultOption?.code, 'regular');
  });
}
