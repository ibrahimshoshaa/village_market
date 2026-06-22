import 'package:meta/meta.dart';

import '../error/failures.dart';

/// Lightweight Result type, avoiding a dependency on fpdart/dartz for a
/// single sealed-class pattern. Repository methods return
/// Result&lt;T, Failure&gt; instead of throwing, per Phase 1.1's Clean
/// Architecture conventions.
@immutable
sealed class Result<S, F> {
  const Result();

  factory Result.success(S value) = Success<S, F>;
  factory Result.failure(F failure) = Failed<S, F>;

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failed<S, F>;

  T fold<T>(T Function(F failure) onFailure, T Function(S value) onSuccess) {
    final self = this;
    if (self is Success<S, F>) return onSuccess(self.value);
    if (self is Failed<S, F>) return onFailure(self.failure);
    throw StateError('Unreachable');
  }

  S? get valueOrNull => switch (this) {
        Success<S, F>(value: final v) => v,
        Failed<S, F>() => null,
      };
}

final class Success<S, F> extends Result<S, F> {
  final S value;
  const Success(this.value);
}

final class Failed<S, F> extends Result<S, F> {
  final F failure;
  const Failed(this.failure);
}

/// Convenience alias used throughout repository interfaces, e.g.
/// `Future<AppResult<AppUser>> getCurrentUser()`.
typedef AppResult<T> = Result<T, Failure>;
