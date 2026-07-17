/// A points balance, as reported by the server.
///
/// This type deliberately offers no arithmetic. The client displays points;
/// it never adds or subtracts them (PRD §16.5). A redeem request names the
/// voucher being bought, never the balance the client believes it has.
class Points {
  const Points({required this.balance, required this.asOf});

  final int balance;

  /// When the server last reported this. The UI dates a cached balance rather
  /// than presenting a possibly-stale number as current fact (spec §5.3).
  final DateTime asOf;

  /// Formatted with a thousands separator: `1,240`.
  String get formatted {
    final digits = balance.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Progress toward the next free drink.
///
/// PRD §10.1: one stamp per qualifying purchase; ten stamps unlock a free
/// drink and reset the counter.
class StampCard {
  const StampCard({
    required this.collected,
    required this.required_,
    required this.freeDrinksAvailable,
  });

  final int collected;

  /// Trailing underscore because `required` is a Dart keyword.
  final int required_;

  /// Free drinks already earned and not yet consumed at the counter.
  final int freeDrinksAvailable;

  bool isFilled(int index) => index < collected;

  /// 0.0 → 1.0. Guards against a server sending `required_ == 0`, which would
  /// otherwise divide by zero and crash the Home screen.
  double get progress =>
      required_ == 0 ? 0 : (collected / required_).clamp(0.0, 1.0);
}
