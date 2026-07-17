/// Typed failures. Raw exceptions must never reach a widget.
///
/// Each variant exists because it demands a distinct user-facing response,
/// not merely a distinct log line.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// Network unreachable or timed out. Render cached data with a stale badge.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No connection']);
}

/// Token rejected. Sign out, wipe the cache, return to login.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expired']);
}

/// The server's balance is lower than the client believed.
///
/// The client never asserts a balance, so this is an expected outcome of a
/// redeem attempt, not an exceptional one. Carries the true balance so the
/// UI can explain the discrepancy rather than merely refusing.
class InsufficientPointsFailure extends Failure {
  const InsufficientPointsFailure({
    required this.actualPoints,
    required this.requiredPoints,
  }) : super('Insufficient points');

  final int actualPoints;
  final int requiredPoints;
}

/// Voucher lapsed before use. Remove it from the wallet and say so.
///
/// Points are not refunded on expiry — see design spec §2.2.
class VoucherExpiredFailure extends Failure {
  const VoucherExpiredFailure([super.message = 'This voucher has expired']);
}

/// Field-level rejection. [fieldErrors] maps a form field name to its problem.
class ValidationFailure extends Failure {
  const ValidationFailure(
    this.fieldErrors, [
    super.message = 'Check your details',
  ]);

  final Map<String, String> fieldErrors;
}

/// The server erred. Offer a retry.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong']);
}
