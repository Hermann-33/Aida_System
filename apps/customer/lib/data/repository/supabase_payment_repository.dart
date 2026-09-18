import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/model/order_payment.dart';
import '../../domain/repository/payment_repository.dart';

class SupabasePaymentRepository implements PaymentRepository {
  SupabasePaymentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<OrderPaymentSnapshot>> getOrderPaymentState({
    required String orderId,
    required int orderTotalSen,
    required String orderCurrency,
  }) => _mapPaymentRpc(
    'get_order_payment_state',
    params: {'p_order_id': orderId},
    orderTotalSen: orderTotalSen,
    orderCurrency: orderCurrency,
  );

  @override
  Future<Result<OrderPaymentSnapshot>> requestExternalPayment({
    required String orderId,
    required String idempotencyKey,
    required int orderTotalSen,
    required String orderCurrency,
  }) => _mapPaymentRpc(
    'request_external_payment',
    params: {
      'p_order_id': orderId,
      'p_idempotency_key': idempotencyKey,
    },
    orderTotalSen: orderTotalSen,
    orderCurrency: orderCurrency,
  );

  Future<Result<OrderPaymentSnapshot>> _mapPaymentRpc(
    String name, {
    required Map<String, dynamic> params,
    required int orderTotalSen,
    required String orderCurrency,
  }) async {
    try {
      final raw = await _client.rpc(name, params: params);
      if (raw is! Map) {
        return const Err(ServerFailure('Payment response was invalid'));
      }
      return Ok(
        OrderPaymentSnapshot.fromJson(
          Map<String, dynamic>.from(raw),
          orderTotalSen: orderTotalSen,
          orderCurrency: orderCurrency,
        ),
      );
    } on AuthException catch (_) {
      return const Err(AuthFailure('Sign in to view payment information'));
    } on PostgrestException catch (error) {
      return Err(_postgrestFailure(error));
    } on FormatException {
      return const Err(ServerFailure('Payment response failed validation'));
    } catch (_) {
      return const Err(ServerFailure('Unable to reach payments right now'));
    }
  }

  static Failure _postgrestFailure(PostgrestException error) {
    if (error.code == '42501') {
      return const AuthFailure('You cannot access this payment');
    }
    if (error.code == '55000' &&
        (error.details?.toString().contains('PAYMENT_PROVIDER_UNAVAILABLE') ??
            false)) {
      return const ValidationFailure(
        {},
        'Online payment is not available yet',
      );
    }
    if (error.code == '22023' || error.code == '23505') {
      return ValidationFailure(const {}, error.message);
    }
    return const ServerFailure('Unable to complete the payment request');
  }
}
