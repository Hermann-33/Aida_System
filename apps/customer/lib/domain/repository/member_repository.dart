import '../../core/error/result.dart';
import '../model/loyalty.dart';
import '../model/member.dart';
import '../model/offer.dart';
import '../model/promo.dart';
import '../model/reward.dart';
import '../model/voucher.dart';

/// Customer identity, membership, loyalty and offer backend boundary.
///
/// Catalogue/menu data deliberately lives behind CatalogueRepository so a
/// failed backend read can never fall back to preview prices/items.
abstract interface class MemberRepository {
  Future<Result<void>> logIn({required String email, required String password});

  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
    required bool isStudent,
  });

  Future<Result<void>> requestPasswordReset({required String email});

  Future<Result<Member>> getMember();

  Future<Result<Points>> getPoints();

  Future<Result<StampCard>> getStampCard();

  Future<Result<List<Reward>>> getRewards();

  Future<Result<List<Voucher>>> getVouchers();

  Future<Result<List<Offer>>> getOffers();

  Future<Result<List<Promo>>> getPromos();
}
