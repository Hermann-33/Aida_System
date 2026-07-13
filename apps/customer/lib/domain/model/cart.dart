import 'item_size.dart';
import 'menu_item.dart';
import 'money.dart';

/// One configured line in the cart: an item, its size (if applicable), any
/// add-ons, a quantity, and an optional note.
///
/// Two lines are the "same" line — and merge into one with an incremented
/// quantity — only when every field but quantity matches exactly. A plain
/// latte and a "no ice" latte are different orders, not the same line with a
/// comment attached; that is exactly how every real cart works.
class CartLineItem {
  const CartLineItem({
    required this.item,
    this.size,
    this.addOnIds = const [],
    required this.quantity,
    this.note,
  });

  final MenuItem item;
  final ItemSize? size;
  final List<String> addOnIds;
  final int quantity;
  final String? note;

  /// Price for one unit: base price + size delta. Add-on prices are summed
  /// separately by whoever resolves [addOnIds] against the menu, since this
  /// model doesn't hold a reference to the full menu.
  Money unitPrice(Money addOnTotal) {
    final delta = size?.delta.sen ?? 0;
    return Money.fromSen(item.price.sen + delta + addOnTotal.sen);
  }

  Money lineTotal(Money addOnTotal) =>
      Money.fromSen(unitPrice(addOnTotal).sen * quantity);

  /// Whether [other] represents the same configuration (ignoring quantity),
  /// and so should merge with this line rather than become a new one.
  bool sameConfigurationAs(CartLineItem other) {
    if (item.id != other.item.id) return false;
    if (size != other.size) return false;
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

/// The cart. In-memory only — see the design spec §2: no backend exists yet
/// for this app, so there is nothing real to persist an order to. This is
/// the same repository-shaped-interface pattern as the rest of the app,
/// applied to state instead: build against what's real today, swap in a
/// backend later without the UI changing.
class Cart {
  const Cart({this.lineItems = const []});

  final List<CartLineItem> lineItems;

  bool get isEmpty => lineItems.isEmpty;

  int get itemCount => lineItems.fold(0, (sum, line) => sum + line.quantity);

  /// Subtotal needs each line's add-on total, which lives outside this model
  /// (the cart doesn't hold a reference to the menu). Callers pass a
  /// resolver rather than this class reaching out to a repository itself.
  Money subtotal(Money Function(CartLineItem) addOnTotalFor) {
    var sen = 0;
    for (final line in lineItems) {
      sen += line.lineTotal(addOnTotalFor(line)).sen;
    }
    return Money.fromSen(sen);
  }
}

/// Resolves a line's add-on IDs against the full menu to a total price.
/// Shared by the item detail live-price preview and the cart subtotal, so
/// the two can never compute add-on pricing differently.
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
