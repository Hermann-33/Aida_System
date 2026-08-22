import 'package:aida_customer/core/error/result.dart';
import 'package:aida_customer/domain/model/catalogue_snapshot.dart';
import 'package:aida_customer/domain/model/menu_category.dart';
import 'package:aida_customer/domain/model/menu_customization.dart';
import 'package:aida_customer/domain/model/menu_item.dart';
import 'package:aida_customer/domain/model/menu_variant.dart';
import 'package:aida_customer/domain/model/money.dart';
import 'package:aida_customer/domain/repository/catalogue_repository.dart';

/// Test-only representation of the canonical seeded catalogue. Production
/// runtime has no hardcoded menu fallback; tests opt into this fixture through
/// an explicit provider override.
class TestCatalogueRepository implements CatalogueRepository {
  const TestCatalogueRepository();

  static const small = MenuVariant(
    id: 'v_small',
    code: 'small',
    label: 'Small',
    priceDeltaSen: -100,
    isDefault: false,
    isAvailable: true,
    sortOrder: 10,
  );

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

  static const hot = MenuCustomizationOption(
    id: 'opt_hot',
    code: 'hot',
    label: 'Hot',
    priceDeltaSen: 0,
    isDefault: true,
    isAvailable: true,
    sortOrder: 10,
  );

  static const iced = MenuCustomizationOption(
    id: 'opt_iced',
    code: 'iced',
    label: 'Iced',
    priceDeltaSen: 100,
    isDefault: false,
    isAvailable: true,
    sortOrder: 20,
  );

  static const regularSweet = MenuCustomizationOption(
    id: 'opt_regular',
    code: 'regular',
    label: 'Regular',
    priceDeltaSen: 0,
    isDefault: true,
    isAvailable: true,
    sortOrder: 10,
  );

  static const lessSweet = MenuCustomizationOption(
    id: 'opt_less_sweet',
    code: 'less-sweet',
    label: 'Less sweet',
    priceDeltaSen: 0,
    isDefault: false,
    isAvailable: true,
    sortOrder: 20,
  );

  static const temperature = MenuCustomizationGroup(
    id: 'grp_temperature',
    code: 'temperature',
    name: 'Temperature',
    sortOrder: 10,
    options: [hot, iced],
  );

  static const sweetness = MenuCustomizationGroup(
    id: 'grp_sweetness',
    code: 'sweetness',
    name: 'Sweetness',
    sortOrder: 20,
    options: [regularSweet, lessSweet],
  );

  static const drinkVariants = [small, medium, large];
  static const drinkAddOns = ['p_shot', 'p_oat', 'p_cream'];
  static const drinkCustomizationGroups = [temperature, sweetness];

  static const latte = MenuItem(
    id: 'p_scl',
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
    isDrink: true,
    variants: drinkVariants,
    compatibleAddOnIds: drinkAddOns,
    customizationGroups: drinkCustomizationGroups,
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
      MenuCategory(id: 'c_coffee', name: 'Coffee', itemCount: 5),
      MenuCategory(id: 'c_iced', name: 'Iced Drinks', itemCount: 4),
      MenuCategory(id: 'c_food', name: 'Food', itemCount: 4),
      MenuCategory(id: 'c_addons', name: 'Add-ons', itemCount: 3),
    ],
    items: [
      latte,
      MenuItem(
        id: 'p_latte',
        categoryId: 'c_coffee',
        sku: 'CF-LAT',
        name: 'Latte',
        category: 'Coffee',
        description: 'Espresso and steamed milk, softly balanced',
        price: Money.fromSen(1050),
        isAvailable: true,
        isStudentEligible: true,
        variants: drinkVariants,
        compatibleAddOnIds: drinkAddOns,
        volumeMl: 240,
      ),
      MenuItem(
        id: 'p_americano',
        categoryId: 'c_coffee',
        sku: 'CF-AME',
        name: 'Americano',
        category: 'Coffee',
        description: 'Espresso lengthened with hot water',
        price: Money.fromSen(850),
        isAvailable: true,
        isStudentEligible: true,
        variants: drinkVariants,
        compatibleAddOnIds: drinkAddOns,
        volumeMl: 240,
      ),
      MenuItem(
        id: 'p_cappuccino',
        categoryId: 'c_coffee',
        sku: 'CF-CAP',
        name: 'Cappuccino',
        category: 'Coffee',
        description: 'Smooth espresso with rich, velvety foam',
        price: Money.fromSen(950),
        isAvailable: true,
        isBestSeller: true,
        isStudentEligible: true,
        variants: drinkVariants,
        compatibleAddOnIds: drinkAddOns,
        volumeMl: 240,
      ),
      MenuItem(
        id: 'p_mocha',
        categoryId: 'c_coffee',
        sku: 'CF-MOC',
        name: 'Mocha',
        category: 'Coffee',
        description: 'Espresso, chocolate, and steamed milk',
        price: Money.fromSen(1150),
        isAvailable: true,
        variants: drinkVariants,
        compatibleAddOnIds: drinkAddOns,
        volumeMl: 240,
      ),
      MenuItem(
        id: 'p_iced_coffee',
        categoryId: 'c_iced',
        sku: 'IC-COF',
        name: 'Iced Coffee',
        category: 'Iced Drinks',
        description: 'Cold, clean, and straight to the point',
        price: Money.fromSen(900),
        isAvailable: true,
        isStudentEligible: true,
        variants: drinkVariants,
        compatibleAddOnIds: drinkAddOns,
        volumeMl: 350,
      ),
      MenuItem(
        id: 'p_iced_latte',
        categoryId: 'c_iced',
        sku: 'IC-LAT',
        name: 'Iced Latte',
        category: 'Iced Drinks',
        description: 'Chilled, creamy, and endlessly refreshing',
        price: Money.fromSen(1050),
        isAvailable: true,
        isBestSeller: true,
        isStudentEligible: true,
        variants: drinkVariants,
        compatibleAddOnIds: drinkAddOns,
        volumeMl: 350,
      ),
      MenuItem(
        id: 'p_matcha',
        categoryId: 'c_iced',
        sku: 'IC-MAT',
        name: 'Matcha Latte',
        category: 'Iced Drinks',
        description: 'Stone-ground matcha, gently sweetened',
        price: Money.fromSen(1190),
        isAvailable: true,
        isBestSeller: true,
        variants: drinkVariants,
        compatibleAddOnIds: drinkAddOns,
        volumeMl: 350,
      ),
      MenuItem(
        id: 'p_choc_ice',
        categoryId: 'c_iced',
        sku: 'IC-CHO',
        name: 'Chocolate Ice',
        category: 'Iced Drinks',
        description: 'Dark chocolate over ice, not too sweet',
        price: Money.fromSen(1090),
        isAvailable: true,
        variants: drinkVariants,
        compatibleAddOnIds: drinkAddOns,
        volumeMl: 350,
      ),
      MenuItem(
        id: 'p_sandwich',
        categoryId: 'c_food',
        sku: 'FD-SAN',
        name: 'Sandwich',
        category: 'Food',
        description: 'Toasted, generously filled, made to order',
        price: Money.fromSen(1290),
        isAvailable: true,
        isStudentEligible: true,
      ),
      MenuItem(
        id: 'p_croissant',
        categoryId: 'c_food',
        sku: 'FD-CRO',
        name: 'Butter Croissant',
        category: 'Food',
        description: 'Flaky, buttery, baked this morning',
        price: Money.fromSen(750),
        isAvailable: false,
        isBestSeller: true,
      ),
      MenuItem(
        id: 'p_muffin',
        categoryId: 'c_food',
        sku: 'FD-MUF',
        name: 'Muffin',
        category: 'Food',
        description: 'Blueberry, still warm from the oven',
        price: Money.fromSen(690),
        isAvailable: true,
      ),
      MenuItem(
        id: 'p_wrap',
        categoryId: 'c_food',
        sku: 'FD-WRP',
        name: 'Chicken Wrap',
        category: 'Food',
        description: 'Grilled chicken, crisp greens, house sauce',
        price: Money.fromSen(1390),
        isAvailable: true,
        isStudentEligible: true,
      ),
      shot,
      MenuItem(
        id: 'p_oat',
        categoryId: 'c_addons',
        sku: 'AD-OAT',
        kind: 'addon',
        name: 'Oat Milk',
        category: 'Add-ons',
        description: 'Swap in oat milk for any drink',
        price: Money.fromSen(250),
        isAvailable: true,
      ),
      MenuItem(
        id: 'p_cream',
        categoryId: 'c_addons',
        sku: 'AD-CRM',
        kind: 'addon',
        name: 'Whipped Cream',
        category: 'Add-ons',
        description: 'A generous swirl on top',
        price: Money.fromSen(200),
        isAvailable: true,
      ),
    ],
  );

  @override
  Future<Result<CatalogueSnapshot>> getCatalogue() async => const Ok(snapshot);

  @override
  Stream<int> watchRevision() => Stream<int>.value(1);
}
