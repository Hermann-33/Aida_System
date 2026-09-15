/// Gates for preserved future backend-dependent surfaces.
///
/// Production builds keep these disabled until their dedicated backend tasks
/// are promoted from `supabase/drafts/` and deployed.
abstract final class AidaFeatureFlags {
  static bool get referralDraft => const bool.fromEnvironment(
    'AIDA_ENABLE_REFERRAL_DRAFT',
    defaultValue: false,
  );
}
