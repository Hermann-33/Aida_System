import '../../core/error/result.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/member.dart';
import '../../domain/model/menu_category.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/money.dart';
import '../../domain/model/offer.dart';
import '../../domain/model/promo.dart';
import '../../domain/model/reward.dart';
import '../../domain/repository/member_repository.dart';

/// Demo data for client review. No network, no backend.
///
/// This exists so the client can see and react to real screens before the
/// backend stack is chosen. When the real backend lands, it implements the same
/// [MemberRepository] interface and this class is simply not bound. No screen
/// changes, nothing built here is thrown away.
///
/// The latency below is deliberate: instant responses hide loading states, and
/// loading states are where demos fall apart in front of a client.
class MockMemberRepository implements MemberRepository {
  const MockMemberRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  static final _member = Member(
    id: 'm_001',
    memberCode: 'AIDA-2049-7731',
    name: 'Aida Rahman',
    email: 'aida.rahman@cityu.edu.my',
    phone: '+60 12-345 6789',
    studentStatus: StudentStatus.verified,
    birthday: DateTime(2003, 4, 18),
    tierName: 'Gold Member', // Cosmetic — tiers (CUS-12) are deferred.
  );

  @override
  Future<Result<Member>> getMember() async {
    await Future<void>.delayed(latency);
    return Ok(_member);
  }

  @override
  Future<Result<Points>> getPoints() async {
    await Future<void>.delayed(latency);
    // 130 puts the member mid-ladder: the RM 5 voucher is unlocked, the pastry
    // is 20 points away. The UI Direction deck showed 1,240, but at that
    // balance every tier is already affordable and the reward track has nothing
    // to show. See the note on [getRewards] — the ladder itself is the problem.
    return Ok(Points(balance: 130, asOf: DateTime.now()));
  }

  @override
  Future<Result<List<Reward>>> getRewards() async {
    await Future<void>.delayed(latency);
    // Costs are exactly PRD §10.1.
    //
    // PRODUCT NOTE: this ladder is narrow. At RM 1 = 1 point, a member reaches
    // the dearest reward (180) after roughly fifteen visits and then has
    // nothing left to aim at — the track maxes out and stops motivating. Worth
    // raising with the owner: either add higher tiers, or raise the costs.
    return const Ok([
      Reward(
        id: 'r_voucher_5',
        name: 'RM 5 Voucher',
        shortLabel: 'RM 5',
        pointsCost: 100,
        kind: RewardKind.voucher,
      ),
      Reward(
        id: 'r_pastry',
        name: 'Free Pastry',
        shortLabel: 'Pastry',
        pointsCost: 150,
        kind: RewardKind.freeItem,
      ),
      Reward(
        id: 'r_voucher_10',
        name: 'RM 10 Voucher',
        shortLabel: 'RM 10',
        pointsCost: 180,
        kind: RewardKind.voucher,
      ),
    ]);
  }

  @override
  Future<Result<StampCard>> getStampCard() async {
    await Future<void>.delayed(latency);
    return const Ok(StampCard(collected: 7, required_: 10, freeDrinksAvailable: 1));
  }

  @override
  Future<Result<List<Offer>>> getOffers() async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    return Ok([
      Offer(
        id: 'o_student_20',
        title: 'Student Offer · 20% Off',
        subtitle: 'Show your student QR at City U campus',
        audience: OfferAudience.students,
        endsAt: now.add(const Duration(days: 14)),
      ),
      Offer(
        id: 'o_double_points',
        title: 'Double Points Tuesday',
        subtitle: 'Earn 2× Aida Points on every drink',
        audience: OfferAudience.all,
        endsAt: now.add(const Duration(days: 3)),
      ),
    ]);
  }

  @override
  Future<Result<MenuItem?>> getFeaturedItem() async {
    await Future<void>.delayed(latency);
    return const Ok(_featured);
  }

  @override
  Future<Result<List<Promo>>> getPromos() async {
    await Future<void>.delayed(latency);
    return const Ok([
      Promo(
        id: 'promo_signature',
        headline: 'Step into\nthe light',
        subhead: 'Try our signature roast, made fresh every morning',
        ctaLabel: 'See Menu',
      ),
      Promo(
        id: 'promo_student',
        headline: 'Students\nsave 20%',
        subhead: 'Verified City U students, every day',
        ctaLabel: 'See Offer',
        linkedOfferId: 'o_student_20',
      ),
      Promo(
        id: 'promo_stamps',
        headline: '10 stamps,\n1 free drink',
        subhead: 'Every cup counts toward your next one',
        ctaLabel: 'View Rewards',
      ),
    ]);
  }

  @override
  Future<Result<List<MenuCategory>>> getCategories() async {
    await Future<void>.delayed(latency);
    // Categories per PRD §12.2.
    return const Ok([
      MenuCategory(id: 'c_coffee', name: 'Coffee', itemCount: 4),
      MenuCategory(id: 'c_iced', name: 'Iced Drinks', itemCount: 4),
      MenuCategory(id: 'c_food', name: 'Food', itemCount: 4),
      MenuCategory(id: 'c_addons', name: 'Add-ons', itemCount: 3),
    ]);
  }

  @override
  Future<Result<List<MenuItem>>> getPopularItems() async {
    await Future<void>.delayed(latency);
    return Ok(_menu.where((i) => i.isBestSeller).toList());
  }

  @override
  Future<Result<List<MenuItem>>> getMenuItems() async {
    await Future<void>.delayed(latency);
    return const Ok(_menu);
  }

  static const _featured = MenuItem(
    id: 'p_scl',
    name: 'Salted Caramel Latte',
    category: 'Coffee',
    description: 'Silky espresso, caramel, a pinch of sea salt',
    price: Money.fromSen(1290), // RM 12.90
    isAvailable: true,
    isBestSeller: true,
    isStudentEligible: true,
    bonusPoints: 25,
  );

  /// The menu from PRD §12.2. Prices are plausible Malaysian café prices and
  /// must be replaced with Aida's real ones before any client demo — the owner
  /// will comment on these first.
  static const _menu = <MenuItem>[
    _featured,
    MenuItem(
      id: 'p_latte',
      name: 'Latte',
      category: 'Coffee',
      description: 'Espresso and steamed milk, softly balanced',
      price: Money.fromSen(1050),
      isAvailable: true,
      isStudentEligible: true,
    ),
    MenuItem(
      id: 'p_americano',
      name: 'Americano',
      category: 'Coffee',
      description: 'Espresso lengthened with hot water',
      price: Money.fromSen(850),
      isAvailable: true,
      isStudentEligible: true,
    ),
    MenuItem(
      id: 'p_cappuccino',
      name: 'Cappuccino',
      category: 'Coffee',
      description: 'Smooth espresso with rich, velvety foam',
      price: Money.fromSen(950),
      isAvailable: true,
      isBestSeller: true,
      isStudentEligible: true,
    ),
    MenuItem(
      id: 'p_mocha',
      name: 'Mocha',
      category: 'Coffee',
      description: 'Espresso, chocolate, and steamed milk',
      price: Money.fromSen(1150),
      isAvailable: true,
    ),
    MenuItem(
      id: 'p_iced_coffee',
      name: 'Iced Coffee',
      category: 'Iced Drinks',
      description: 'Cold, clean, and straight to the point',
      price: Money.fromSen(900),
      isAvailable: true,
      isStudentEligible: true,
    ),
    MenuItem(
      id: 'p_iced_latte',
      name: 'Iced Latte',
      category: 'Iced Drinks',
      description: 'Chilled, creamy, and endlessly refreshing',
      price: Money.fromSen(1050),
      isAvailable: true,
      isBestSeller: true,
      isStudentEligible: true,
    ),
    MenuItem(
      id: 'p_matcha',
      name: 'Matcha Latte',
      category: 'Iced Drinks',
      description: 'Stone-ground matcha, gently sweetened',
      price: Money.fromSen(1190),
      isAvailable: true,
      isBestSeller: true,
    ),
    MenuItem(
      id: 'p_choc_ice',
      name: 'Chocolate Ice',
      category: 'Iced Drinks',
      description: 'Dark chocolate over ice, not too sweet',
      price: Money.fromSen(1090),
      isAvailable: true,
    ),
    MenuItem(
      id: 'p_sandwich',
      name: 'Sandwich',
      category: 'Food',
      description: 'Toasted, generously filled, made to order',
      price: Money.fromSen(1290),
      isAvailable: true,
      isStudentEligible: true,
    ),
    MenuItem(
      id: 'p_croissant',
      name: 'Butter Croissant',
      category: 'Food',
      description: 'Flaky, buttery, baked this morning',
      price: Money.fromSen(750),
      isAvailable: false, // Sold out — exercises the unavailable state.
      isBestSeller: true,
    ),
    MenuItem(
      id: 'p_muffin',
      name: 'Muffin',
      category: 'Food',
      description: 'Blueberry, still warm from the oven',
      price: Money.fromSen(690),
      isAvailable: true,
    ),
    MenuItem(
      id: 'p_wrap',
      name: 'Chicken Wrap',
      category: 'Food',
      description: 'Grilled chicken, crisp greens, house sauce',
      price: Money.fromSen(1390),
      isAvailable: true,
      isStudentEligible: true,
    ),
    MenuItem(
      id: 'p_shot',
      name: 'Extra Shot',
      category: 'Add-ons',
      description: 'One more shot of espresso',
      price: Money.fromSen(300),
      isAvailable: true,
    ),
    MenuItem(
      id: 'p_oat',
      name: 'Oat Milk',
      category: 'Add-ons',
      description: 'Swap in oat milk for any drink',
      price: Money.fromSen(250),
      isAvailable: true,
    ),
    MenuItem(
      id: 'p_cream',
      name: 'Whipped Cream',
      category: 'Add-ons',
      description: 'A generous swirl on top',
      price: Money.fromSen(200),
      isAvailable: true,
    ),
  ];
}
