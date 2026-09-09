import '../../core/error/result.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/member.dart';
import '../../domain/model/offer.dart';
import '../../domain/model/promo.dart';
import '../../domain/model/reward.dart';
import '../../domain/model/voucher.dart';
import '../../domain/repository/member_repository.dart';

/// Preview data for feature families that have not been integrated yet.
///
/// Catalogue/menu data is intentionally absent. The live app now has one menu
/// authority: Supabase through CatalogueRepository.
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
    tierName: 'Gold Member',
    studentOrEmployeeId: 'TP065432',
  );

  @override
  Future<Result<void>> logIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
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
    return Ok(Points(balance: 130, asOf: DateTime.now()));
  }

  @override
  Future<Result<List<Reward>>> getRewards() async {
    await Future<void>.delayed(latency);
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

  static const _stockLatte =
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=900&q=80';
  static const _stockBeans =
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=900&q=80';
  static const _stockPastry =
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=900&q=80';

  @override
  Future<Result<List<Promo>>> getPromos() async {
    await Future<void>.delayed(latency);
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
}
