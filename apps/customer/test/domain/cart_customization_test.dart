import 'package:aida_customer/domain/model/cart.dart';
import 'package:aida_customer/domain/model/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_catalogue_repository.dart';

void main() {
  test('same drink with different add-ons remains a distinct configuration', () {
    const withExtra = CartLineItem(
      item: TestCatalogueRepository.latte,
      size: TestCatalogueRepository.medium,
      addOnIds: ['p_shot'],
      optionValueIds: ['opt_hot', 'opt_regular'],
      quantity: 1,
    );
    const withoutExtra = CartLineItem(
      item: TestCatalogueRepository.latte,
      size: TestCatalogueRepository.medium,
      optionValueIds: ['opt_hot', 'opt_regular'],
      quantity: 1,
    );

    expect(withExtra.sameConfigurationAs(withoutExtra), isFalse);
  });

  test('same drink with different temperature remains a distinct configuration', () {
    const hot = CartLineItem(
      item: TestCatalogueRepository.latte,
      size: TestCatalogueRepository.medium,
      optionValueIds: ['opt_hot', 'opt_regular'],
      quantity: 1,
    );
    const iced = CartLineItem(
      item: TestCatalogueRepository.latte,
      size: TestCatalogueRepository.medium,
      optionValueIds: ['opt_iced', 'opt_regular'],
      quantity: 1,
    );

    expect(hot.sameConfigurationAs(iced), isFalse);
  });

  test('local estimate includes configured option price delta', () {
    const iced = CartLineItem(
      item: TestCatalogueRepository.latte,
      size: TestCatalogueRepository.medium,
      optionValueIds: ['opt_iced', 'opt_regular'],
      quantity: 2,
    );

    expect(iced.unitPrice(Money.zero).sen, 1390);
    expect(iced.lineTotal(Money.zero).sen, 2780);
  });

  test('order selection keeps per-line option IDs', () {
    const cart = Cart(
      lineItems: [
        CartLineItem(
          item: TestCatalogueRepository.latte,
          size: TestCatalogueRepository.large,
          addOnIds: ['p_shot'],
          optionValueIds: ['opt_iced', 'opt_less_sweet'],
          quantity: 1,
        ),
      ],
    );

    final line = cart.toOrderSelection().single;
    expect(line.addOnIds, ['p_shot']);
    expect(line.optionValueIds, ['opt_iced', 'opt_less_sweet']);
  });
}
