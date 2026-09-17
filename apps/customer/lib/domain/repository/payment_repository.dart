import '../../core/error/result.dart';
import '../model/order_payment.dart';

abstract interface class PaymentRepository {
  Future<Result<OrderPaymentSnapshot>> getOrderPaymentState({
    required String orderId,
    required int orderTotalSen,
    required String orderCurrency,
  });

  Future<Result<OrderPaymentSnapshot>> requestExternalPayment({
    required String orderId,
    required String idempotencyKey,
    required int orderTotalSen,
    required String orderCurrency,
  });
}
