import '../../core/error/result.dart';
import '../model/loyalty.dart';
import '../model/member.dart';
import '../model/menu_category.dart';
import '../model/menu_item.dart';
import '../model/offer.dart';
import '../model/promo.dart';
import '../model/reward.dart';

/// Everything the customer app needs from a backend.
///
/// The backend stack is undecided (PRD §24.4 #11). This interface is the seam:
/// today a mock satisfies it, tomorrow a real client does. No screen changes.
///
/// Implementations must not compute balances, discounts, or eligibility — they
/// transport what the server decided (PRD §16.5).
abstract interface class MemberRepository {
  /// The signed-in member. Cached; renders offline.
  Future<Result<Member>> getMember();

  /// Points balance, carrying the time the server reported it.
  Future<Result<Points>> getPoints();

  /// Stamp progress toward the next free drink.
  Future<Result<StampCard>> getStampCard();

  /// Reward tiers, ascending by points cost. Business data — the owner sets
  /// these, so the app must not assume a fixed ladder.
  Future<Result<List<Reward>>> getRewards();

  /// Offers this member is eligible for. The server filters; the client does
  /// not. An unverified student must not receive student offers at all.
  Future<Result<List<Offer>>> getOffers();

  /// Today's featured item, or null if the café has not set one.
  Future<Result<MenuItem?>> getFeaturedItem();

  /// Hero promotions for the Home carousel. May be empty — the carousel hides
  /// itself rather than showing a blank frame.
  Future<Result<List<Promo>>> getPromos();

  /// Menu categories, in the order the café wants them shown.
  Future<Result<List<MenuCategory>>> getCategories();

  /// Best sellers for the "Popular Picks" list.
  Future<Result<List<MenuItem>>> getPopularItems();
}
