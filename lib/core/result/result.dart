import 'package:meta/meta.dart';
import '../error/failures.dart';

@immutable
sealed class Result<S, F> {
  const Result();

  const factory Result.success(S value) = Success<S, F>;
  const factory Result.failure(F failure) = Failed<S, F>;

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

typedef AppResult<T> = Result<T, Failure>;
