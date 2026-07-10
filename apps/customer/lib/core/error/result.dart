import 'failures.dart';

/// The outcome of any operation that can fail.
///
/// Repositories return this rather than throwing, so callers cannot forget
/// that a failure path exists — the type system will not let them.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
