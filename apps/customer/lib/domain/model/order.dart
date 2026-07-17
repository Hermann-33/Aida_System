import 'cart.dart';
import 'money.dart';

/// A placed order, snapshotted the moment checkout completes — nothing here
/// changes afterward, the same way a printed receipt doesn't.
///
/// Status is always [ready]: there is no staff/kitchen app in this repo to
/// drive a real "preparing" → "ready" transition (see
/// OrderConfirmationScreen's own doc for why), and a history entry stuck
/// showing "Preparing" forever with no way to ever update would be actively
/// wrong, not just incomplete.
enum OrderStatus { ready }

class PastOrder {
  const PastOrder({
    required this.orderNumber,
    required this.placedAt,
    required this.lineItems,
    required this.subtotal,
    required this.paymentMethodLabel,
    this.status = OrderStatus.ready,
  });

  final String orderNumber;
  final DateTime placedAt;
  final List<CartLineItem> lineItems;
  final Money subtotal;
  final String paymentMethodLabel;
  final OrderStatus status;

  int get itemCount => lineItems.fold(0, (sum, line) => sum + line.quantity);
}
