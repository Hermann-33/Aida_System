import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/reward.dart';
import '../../domain/model/voucher.dart';
import '../../domain/repository/loyalty_repository.dart';

/// Supabase-backed customer loyalty boundary.
///
/// Balances, reward costs, voucher ownership and redemption outcomes are all
/// resolved by caller-bound RPCs. No client-computed balance is persisted and
/// there is deliberately no mock/preview fallback in live mode.
class SupabaseLoyaltyRepository implements LoyaltyRepository {
  SupabaseLoyaltyRepository(this._client);

  final SupabaseClient _client;

  Future<Result<Map<String, dynamic>>> _wallet() async {
    if (_client.auth.currentUser == null) {
      return const Err(AuthFailure('Sign in to load your loyalty wallet'));
    }
    try {
      final response = await _client.rpc('get_my_loyalty_wallet');
      if (response is! Map) {
        return const Err(ServerFailure('Invalid loyalty response'));
      }
      return Ok(Map<String, dynamic>.from(response));
    } on PostgrestException {
      return const Err(ServerFailure('Unable to load loyalty right now'));
    } catch (_) {
      return const Err(ServerFailure('Unable to load loyalty right now'));
    }
  }

  @override
  Future<Result<Points>> getPoints() async {
    final result = await _wallet();
    return switch (result) {
      Err(failure: final failure) => Err(failure),
      Ok(value: final wallet) => _points(wallet),
    };
  }

  Result<Points> _points(Map<String, dynamic> wallet) {
    final raw = wallet['pointsBalance'];
    if (raw is! num) return const Err(ServerFailure('Invalid loyalty balance'));
    return Ok(Points(balance: raw.toInt(), asOf: DateTime.now().toUtc()));
  }

  @override
  Future<Result<StampCard>> getStampCard() async {
    final result = await _wallet();
    return switch (result) {
      Err(failure: final failure) => Err(failure),
      Ok(value: final wallet) => _stampCard(wallet),
    };
  }

  Result<StampCard> _stampCard(Map<String, dynamic> wallet) {
    final collected = wallet['stampBalance'];
    final program = wallet['program'];
    final vouchers = wallet['vouchers'];
    if (collected is! num || program is! Map || vouchers is! List) {
      return const Err(ServerFailure('Invalid stamp-card response'));
    }
    final goal = program['stampGoal'];
    if (goal is! num) return const Err(ServerFailure('Invalid stamp-card goal'));
    final freeDrinks = vouchers.where((entry) {
      if (entry is! Map) return false;
      return entry['status'] == 'active' && entry['rewardCode'] == 'STAMP_FREE_DRINK';
    }).length;
    return Ok(StampCard(
      collected: collected.toInt(),
      required_: goal.toInt(),
      freeDrinksAvailable: freeDrinks,
    ));
  }

  @override
  Future<Result<List<Reward>>> getRewards() async {
    final result = await _wallet();
    return switch (result) {
      Err(failure: final failure) => Err(failure),
      Ok(value: final wallet) => _rewards(wallet),
    };
  }

  Result<List<Reward>> _rewards(Map<String, dynamic> wallet) {
    final rows = wallet['rewards'];
    if (rows is! List) return const Err(ServerFailure('Invalid rewards response'));
    try {
      return Ok(rows.map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final type = row['rewardType'] as String?;
        final fixed = row['fixedAmountSen'];
        final kind = type == 'fixed_amount' ? RewardKind.voucher : RewardKind.freeItem;
        final shortLabel = fixed is num ? 'RM ${(fixed.toInt() / 100).toStringAsFixed(fixed.toInt() % 100 == 0 ? 0 : 2)}' : null;
        return Reward(
          id: row['id'] as String,
          name: row['name'] as String,
          pointsCost: (row['pointsCost'] as num).toInt(),
          kind: kind,
          shortLabel: shortLabel,
        );
      }).toList(growable: false));
    } catch (_) {
      return const Err(ServerFailure('Invalid rewards response'));
    }
  }

  @override
  Future<Result<List<Voucher>>> getVouchers() async {
    final result = await _wallet();
    return switch (result) {
      Err(failure: final failure) => Err(failure),
      Ok(value: final wallet) => _vouchers(wallet),
    };
  }

  Result<List<Voucher>> _vouchers(Map<String, dynamic> wallet) {
    final rows = wallet['vouchers'];
    if (rows is! List) return const Err(ServerFailure('Invalid vouchers response'));
    try {
      final vouchers = <Voucher>[];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        if (row['status'] != 'active') continue;
        final code = row['rewardCode'] as String? ?? '';
        final type = row['rewardType'] as String?;
        final fixed = row['fixedAmountSen'];
        final kind = code == 'STAMP_FREE_DRINK'
            ? RewardKind.freeDrink
            : type == 'fixed_amount'
                ? RewardKind.voucher
                : RewardKind.freeItem;
        final description = fixed is num
            ? 'RM ${(fixed.toInt() / 100).toStringAsFixed(2)} off an eligible order'
            : kind == RewardKind.freeDrink
                ? 'One free eligible drink'
                : 'One free eligible item';
        vouchers.add(Voucher(
          id: row['id'] as String,
          title: row['rewardName'] as String,
          description: description,
          kind: kind,
          expiresAt: DateTime.parse(row['expiresAt'] as String).toLocal(),
          imageCategory: kind == RewardKind.freeItem ? 'Pastries' : 'Drinks',
        ));
      }
      return Ok(vouchers);
    } catch (_) {
      return const Err(ServerFailure('Invalid vouchers response'));
    }
  }

  @override
  Future<Result<void>> redeemReward(String rewardId) async {
    if (_client.auth.currentUser == null) {
      return const Err(AuthFailure('Sign in to redeem rewards'));
    }
    try {
      await _client.rpc('redeem_my_reward', params: <String, dynamic>{'p_reward_id': rewardId});
      return const Ok(null);
    } on PostgrestException catch (error) {
      if (error.details == 'LOYALTY_POINTS_INSUFFICIENT') {
        return const Err(ValidationFailure({'points': 'Not enough points for this reward'}));
      }
      if (error.details == 'REWARD_UNAVAILABLE') {
        return const Err(ValidationFailure({'reward': 'This reward is no longer available'}));
      }
      return const Err(ServerFailure('Unable to redeem this reward right now'));
    } catch (_) {
      return const Err(ServerFailure('Unable to redeem this reward right now'));
    }
  }
}
