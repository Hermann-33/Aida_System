import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/model/loyalty.dart';
import '../../domain/model/member.dart';
import '../../domain/model/menu_category.dart';
import '../../domain/model/menu_item.dart';
import '../../domain/model/offer.dart';
import '../../domain/model/promo.dart';
import '../../domain/model/reward.dart';
import '../../domain/model/voucher.dart';
import '../../domain/repository/member_repository.dart';
import 'mock_member_repository.dart';

/// Real Supabase implementation for customer authentication and membership.
///
/// Features that have not reached their backend-integration task yet still
/// delegate to the existing preview repository. Auth and member identity never
/// delegate: those values are trusted only when returned by Supabase.
class SupabaseMemberRepository implements MemberRepository {
  SupabaseMemberRepository(
    this._client, {
    MemberRepository? pendingFeatures,
  }) : _pendingFeatures = pendingFeatures ?? const MockMemberRepository();

  final SupabaseClient _client;
  final MemberRepository _pendingFeatures;

  bool get hasActiveSession => _client.auth.currentSession != null;

  Stream<bool> get authStateChanges => _client.auth.onAuthStateChange
      .map((event) => event.session != null)
      .distinct();

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
      return const Ok(null);
    } on AuthException catch (error) {
      return Err(_mapAuthFailure(error));
    } catch (_) {
      return const Err(ServerFailure('Unable to create your account right now'));
    }
  }

  /// Clears the Supabase session. AuthGate also invalidates user-scoped reads.
  Future<Result<void>> logOut() async {
    try {
      await _client.auth.signOut();
      return const Ok(null);
    } catch (_) {
      return const Err(ServerFailure('Unable to sign out cleanly'));
    }
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return const Ok(null);
    } on AuthException {
      // Deliberately return the same result for unknown/invalid accounts so
      // this endpoint cannot be used for account enumeration.
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

    try {
      final profile = await _client
          .from('user_profiles')
          .select('display_name,email,phone')
          .eq('user_id', user.id)
          .single();
      final membership = await _client
          .from('members')
          .select('id,member_code,student_status')
          .eq('user_id', user.id)
          .single();

      return Ok(
        Member(
          id: membership['id'] as String,
          memberCode: membership['member_code'] as String,
          name: (profile['display_name'] as String?)?.trim().isNotEmpty == true
              ? (profile['display_name'] as String).trim()
              : (profile['email'] as String).split('@').first,
          email: profile['email'] as String,
          phone: profile['phone'] as String?,
          studentStatus: _mapStudentStatus(
            membership['student_status'] as String?,
          ),
        ),
      );
    } on PostgrestException {
      return const Err(ServerFailure('Unable to load your membership'));
    } catch (_) {
      return const Err(ServerFailure('Unable to load your membership'));
    }
  }

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
      return const ValidationFailure(
        {'email': 'An account already exists for this email'},
      );
    }
    if (message.contains('password')) {
      return const ValidationFailure(
        {'password': 'Password does not meet the account requirements'},
      );
    }
    return const AuthFailure('Authentication failed');
  }

  // Pending backend features remain explicitly delegated to preview data until
  // their bounded integration tasks replace them. This prevents auth/member
  // work from silently inventing catalogue, loyalty, or promotion state.
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
  Future<Result<MenuItem?>> getFeaturedItem() =>
      _pendingFeatures.getFeaturedItem();

  @override
  Future<Result<List<Promo>>> getPromos() => _pendingFeatures.getPromos();

  @override
  Future<Result<List<MenuCategory>>> getCategories() =>
      _pendingFeatures.getCategories();

  @override
  Future<Result<List<MenuItem>>> getPopularItems() =>
      _pendingFeatures.getPopularItems();

  @override
  Future<Result<List<MenuItem>>> getMenuItems() =>
      _pendingFeatures.getMenuItems();
}
