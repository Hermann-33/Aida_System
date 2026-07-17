/// Whether a member is entitled to student-only offers.
///
/// A customer self-declares at registration and lands in [pending]. Only an
/// admin moves them to [verified]. PRD §11.3 requires that unverified members
/// must not *see* student offers, not merely be blocked from applying them.
enum StudentStatus {
  /// Not a student, or never claimed to be.
  none,

  /// Self-declared, awaiting admin verification. No student benefits yet.
  pending,

  /// Verified by an admin. Student offers are visible.
  verified,
}

/// A loyalty member.
///
/// Balances are read-only here. The client never computes them — the server
/// does (PRD §16.5). See [Points] and [StampCard].
class Member {
  const Member({
    required this.id,
    required this.memberCode,
    required this.name,
    required this.email,
    required this.studentStatus,
    this.phone,
    this.birthday,
    this.tierName,
    this.studentOrEmployeeId,
  });

  final String id;

  /// The permanent identifier encoded into the membership QR. Immutable after
  /// registration, which is what lets the QR render offline (spec §2.3).
  final String memberCode;

  final String name;
  final String email;
  final StudentStatus studentStatus;
  final String? phone;
  final DateTime? birthday;

  /// Cosmetic in v1. Tiers (CUS-12) are deferred, so nothing computes this —
  /// it is displayed because the approved design shows it.
  final String? tierName;

  /// City U student ID, or staff/employee ID for a non-student member. Not
  /// in the original CUS-21 field list (name, phone, birthday) — added on
  /// client request. Self-reported by the member, same as every other
  /// editable field here; nothing verifies it against a real campus system.
  final String? studentOrEmployeeId;

  bool get isVerifiedStudent => studentStatus == StudentStatus.verified;

  /// First letter, for the avatar. Falls back to `?` rather than crashing on
  /// an empty name.
  String get initial => name.isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// For the Edit Profile form: applies the customer's own changes to the
  /// editable fields, leaving everything else (id, memberCode, email,
  /// studentStatus, tierName) untouched — those aren't self-editable.
  Member copyWith({
    String? name,
    String? phone,
    DateTime? birthday,
    String? studentOrEmployeeId,
  }) {
    return Member(
      id: id,
      memberCode: memberCode,
      name: name ?? this.name,
      email: email,
      studentStatus: studentStatus,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      tierName: tierName,
      studentOrEmployeeId: studentOrEmployeeId ?? this.studentOrEmployeeId,
    );
  }
}
