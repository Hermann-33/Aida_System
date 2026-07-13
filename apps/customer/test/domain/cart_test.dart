import 'package:aida_customer/domain/model/cart.dart';
import 'package:aida_customer/domain/model/item_size.dart';
import 'package:aida_customer/domain/model/menu_item.dart';
import 'package:aida_customer/domain/model/money.dart';
import 'package:test/test.dart';

const _latte = MenuItem(
  id: 'p_latte',
  name: 'Latte',
  category: 'Coffee',
  description: 'x',
  price: Money.fromSen(1050),
  isAvailable: true,
  compatibleAddOnIds: ['p_shot', 'p_oat'],
);

const _shot = MenuItem(
  id: 'p_shot',
  name: 'Extra Shot',
  category: 'Add-ons',
  description: 'x',
  price: Money.fromSen(300),
  isAvailable: true,
);

const _oat = MenuItem(
  id: 'p_oat',
  name: 'Oat Milk',
  category: 'Add-ons',
  description: 'x',
  price: Money.fromSen(250),
  isAvailable: true,
);

void main() {
  group('ItemSize', () {
    test('applies only to Coffee and Iced Drinks', () {
      expect(ItemSize.appliesTo('Coffee'), isTrue);
      expect(ItemSize.appliesTo('Iced Drinks'), isTrue);
      expect(ItemSize.appliesTo('Food'), isFalse);
      expect(ItemSize.appliesTo('Add-ons'), isFalse);
    });

    test('medium carries no price delta', () {
      expect(ItemSize.medium.delta, Money.zero);
    });
  });

  group('CartLineItem.sameConfigurationAs', () {
    test('identical configuration matches regardless of quantity', () {
      const a = CartLineItem(item: _latte, size: ItemSize.medium, quantity: 1);
      const b = CartLineItem(item: _latte, size: ItemSize.medium, quantity: 5);
      expect(a.sameConfigurationAs(b), isTrue);
    });

    test('a different size is a different line', () {
      const a = CartLineItem(item: _latte, size: ItemSize.medium, quantity: 1);
      const b = CartLineItem(item: _latte, size: ItemSize.large, quantity: 1);
      expect(a.sameConfigurationAs(b), isFalse);
    });

    test('different add-ons are a different line, regardless of order', () {
      const a = CartLineItem(item: _latte, addOnIds: ['p_shot', 'p_oat'], quantity: 1);
      const b = CartLineItem(item: _latte, addOnIds: ['p_oat', 'p_shot'], quantity: 1);
      const c = CartLineItem(item: _latte, addOnIds: ['p_shot'], quantity: 1);

      expect(a.sameConfigurationAs(b), isTrue, reason: 'order should not matter');
      expect(a.sameConfigurationAs(c), isFalse);
    });

    test('a different note is a different line', () {
      const a = CartLineItem(item: _latte, quantity: 1, note: 'less ice');
      const b = CartLineItem(item: _latte, quantity: 1);
      expect(a.sameConfigurationAs(b), isFalse);
    });
  });

  group('pricing', () {
    test('unit price is base plus size delta plus add-on total', () {
      const line = CartLineItem(
        item: _latte,
        size: ItemSize.large, // +150
        addOnIds: ['p_shot', 'p_oat'],
        quantity: 1,
      );
      final addOns = addOnTotalFor(line.addOnIds, [_latte, _shot, _oat]);
      // 1050 (latte) + 150 (large) + 300 (shot) + 250 (oat) = 1750
      expect(line.unitPrice(addOns), const Money.fromSen(1750));
    });

    test('line total multiplies unit price by quantity', () {
      const line = CartLineItem(item: _latte, quantity: 3);
      expect(line.lineTotal(Money.zero), const Money.fromSen(1050 * 3));
    });
  });

  group('Cart.subtotal', () {
    test('sums every line', () {
      const cart = Cart(
        lineItems: [
          CartLineItem(item: _latte, quantity: 2), // 2100
          CartLineItem(item: _shot, quantity: 1), // 300
        ],
      );
      final total = cart.subtotal((_) => Money.zero);
      expect(total, const Money.fromSen(2400));
    });

    test('an empty cart has a zero subtotal and reports empty', () {
      const cart = Cart();
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotal((_) => Money.zero), Money.zero);
    });
  });
}
