import '../../core/error/result.dart';
import '../model/loyalty.dart';
import '../model/member.dart';
import '../model/menu_category.dart';
import '../model/menu_item.dart';
import '../model/offer.dart';
import '../model/promo.dart';
import '../model/reward.dart';
import '../model/voucher.dart';

/// Everything the customer app needs from a backend.
///
/// The backend stack is undecided (PRD §24.4 #11). This interface is the seam:
/// today a mock satisfies it, tomorrow a real client does. No screen changes.
///
/// Implementations must not compute balances, discounts, or eligibility — they
/// transport what the server decided (PRD §16.5).
abstract interface class MemberRepository {
  /// Starts a session for an existing member. No real credential store
  /// exists yet — the mock implementation accepts any well-formed input —
  /// so this is a seam for Auth (C2), not a working login.
  Future<Result<void>> logIn({required String email, required String password});

  /// Registers a new member and starts a session.
  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
    required bool isStudent,
  });

  /// Requests a password-reset email. Must succeed identically whether or
  /// not [email] belongs to a real account — a response that reveals which
  /// is a real account-enumeration leak, in a mock or a real backend alike.
  Future<Result<void>> requestPasswordReset({required String email});

  /// The signed-in member. Cached; renders offline.
  Future<Result<Member>> getMember();

  /// Points balance, carrying the time the server reported it.
  Future<Result<Points>> getPoints();

  /// Stamp progress toward the next free drink.
  Future<Result<StampCard>> getStampCard();

  /// Reward tiers, ascending by points cost. Business data — the owner sets
  /// these, so the app must not assume a fixed ladder.
  Future<Result<List<Reward>>> getRewards();

  /// Entitlements the member already holds (voucher wallet). PRD CUS-06.
  ///
  /// The server owns expiry and validity — the client only displays what it
  /// receives. Consuming any of these still requires staff at the counter.
  Future<Result<List<Voucher>>> getVouchers();

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

  /// The full menu. Filtering by category is done in the UI over this list —
  /// the menu is small enough that a round trip per category would be slower
  /// and would break offline browsing.
  Future<Result<List<MenuItem>>> getMenuItems();
}
