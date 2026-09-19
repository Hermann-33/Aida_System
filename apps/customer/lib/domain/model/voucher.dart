export 'money.dart';

import 'reward.dart';

/// An entitlement the member already holds — a voucher, free drink, or free
/// item ready to present at the counter. PRD §10.1, design spec screens 10–11.
///
/// Distinct from [Reward]: a [Reward] is something you *buy* with points; a
/// [Voucher] is something you already own. Consuming it still requires staff
/// (CUS-07) — the customer can only request / show it.
class Voucher {
  const Voucher({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.expiresAt,
    this.imageCategory = 'Drinks',
  });

  final String id;
  final String title;
  final String description;
  final RewardKind kind;
  final DateTime expiresAt;

  /// Feeds [ProductImage]'s category tint until real photography lands.
  final String imageCategory;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// `EXPIRES ON 17/08/2026` — matches the reference layout the client
  /// asked to mirror, with Aida colours underneath.
  String get expiresLabel {
    final d = expiresAt.day.toString().padLeft(2, '0');
    final m = expiresAt.month.toString().padLeft(2, '0');
    return 'EXPIRES ON $d/$m/${expiresAt.year}';
  }
}
