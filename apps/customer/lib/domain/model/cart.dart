import 'menu_item.dart';
import 'menu_variant.dart';
import 'money.dart';
import 'order.dart';

/// One independently configured line in the local cart.
///
/// The cart stages selection intent only. Catalogue prices/options are used for
/// the local estimate, then the order RPC revalidates every ID and re-prices the
/// line before placement.
class CartLineItem {
  const CartLineItem({
    required this.item,
    this.size,
    this.addOnIds = const [],
    this.optionValueIds = const [],
    required this.quantity,
    this.note,
  });

  final MenuItem item;

  /// Kept as `size` for existing UI/receipt semantics, but the value is a
  /// server-defined catalogue variant rather than a hardcoded Dart enum.
  final MenuVariant? size;

  /// Optional per-line extras such as Boba. Two copies of the same drink may
  /// therefore carry different add-ons without ambiguity.
  final List<String> addOnIds;

  /// One server-owned value ID from each required drink customization group.
  final List<String> optionValueIds;

  final int quantity;
  final String? note;

  Money unitPrice(Money addOnTotal, [Money? optionTotal]) {
    final delta = size?.priceDeltaSen ?? 0;
    final resolvedOptions = optionTotal ?? customizationTotalFor(this);
    return Money.fromSen(
      item.price.sen + delta + addOnTotal.sen + resolvedOptions.sen,
    );
  }

  Money lineTotal(Money addOnTotal, [Money? optionTotal]) =>
      Money.fromSen(unitPrice(addOnTotal, optionTotal).sen * quantity);

  bool sameConfigurationAs(CartLineItem other) {
    if (item.id != other.item.id) return false;
    if (size?.id != other.size?.id) return false;
    if (note != other.note) return false;
    if (!_sameIds(addOnIds, other.addOnIds)) return false;
    if (!_sameIds(optionValueIds, other.optionValueIds)) return false;
    return true;
  }

  CartLineItem copyWith({int? quantity}) => CartLineItem(
    item: item,
    size: size,
    addOnIds: addOnIds,
    optionValueIds: optionValueIds,
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

  List<OrderSelectionLine> toOrderSelection() => lineItems
      .map(
        (line) => OrderSelectionLine(
          itemId: line.item.id,
          variantId: line.size?.id,
          addOnIds: List.unmodifiable(line.addOnIds),
          optionValueIds: List.unmodifiable(line.optionValueIds),
          quantity: line.quantity,
          note: line.note,
        ),
      )
      .toList(growable: false);
}

extension CartLineItemSummary on CartLineItem {
  String? configSummary(List<MenuItem> menu) {
    final parts = <String>[];
    if (size != null) parts.add(size!.label);

    for (final group in item.customizationGroups) {
      for (final option in group.options) {
        if (optionValueIds.contains(option.id)) {
          parts.add('${group.name}: ${option.label}');
          break;
        }
      }
    }

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

Money customizationTotalFor(CartLineItem line) {
  var sen = 0;
  for (final group in line.item.customizationGroups) {
    for (final option in group.options) {
      if (line.optionValueIds.contains(option.id)) {
        sen += option.priceDeltaSen;
        break;
      }
    }
  }
  return Money.fromSen(sen);
}

bool _sameIds(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  final a = [...left]..sort();
  final b = [...right]..sort();
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
