import 'menu_item.dart';
import 'menu_variant.dart';
import 'money.dart';

/// One configured line in the local preview cart.
///
/// Menu configuration prices come from the shared catalogue. This cart is not
/// an authoritative quote/order implementation; checkout must still re-price
/// server-side when that backend task lands.
class CartLineItem {
  const CartLineItem({
    required this.item,
    this.size,
    this.addOnIds = const [],
    required this.quantity,
    this.note,
  });

  final MenuItem item;

  /// Kept as `size` for existing UI/receipt semantics, but the value is now a
  /// server-defined catalogue variant rather than a hardcoded Dart enum.
  final MenuVariant? size;
  final List<String> addOnIds;
  final int quantity;
  final String? note;

  Money unitPrice(Money addOnTotal) {
    final delta = size?.priceDeltaSen ?? 0;
    return Money.fromSen(item.price.sen + delta + addOnTotal.sen);
  }

  Money lineTotal(Money addOnTotal) =>
      Money.fromSen(unitPrice(addOnTotal).sen * quantity);

  bool sameConfigurationAs(CartLineItem other) {
    if (item.id != other.item.id) return false;
    if (size?.id != other.size?.id) return false;
    if (note != other.note) return false;
    if (addOnIds.length != other.addOnIds.length) return false;
    final a = [...addOnIds]..sort();
    final b = [...other.addOnIds]..sort();
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  CartLineItem copyWith({int? quantity}) => CartLineItem(
        item: item,
        size: size,
        addOnIds: addOnIds,
        quantity: quantity ?? this.quantity,
        note: note,
      );
}

class Cart {
  const Cart({this.lineItems = const []});

  final List<CartLineItem> lineItems;

  bool get isEmpty => lineItems.isEmpty;

  int get itemCount => lineItems.fold(0, (sum, line) => sum + line.quantity);

  Money subtotal(Money Function(CartLineItem) addOnTotalFor) {
    var sen = 0;
    for (final line in lineItems) {
      sen += line.lineTotal(addOnTotalFor(line)).sen;
    }
    return Money.fromSen(sen);
  }
}

extension CartLineItemSummary on CartLineItem {
  String? configSummary(List<MenuItem> menu) {
    final parts = <String>[];
    if (size != null) parts.add(size!.label);
    if (addOnIds.isNotEmpty) {
      final names = addOnIds
          .map((id) {
            for (final m in menu) {
              if (m.id == id) return m.name;
            }
            return null;
          })
          .whereType<String>()
          .join(', ');
      if (names.isNotEmpty) parts.add(names);
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

Money addOnTotalFor(List<String> addOnIds, List<MenuItem> menu) {
  var sen = 0;
  for (final id in addOnIds) {
    for (final item in menu) {
      if (item.id == id) {
        sen += item.price.sen;
        break;
      }
    }
  }
  return Money.fromSen(sen);
}
