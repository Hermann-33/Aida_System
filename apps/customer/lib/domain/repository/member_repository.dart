import '../../core/error/result.dart';
import '../model/loyalty.dart';
import '../model/member.dart';
import '../model/menu_item.dart';
import '../model/offer.dart';

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

  /// Offers this member is eligible for. The server filters; the client does
  /// not. An unverified student must not receive student offers at all.
  Future<Result<List<Offer>>> getOffers();

  /// Today's featured item, or null if the café has not set one.
  Future<Result<MenuItem?>> getFeaturedItem();
}
