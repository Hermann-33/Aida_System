import '../../core/error/result.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/member.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/money.dart';
import '../../domain/model/offer.dart';
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
    return Ok(Points(balance: 1240, asOf: DateTime.now()));
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
    return const Ok(
      MenuItem(
        id: 'p_scl',
        name: 'Salted Caramel Latte',
        category: 'Coffee',
        description: 'Silky espresso, caramel, a pinch of sea salt.',
        price: Money.fromSen(1290), // RM 12.90
        isAvailable: true,
        isBestSeller: true,
        isStudentEligible: true,
        bonusPoints: 25,
      ),
    );
  }
}
