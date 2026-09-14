import '../../core/error/result.dart';
import '../model/loyalty.dart';
import '../model/member.dart';
import '../model/offer.dart';
import '../model/privacy_preferences.dart';
import '../model/promo.dart';
import '../model/reward.dart';
import '../model/voucher.dart';

/// Customer identity, membership, privacy, loyalty and offer backend boundary.
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
    String? referralCode,
  });

  /// Deletes the authenticated customer identity while the backend retains
  /// only anonymized commercial/operational history required by policy.
  Future<Result<void>> deleteAccount();

  Future<Result<void>> requestPasswordReset({required String email});

  Future<Result<Member>> getMember();

  Future<Result<PrivacyPreferences>> getPrivacyPreferences();

  Future<Result<PrivacyPreferences>> savePrivacyPreferences({
    required bool marketingNotificationsEnabled,
    required bool transactionalNotificationsEnabled,
  });

  Future<Result<Points>> getPoints();

  Future<Result<StampCard>> getStampCard();

  Future<Result<List<Reward>>> getRewards();

  Future<Result<List<Voucher>>> getVouchers();

  /// Requests an atomic server-side points redemption. The client submits only
  /// the selected reward ID; points cost, balance sufficiency and voucher
  /// issuance remain backend authority.
  Future<Result<void>> redeemReward(String rewardId);

  Future<Result<List<Offer>>> getOffers();

  Future<Result<List<Promo>>> getPromos();
}
