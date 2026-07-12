import 'offer.dart';

/// A hero promotion for the Home carousel.
///
/// Distinct from [Offer]: an Offer is a rule the server applies at checkout,
/// while a Promo is marketing content the café controls. A Promo may point at
/// an Offer, but it can also just say "we're open late this week".
///
/// Active offers are folded into the carousel as promo slides (see
/// [audience]) rather than shown a second time in a separate banner list —
/// showing "Students save 20%" as both a teaser slide and a full banner below
/// it said the same thing twice.
class Promo {
  const Promo({
    required this.id,
    required this.headline,
    required this.subhead,
    required this.ctaLabel,
    this.imageUrl,
    this.linkedOfferId,
    this.audience,
  });

  final String id;

  /// Two or three words. Sits large over the image.
  final String headline;

  final String subhead;

  /// e.g. "See Offer". Browse-only in v1 — this never adds to a cart.
  final String ctaLabel;

  final String? imageUrl;

  /// When set, tapping the promo opens that offer's detail.
  final String? linkedOfferId;

  /// Set when this slide represents a real [Offer], so the carousel can carry
  /// the same student/general colour distinction the old offer banner had.
  /// Null means pure marketing content with no eligibility attached.
  final OfferAudience? audience;

  bool get isStudentOffer => audience == OfferAudience.students;
}
