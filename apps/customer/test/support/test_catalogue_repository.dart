import 'package:aida_customer/core/error/result.dart';
import 'package:aida_customer/domain/model/catalogue_snapshot.dart';
import 'package:aida_customer/domain/model/menu_category.dart';
import 'package:aida_customer/domain/model/menu_item.dart';
import 'package:aida_customer/domain/model/menu_variant.dart';
import 'package:aida_customer/domain/model/money.dart';
import 'package:aida_customer/domain/repository/catalogue_repository.dart';

/// Test-only catalogue fixture. Production runtime has no hardcoded menu
/// fallback; widget tests override the catalogue capability explicitly.
class TestCatalogueRepository implements CatalogueRepository {
  const TestCatalogueRepository();

  static const medium = MenuVariant(
    id: 'v_medium',
    code: 'medium',
    label: 'Medium',
    priceDeltaSen: 0,
    isDefault: true,
    isAvailable: true,
    sortOrder: 20,
  );

  static const large = MenuVariant(
    id: 'v_large',
    code: 'large',
    label: 'Large',
    priceDeltaSen: 150,
    isDefault: false,
    isAvailable: true,
    sortOrder: 30,
  );

  static const latte = MenuItem(
    id: 'p_latte',
    categoryId: 'c_coffee',
    sku: 'CF-SCL',
    name: 'Salted Caramel Latte',
    category: 'Coffee',
    description: 'Silky espresso, caramel, a pinch of sea salt',
    price: Money.fromSen(1290),
    isAvailable: true,
    isFeatured: true,
    isBestSeller: true,
    isStudentEligible: true,
    variants: [medium, large],
    compatibleAddOnIds: ['p_shot'],
    volumeMl: 240,
  );

  static const shot = MenuItem(
    id: 'p_shot',
    categoryId: 'c_addons',
    sku: 'AD-SHT',
    kind: 'addon',
    name: 'Extra Shot',
    category: 'Add-ons',
    description: 'One more shot of espresso',
    price: Money.fromSen(300),
    isAvailable: true,
  );

  static const snapshot = CatalogueSnapshot(
    revision: 1,
    categories: [
      MenuCategory(id: 'c_coffee', name: 'Coffee', itemCount: 1),
      MenuCategory(id: 'c_addons', name: 'Add-ons', itemCount: 1),
    ],
    items: [latte, shot],
  );

  @override
  Future<Result<CatalogueSnapshot>> getCatalogue() async => const Ok(snapshot);

  @override
  Stream<int> watchRevision() => Stream<int>.value(1);
}
