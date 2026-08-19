import 'package:aida_customer/core/error/failures.dart';
import 'package:aida_customer/data/repository/supabase_member_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseMemberRepository.mapAuthFailure', () {
    test('maps retryable transport failures without exposing internals', () {
      final failure = SupabaseMemberRepository.mapAuthFailure(
        AuthRetryableFetchException(
          message:
              'ClientException with SocketException: Failed host lookup: '
              'eswovqxqzfevcdwwcmuh.supabase.co',
        ),
      );

      expect(failure, isA<NetworkFailure>());
      expect(
        failure.message,
        'Unable to reach AIDA. Check your internet connection and try again.',
      );
      expect(failure.message, isNot(contains('supabase.co')));
      expect(failure.message, isNot(contains('SocketException')));
    });

    test('preserves invalid-credential guidance', () {
      final failure = SupabaseMemberRepository.mapAuthFailure(
        const AuthException('Invalid login credentials'),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Incorrect email or password');
    });

    test('preserves duplicate-signup guidance', () {
      final failure = SupabaseMemberRepository.mapAuthFailure(
        const AuthException('User already registered'),
      );

      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors['email'],
        'An account already exists for this email',
      );
    });
  });
}
