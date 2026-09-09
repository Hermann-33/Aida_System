import 'package:flutter/foundation.dart';

/// Gates for preserved future/demo surfaces.
///
/// Production builds keep future backend-dependent features disabled until
/// their dedicated backend tasks are promoted from `supabase/drafts/`.
abstract final class AidaFeatureFlags {
  static bool get referralDraft => const bool.fromEnvironment(
    'AIDA_ENABLE_REFERRAL_DRAFT',
    defaultValue: false,
  );

  static bool get accountDeletionDraft => const bool.fromEnvironment(
    'AIDA_ENABLE_ACCOUNT_DELETION_DRAFT',
    defaultValue: false,
  );

  static bool get developerDemo => kDebugMode;
}
