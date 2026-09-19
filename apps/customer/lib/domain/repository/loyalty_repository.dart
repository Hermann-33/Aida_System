import '../../core/error/result.dart';
import '../model/loyalty.dart';
import '../model/reward.dart';
import '../model/voucher.dart';

/// Live customer loyalty boundary. Every balance, reward cost and voucher
/// lifecycle fact comes from Supabase; no preview fallback is allowed here.
abstract interface class LoyaltyRepository {
  Future<Result<Points>> getPoints();

  Future<Result<StampCard>> getStampCard();

  Future<Result<List<Reward>>> getRewards();

  Future<Result<List<Voucher>>> getVouchers();

  /// Atomically converts server-owned points into a server-issued voucher.
  Future<Result<void>> redeemReward(String rewardId);
}
