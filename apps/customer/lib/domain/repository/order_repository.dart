import '../../core/error/result.dart';
import '../model/branch_pickup.dart';
import '../model/order.dart';

abstract interface class OrderRepository {
  Future<Result<OrderingPolicy>> getOrderingPolicy();

  Future<Result<List<PickupBranch>>> listPickupBranches();

  Future<Result<BranchPickupState>> getBranchPickupState(String branchId);

  Future<Result<BranchPickupSlots>> listBranchPickupSlots(
    String branchId,
    DateTime serviceDate,
  );

  Future<Result<OrderQuote>> quoteOrder(OrderRequest request);

  Future<Result<OrderQuote>> quoteOrderAtBranch(
    String branchId,
    OrderRequest request,
  );

  Future<Result<OrderSnapshot>> placeCustomerOrder(OrderRequest request);

  Future<Result<OrderSnapshot>> placeCustomerOrderAtBranch(
    String branchId,
    OrderRequest request,
  );

  Future<Result<List<OrderSnapshot>>> getMyOrders({int limit = 20});

  Future<Result<OrderSnapshot>> getOrder(String orderId);

  /// RLS-owner-scoped signal only. Consumers must refetch an authoritative
  /// order snapshot rather than treating a Realtime row as order authority.
  Stream<void> watchMyOrders();
}
