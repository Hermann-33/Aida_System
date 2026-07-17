import '../../core/error/result.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/member.dart';
import '../../domain/model/menu_category.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/money.dart';
import '../../domain/model/offer.dart';
import '../../domain/model/promo.dart';
import '../../domain/model/reward.dart';
import '../../domain/model/voucher.dart';
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
  const MockMemberRepository({
    this.latency = const Duration(milliseconds: 400),
  });

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
    studentOrEmployeeId: 'TP065432', // Demo value — self-reported, unverified.
  );

  @override
  Future<Result<void>> logIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    // No real credential store to check against — every well-formed
    // attempt "succeeds." Field-level validation (empty, malformed email,
    // short password) already happened in the form before this is called.
    return const Ok(null);
  }

  @override
  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
    required bool isStudent,
  }) async {
    await Future<void>.delayed(latency);
    return const Ok(null);
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    await Future<void>.delayed(latency);
    // Always succeeds regardless of whether the email is registered — see
    // the interface doc on why that's correct even for a real backend.
    return const Ok(null);
  }

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
    return const Ok(
      StampCard(collected: 7, required_: 10, freeDrinksAvailable: 1),
    );
  }

  @override
  Future<Result<List<Voucher>>> getVouchers() async {
    await Future<void>.delayed(latency);
    // One free drink from a completed stamp card, plus a points-converted
    // voucher — enough to demo the ticket wallet without inventing a full
    // redemption flow. Expiry window is a stand-in until the owner sets one
    // (design spec open question #2).
    final now = DateTime.now();
    return Ok([
      Voucher(
        id: 'v_free_drink',
        title: 'Free Handcrafted Drink',
        description:
            'Unlocked with a completed stamp card. Show this at the counter.',
        kind: RewardKind.freeDrink,
        expiresAt: now.add(const Duration(days: 30)),
        imageCategory: 'Drinks',
      ),
      Voucher(
        id: 'v_rm5',
        title: 'RM 5 Voucher',
        description:
            'Converted from 100 Aida Points. Staff apply it at checkout.',
        kind: RewardKind.voucher,
        expiresAt: now.add(const Duration(days: 45)),
        imageCategory: 'Drinks',
      ),
    ]);
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

  /// TEMPORARY stock photography, for visualising the carousel only.
  ///
  /// Aida has no product photography yet. These are stand-in Unsplash images
  /// so the client can see the intended effect — swap for real photos before
  /// any real deployment. Hotlinked, so they need a live connection; if one
  /// fails to load, ProductImage's fallback still renders its tinted
  /// placeholder rather than a broken image.
  static const _stockLatte =
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=900&q=80';
  static const _stockBeans =
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=900&q=80';
  static const _stockPastry =
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=900&q=80';
  static const _stockCappuccino =
      'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=900&q=80';
  static const _stockIcedCoffee =
      'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=900&q=80';
  static const _stockMatcha =
      'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=900&q=80';
  static const _stockAmericano =
      'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=900&q=80';
  static const _stockMocha =
      'https://images.unsplash.com/photo-1572490122747-3969b75c2f42?w=900&q=80';
  static const _stockIcedCoffeePlain =
      'https://images.unsplash.com/photo-1517701551477-081fb5d9e6e2?w=900&q=80';
  static const _stockChocolate =
      'https://images.unsplash.com/photo-1572490122747-3969b75c2f42?w=900&q=80';
  static const _stockSandwich =
      'https://images.unsplash.com/photo-1528735602782-2552fd46c207?w=900&q=80';
  static const _stockMuffin =
      'https://images.unsplash.com/photo-1607958996338-010a2fbfad75?w=900&q=80';
  static const _stockWrap =
      'https://images.unsplash.com/photo-1626700051175-6818033a6e2a?w=900&q=80';

  @override
  Future<Result<List<Promo>>> getPromos() async {
    await Future<void>.delayed(latency);
    // Active offers are folded in here as slides, rather than shown again in
    // a separate banner list below the carousel — see the note on [Promo].
    return const Ok([
      Promo(
        id: 'promo_signature',
        headline: 'Step into\nthe light',
        subhead: 'Try our signature roast, made fresh every morning',
        ctaLabel: 'See Menu',
        imageUrl: _stockLatte,
      ),
      Promo(
        id: 'o_student_20',
        headline: 'Student Offer\n20% Off',
        subhead: 'Show your student QR at City U campus',
        ctaLabel: 'View Offer',
        linkedOfferId: 'o_student_20',
        audience: OfferAudience.students,
        imageUrl: _stockPastry,
      ),
      Promo(
        id: 'o_double_points',
        headline: 'Double Points\nTuesday',
        subhead: 'Earn 2× Aida Points on every drink',
        ctaLabel: 'View Offer',
        linkedOfferId: 'o_double_points',
        audience: OfferAudience.all,
        imageUrl: _stockBeans,
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

    // Counts are derived from the menu, not hardcoded. A hardcoded count drifts
    // the moment someone adds an item, and a card that says "4 items" over a
    // list of five is a small lie the customer will notice.
    int countOf(String name) => _menu.where((i) => i.category == name).length;

    // Categories per PRD §12.2.
    return Ok([
      MenuCategory(
        id: 'c_coffee',
        name: 'Coffee',
        itemCount: countOf('Coffee'),
      ),
      MenuCategory(
        id: 'c_iced',
        name: 'Iced Drinks',
        itemCount: countOf('Iced Drinks'),
      ),
      MenuCategory(id: 'c_food', name: 'Food', itemCount: countOf('Food')),
      MenuCategory(
        id: 'c_addons',
        name: 'Add-ons',
        itemCount: countOf('Add-ons'),
      ),
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
    imageUrl: _stockLatte,
    compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
    rating: 4.9,
    volumeMl: 240,
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
      rating: 4.6,
      volumeMl: 240,
      compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
      description: 'Espresso and steamed milk, softly balanced',
      price: Money.fromSen(1050),
      isAvailable: true,
      isStudentEligible: true,
      imageUrl: _stockLatte,
    ),
    MenuItem(
      id: 'p_americano',
      name: 'Americano',
      category: 'Coffee',
      rating: 4.4,
      volumeMl: 240,
      compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
      description: 'Espresso lengthened with hot water',
      price: Money.fromSen(850),
      isAvailable: true,
      isStudentEligible: true,
      imageUrl: _stockAmericano,
    ),
    MenuItem(
      id: 'p_cappuccino',
      name: 'Cappuccino',
      category: 'Coffee',
      rating: 4.7,
      volumeMl: 240,
      compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
      description: 'Smooth espresso with rich, velvety foam',
      price: Money.fromSen(950),
      isAvailable: true,
      isBestSeller: true,
      isStudentEligible: true,
      imageUrl: _stockCappuccino,
    ),
    MenuItem(
      id: 'p_mocha',
      name: 'Mocha',
      category: 'Coffee',
      rating: 4.3,
      volumeMl: 240,
      compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
      description: 'Espresso, chocolate, and steamed milk',
      price: Money.fromSen(1150),
      isAvailable: true,
      imageUrl: _stockMocha,
    ),
    MenuItem(
      id: 'p_iced_coffee',
      name: 'Iced Coffee',
      category: 'Iced Drinks',
      rating: 4.5,
      volumeMl: 350,
      compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
      description: 'Cold, clean, and straight to the point',
      price: Money.fromSen(900),
      isAvailable: true,
      isStudentEligible: true,
      imageUrl: _stockIcedCoffeePlain,
    ),
    MenuItem(
      id: 'p_iced_latte',
      name: 'Iced Latte',
      category: 'Iced Drinks',
      rating: 4.8,
      volumeMl: 350,
      compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
      description: 'Chilled, creamy, and endlessly refreshing',
      price: Money.fromSen(1050),
      isAvailable: true,
      isBestSeller: true,
      isStudentEligible: true,
      imageUrl: _stockIcedCoffee,
    ),
    MenuItem(
      id: 'p_matcha',
      name: 'Matcha Latte',
      category: 'Iced Drinks',
      rating: 4.6,
      volumeMl: 350,
      compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
      description: 'Stone-ground matcha, gently sweetened',
      price: Money.fromSen(1190),
      isAvailable: true,
      isBestSeller: true,
      imageUrl: _stockMatcha,
    ),
    MenuItem(
      id: 'p_choc_ice',
      name: 'Chocolate Ice',
      category: 'Iced Drinks',
      rating: 4.2,
      volumeMl: 350,
      compatibleAddOnIds: ['p_shot', 'p_oat', 'p_cream'],
      description: 'Dark chocolate over ice, not too sweet',
      price: Money.fromSen(1090),
      isAvailable: true,
      imageUrl: _stockIcedCoffee,
    ),
    MenuItem(
      id: 'p_sandwich',
      name: 'Sandwich',
      category: 'Food',
      description: 'Toasted, generously filled, made to order',
      price: Money.fromSen(1290),
      isAvailable: true,
      isStudentEligible: true,
      imageUrl: _stockSandwich,
    ),
    MenuItem(
      id: 'p_croissant',
      name: 'Butter Croissant',
      category: 'Food',
      description: 'Flaky, buttery, baked this morning',
      price: Money.fromSen(750),
      isAvailable: false, // Sold out — exercises the unavailable state.
      isBestSeller: true,
      imageUrl: _stockPastry,
    ),
    MenuItem(
      id: 'p_muffin',
      name: 'Muffin',
      category: 'Food',
      description: 'Blueberry, still warm from the oven',
      price: Money.fromSen(690),
      isAvailable: true,
      imageUrl: _stockMuffin,
    ),
    MenuItem(
      id: 'p_wrap',
      name: 'Chicken Wrap',
      category: 'Food',
      description: 'Grilled chicken, crisp greens, house sauce',
      price: Money.fromSen(1390),
      isAvailable: true,
      isStudentEligible: true,
      imageUrl: _stockWrap,
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
