import '../../core/error/result.dart';
import '../model/order.dart';

abstract interface class OrderRepository {
  Future<Result<OrderingPolicy>> getOrderingPolicy();

  Future<Result<OrderQuote>> quoteOrder(OrderRequest request);

  Future<Result<OrderSnapshot>> placeCustomerOrder(OrderRequest request);

  Future<Result<List<OrderSnapshot>>> getMyOrders({int limit = 20});

  Future<Result<OrderSnapshot>> getOrder(String orderId);

  /// RLS-owner-scoped signal only. Consumers must refetch an authoritative
  /// order snapshot rather than treating a Realtime row as order authority.
  Stream<void> watchMyOrders();
}
