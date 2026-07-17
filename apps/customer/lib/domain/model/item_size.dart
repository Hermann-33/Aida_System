import 'money.dart';

/// A size variant. Only Coffee and Iced Drinks carry sizes — see
/// [ItemSize.applicableCategories].
///
/// Price deltas are a placeholder scheme (M = base, S = −RM1, L = +RM1.50),
/// not confirmed real pricing. Every price in this app carries that same
/// caveat until the owner sets real menu numbers.
enum ItemSize {
  small(label: 'Small', delta: Money.fromSen(-100)),
  medium(label: 'Medium', delta: Money.fromSen(0)),
  large(label: 'Large', delta: Money.fromSen(150));

  const ItemSize({required this.label, required this.delta});

  final String label;
  final Money delta;

  /// Categories that offer size selection. A croissant or a single "Extra
  /// Shot" doesn't have S/M/L.
  static const applicableCategories = {'Coffee', 'Iced Drinks'};

  static bool appliesTo(String category) =>
      applicableCategories.contains(category);
}
