class PrivacyPreferences {
  const PrivacyPreferences({
    required this.marketingNotificationsEnabled,
    required this.transactionalNotificationsEnabled,
    this.updatedAt,
  });

  final bool marketingNotificationsEnabled;
  final bool transactionalNotificationsEnabled;
  final DateTime? updatedAt;

  PrivacyPreferences copyWith({
    bool? marketingNotificationsEnabled,
    bool? transactionalNotificationsEnabled,
    DateTime? updatedAt,
  }) => PrivacyPreferences(
    marketingNotificationsEnabled:
        marketingNotificationsEnabled ?? this.marketingNotificationsEnabled,
    transactionalNotificationsEnabled:
        transactionalNotificationsEnabled ??
        this.transactionalNotificationsEnabled,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
