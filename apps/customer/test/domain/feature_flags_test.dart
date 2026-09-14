import 'package:aida_customer/core/config/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remaining future backend drafts are disabled by default', () {
    expect(AidaFeatureFlags.referralDraft, isFalse);
  });
}
