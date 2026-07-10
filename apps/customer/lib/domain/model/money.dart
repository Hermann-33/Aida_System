/// Malaysian Ringgit, stored in sen (integer minor units).
///
/// Currency is never a `double`. RM 5.00 is 500 sen. Floating-point
/// arithmetic on money is a defect class this app refuses to open.
///
/// This type performs no business arithmetic — it formats and compares.
/// Totals, discounts, and points are computed by the server (PRD §16.5).
class Money implements Comparable<Money> {
  const Money.fromSen(this.sen);

  final int sen;

  static const Money zero = Money.fromSen(0);

  /// Formats as `RM 5.00`.
  String get formatted => 'RM ${(sen / 100).toStringAsFixed(2)}';

  @override
  int compareTo(Money other) => sen.compareTo(other.sen);

  @override
  bool operator ==(Object other) => other is Money && other.sen == sen;

  @override
  int get hashCode => sen.hashCode;

  @override
  String toString() => formatted;
}
