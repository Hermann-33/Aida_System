import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/result.dart';
import '../data/repository/supabase_payment_repository.dart';
import '../domain/model/order_payment.dart';
import '../domain/repository/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => SupabasePaymentRepository(Supabase.instance.client),
);

Future<T> _unwrap<T>(Future<Result<T>> future) async {
  final result = await future;
  return switch (result) {
    Ok(value: final value) => value,
    Err(failure: final failure) => throw failure,
  };
}

class PaymentLookup {
  const PaymentLookup({
    required this.orderId,
    required this.orderTotalSen,
    required this.orderCurrency,
  });

  final String orderId;
  final int orderTotalSen;
  final String orderCurrency;

  @override
  bool operator ==(Object other) =>
      other is PaymentLookup &&
      other.orderId == orderId &&
      other.orderTotalSen == orderTotalSen &&
      other.orderCurrency == orderCurrency;

  @override
  int get hashCode => Object.hash(orderId, orderTotalSen, orderCurrency);
}

final orderPaymentProvider = FutureProvider.family<OrderPaymentSnapshot, PaymentLookup>(
  (ref, lookup) => _unwrap(
    ref.watch(paymentRepositoryProvider).getOrderPaymentState(
      orderId: lookup.orderId,
      orderTotalSen: lookup.orderTotalSen,
      orderCurrency: lookup.orderCurrency,
    ),
  ),
);
