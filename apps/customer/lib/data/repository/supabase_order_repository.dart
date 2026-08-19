import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/model/order.dart';
import '../../domain/repository/order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<OrderingPolicy>> getOrderingPolicy() =>
      _mapRpc('get_ordering_policy', OrderingPolicy.fromJson);

  @override
  Future<Result<OrderQuote>> quoteOrder(OrderRequest request) => _mapRpc(
    'quote_order',
    OrderQuote.fromJson,
    params: {'p_payload': request.toJson()},
  );

  @override
  Future<Result<OrderSnapshot>> placeCustomerOrder(OrderRequest request) =>
      _mapRpc(
        'place_customer_order',
        OrderSnapshot.fromJson,
        params: {'p_payload': request.toJson()},
      );

  @override
  Future<Result<List<OrderSnapshot>>> getMyOrders({int limit = 20}) async {
    try {
      final raw = await _client.rpc(
        'get_my_orders',
        params: {'p_limit': limit},
      );
      if (raw is! List) {
        return const Err(ServerFailure('Order history response was invalid'));
      }
      return Ok(
        raw
            .map(
              (value) => OrderSnapshot.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList(growable: false),
      );
    } on AuthException catch (_) {
      return const Err(AuthFailure('Sign in to view your orders'));
    } on PostgrestException catch (error) {
      return Err(_postgrestFailure(error));
    } catch (_) {
      return const Err(ServerFailure('Unable to load your orders'));
    }
  }

  @override
  Future<Result<OrderSnapshot>> getOrder(String orderId) => _mapRpc(
    'get_order',
    OrderSnapshot.fromJson,
    params: {'p_order_id': orderId},
  );

  @override
  Stream<void> watchMyOrders() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream<void>.empty();
    return _client
        .from('orders')
        .stream(primaryKey: const ['id'])
        .eq('customer_user_id', userId)
        .map(
          (rows) =>
              rows.map((row) => '${row['id']}:${row['updated_at']}').join('|'),
        )
        .distinct()
        .map((_) {});
  }

  Future<Result<T>> _mapRpc<T>(
    String name,
    T Function(Map<String, dynamic>) decode, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final raw = await _client.rpc(name, params: params);
      if (raw is! Map) {
        return const Err(ServerFailure('Order response was invalid'));
      }
      return Ok(decode(Map<String, dynamic>.from(raw)));
    } on AuthException catch (_) {
      return const Err(AuthFailure('Sign in to place or view orders'));
    } on PostgrestException catch (error) {
      return Err(_postgrestFailure(error));
    } catch (_) {
      return const Err(ServerFailure('Unable to reach ordering right now'));
    }
  }

  static Failure _postgrestFailure(PostgrestException error) {
    if (error.code == '42501') {
      return const AuthFailure('An active member account is required');
    }
    if (error.code == '22023' || error.code == '23505') {
      return ValidationFailure(const {}, error.message);
    }
    return const ServerFailure('Unable to complete the order request');
  }
}
