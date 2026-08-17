import 'package:aida_customer/domain/model/cart.dart';
import 'package:aida_customer/domain/model/menu_item.dart';
import 'package:aida_customer/domain/model/menu_variant.dart';
import 'package:aida_customer/domain/model/money.dart';
import 'package:test/test.dart';

const _medium = MenuVariant(
  id: 'v_medium',
  code: 'medium',
  label: 'Medium',
  priceDeltaSen: 0,
  isDefault: true,
  isAvailable: true,
  sortOrder: 20,
);

const _large = MenuVariant(
  id: 'v_large',
  code: 'large',
  label: 'Large',
  priceDeltaSen: 150,
  isDefault: false,
  isAvailable: true,
  sortOrder: 30,
);

const _latte = MenuItem(
  id: 'p_latte',
  name: 'Latte',
  category: 'Coffee',
  description: 'x',
  price: Money.fromSen(1050),
  isAvailable: true,
  compatibleAddOnIds: ['p_shot', 'p_oat'],
  variants: [_medium, _large],
);

const _shot = MenuItem(
  id: 'p_shot',
  kind: 'addon',
  name: 'Extra Shot',
  category: 'Add-ons',
  description: 'x',
  price: Money.fromSen(300),
  isAvailable: true,
);

const _oat = MenuItem(
  id: 'p_oat',
  kind: 'addon',
  name: 'Oat Milk',
  category: 'Add-ons',
  description: 'x',
  price: Money.fromSen(250),
  isAvailable: true,
);

void main() {
  group('catalogue variants', () {
    test('item exposes the server-defined default variant', () {
      expect(_latte.defaultVariant?.id, _medium.id);
      expect(_latte.defaultVariant?.priceDeltaSen, 0);
    });
  });

  group('CartLineItem.sameConfigurationAs', () {
    test('identical configuration matches regardless of quantity', () {
      const a = CartLineItem(item: _latte, size: _medium, quantity: 1);
      const b = CartLineItem(item: _latte, size: _medium, quantity: 5);
      expect(a.sameConfigurationAs(b), isTrue);
    });

    test('a different server variant is a different line', () {
      const a = CartLineItem(item: _latte, size: _medium, quantity: 1);
      const b = CartLineItem(item: _latte, size: _large, quantity: 1);
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
    test('unit price is base plus database variant delta plus add-on total', () {
      const line = CartLineItem(
        item: _latte,
        size: _large,
        addOnIds: ['p_shot', 'p_oat'],
        quantity: 1,
      );
      final addOns = addOnTotalFor(line.addOnIds, [_latte, _shot, _oat]);
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
          CartLineItem(item: _latte, quantity: 2),
          CartLineItem(item: _shot, quantity: 1),
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
