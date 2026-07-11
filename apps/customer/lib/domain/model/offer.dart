/// Who an offer is for. PRD §11.1.
enum OfferAudience {
  /// Everyone.
  all,

  /// Verified students only. Must be invisible to everyone else (PRD §11.3).
  students,
}

/// A promotion, as evaluated and returned by the server.
///
/// The client does not decide eligibility — it renders what the server sent.
/// [audience] exists so the UI can style a student offer in Aida Pink, not so
/// the client can filter on it.
class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.audience,
    required this.endsAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final OfferAudience audience;
  final DateTime endsAt;

  bool get isStudentOffer => audience == OfferAudience.students;
}
