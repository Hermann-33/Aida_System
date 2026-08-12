import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/member.dart';
import '../../domain/model/offer.dart';
import '../../domain/model/promo.dart';
import '../../domain/model/reward.dart';
import '../../domain/model/voucher.dart';
import '../../domain/repository/member_repository.dart';
import '../cache/offline_member_cache.dart';
import 'mock_member_repository.dart';

/// Real Supabase implementation for customer authentication and membership.
///
/// Loyalty/offers/promotions remain preview-backed until their own tasks.
/// Catalogue is intentionally not part of this repository anymore.
class SupabaseMemberRepository implements MemberRepository {
  SupabaseMemberRepository(
    this._client, {
    MemberRepository? pendingFeatures,
    OfflineMemberCache? offlineMemberCache,
  }) : _pendingFeatures = pendingFeatures ?? const MockMemberRepository(),
       _offlineMemberCache =
           offlineMemberCache ?? SharedPreferencesOfflineMemberCache(),
       _activeUserId = _client.auth.currentUser?.id;

  final SupabaseClient _client;
  final MemberRepository _pendingFeatures;
  final OfflineMemberCache _offlineMemberCache;
  String? _activeUserId;

  bool get hasActiveSession => _client.auth.currentSession != null;

  Stream<bool> get authStateChanges =>
      _client.auth.onAuthStateChange.asyncMap((event) async {
        await _setActiveUser(event.session?.user.id);
        return event.session != null;
      }).distinct();

  @override
  Future<Result<void>> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session == null) {
        return const Err(AuthFailure('Unable to start a session'));
      }
      await _setActiveUser(response.session!.user.id);
      return const Ok(null);
    } on AuthException catch (error) {
      return Err(_mapAuthFailure(error));
    } catch (_) {
      return const Err(ServerFailure('Unable to sign in right now'));
    }
  }

  @override
  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
    required bool isStudent,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          'display_name': name.trim(),
          'is_student': isStudent,
        },
      );
      if (response.user == null) {
        return const Err(ServerFailure('Unable to create your account'));
      }
      if (response.session != null) {
        await _setActiveUser(response.session!.user.id);
      }
      return const Ok(null);
    } on AuthException catch (error) {
      return Err(_mapAuthFailure(error));
    } catch (_) {
      return const Err(
        ServerFailure('Unable to create your account right now'),
      );
    }
  }

  Future<Result<void>> logOut() async {
    final userId = _client.auth.currentUser?.id ?? _activeUserId;
    try {
      await _client.auth.signOut();
      if (userId != null) await _bestEffortRemove(userId);
      _activeUserId = null;
      return const Ok(null);
    } catch (_) {
      if (userId != null) await _bestEffortRemove(userId);
      _activeUserId = null;
      return const Err(ServerFailure('Unable to sign out cleanly'));
    }
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return const Ok(null);
    } on AuthException {
      return const Ok(null);
    } catch (_) {
      return const Err(ServerFailure('Unable to send a reset email right now'));
    }
  }

  @override
  Future<Result<Member>> getMember() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Err(AuthFailure('Sign in to load your membership'));
    }

    late final Map<String, dynamic> profile;
    late final Map<String, dynamic> membership;
    try {
      profile =
          await _client
              .from('user_profiles')
              .select('display_name,email,phone')
              .eq('user_id', user.id)
              .single();
      membership =
          await _client
              .from('members')
              .select('id,member_code,student_status')
              .eq('user_id', user.id)
              .single();
    } on PostgrestException catch (error) {
      if (_isTransientPostgrestFailure(error)) {
        return _offlineMember(user.id, user.email ?? '');
      }
      return const Err(ServerFailure('Unable to load your membership'));
    } catch (_) {
      return _offlineMember(user.id, user.email ?? '');
    }

    try {
      final member = Member(
        id: membership['id'] as String,
        memberCode: membership['member_code'] as String,
        name:
            (profile['display_name'] as String?)?.trim().isNotEmpty == true
                ? (profile['display_name'] as String).trim()
                : (profile['email'] as String).split('@').first,
        email: profile['email'] as String,
        phone: profile['phone'] as String?,
        studentStatus: _mapStudentStatus(
          membership['student_status'] as String?,
        ),
      );
      await _bestEffortWrite(user.id, member);
      return Ok(member);
    } catch (_) {
      // Invalid server rows are not connectivity failures and must not be
      // hidden by an older local cache entry.
      return const Err(ServerFailure('Unable to load your membership'));
    }
  }

  Future<Result<Member>> _offlineMember(String userId, String email) async {
    try {
      final cached = await _offlineMemberCache.read(
        userId: userId,
        email: email,
      );
      if (cached != null) return Ok(cached);
    } catch (_) {
      // A cache failure must not replace the original backend failure.
    }
    return const Err(ServerFailure('Unable to load your membership'));
  }

  Future<void> _setActiveUser(String? nextUserId) async {
    final previousUserId = _activeUserId;
    if (previousUserId != null && previousUserId != nextUserId) {
      await _bestEffortRemove(previousUserId);
    }
    _activeUserId = nextUserId;
  }

  Future<void> _bestEffortWrite(String userId, Member member) async {
    try {
      await _offlineMemberCache.write(userId: userId, member: member);
    } catch (_) {
      // Online membership remains usable even when local persistence fails.
    }
  }

  Future<void> _bestEffortRemove(String userId) async {
    try {
      await _offlineMemberCache.remove(userId);
    } catch (_) {
      // Auth/session cleanup still proceeds if local storage is unavailable.
    }
  }

  bool _isTransientPostgrestFailure(PostgrestException error) =>
      error.code == '503' || error.code == '520';

  StudentStatus _mapStudentStatus(String? value) => switch (value) {
    'pending' => StudentStatus.pending,
    'verified' => StudentStatus.verified,
    _ => StudentStatus.none,
  };

  Failure _mapAuthFailure(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return const AuthFailure('Incorrect email or password');
    }
    if (message.contains('email not confirmed')) {
      return const AuthFailure('Confirm your email before signing in');
    }
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return const ValidationFailure({
        'email': 'An account already exists for this email',
      });
    }
    if (message.contains('password')) {
      return const ValidationFailure({
        'password': 'Password does not meet the account requirements',
      });
    }
    return const AuthFailure('Authentication failed');
  }

  @override
  Future<Result<Points>> getPoints() => _pendingFeatures.getPoints();

  @override
  Future<Result<StampCard>> getStampCard() => _pendingFeatures.getStampCard();

  @override
  Future<Result<List<Reward>>> getRewards() => _pendingFeatures.getRewards();

  @override
  Future<Result<List<Voucher>>> getVouchers() => _pendingFeatures.getVouchers();

  @override
  Future<Result<List<Offer>>> getOffers() => _pendingFeatures.getOffers();

  @override
  Future<Result<List<Promo>>> getPromos() => _pendingFeatures.getPromos();
}
