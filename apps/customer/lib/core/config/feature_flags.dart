import 'package:flutter/foundation.dart';

/// Compile-time gates for preserved future/demo surfaces.
///
/// Production builds keep future backend-dependent features disabled until
/// their dedicated backend tasks are promoted from `supabase/drafts/`.
abstract final class AidaFeatureFlags {
  static const referralDraft = bool.fromEnvironment(
    'AIDA_ENABLE_REFERRAL_DRAFT',
    defaultValue: false,
  );

  static const accountDeletionDraft = bool.fromEnvironment(
    'AIDA_ENABLE_ACCOUNT_DELETION_DRAFT',
    defaultValue: false,
  );

  static const developerDemo = kDebugMode;
}
