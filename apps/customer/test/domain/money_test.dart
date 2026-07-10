// Note: `package:test`, not `flutter_test`. If this file ever needs the
// Flutter binding, the domain layer has grown a dependency it should not have.
import 'package:aida_customer/domain/model/money.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('formats sen as RM with two decimals', () {
      expect(const Money.fromSen(500).formatted, 'RM 5.00');
      expect(const Money.fromSen(1050).formatted, 'RM 10.50');
      expect(Money.zero.formatted, 'RM 0.00');
    });

    test('formats sub-ringgit amounts without losing the leading zero', () {
      expect(const Money.fromSen(5).formatted, 'RM 0.05');
    });

    test('avoids the float rounding that a double representation would hit', () {
      // 0.1 + 0.2 != 0.3 in binary floating point. In sen it is exact.
      const a = Money.fromSen(10);
      const b = Money.fromSen(20);
      expect(Money.fromSen(a.sen + b.sen), const Money.fromSen(30));
    });

    test('compares by value', () {
      expect(const Money.fromSen(500), const Money.fromSen(500));
      expect(const Money.fromSen(500).compareTo(const Money.fromSen(1000)), isNegative);
    });
  });
}
