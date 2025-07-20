import 'package:flutter/foundation.dart';
import 'failures.dart';

/// Result type for handling success and failure cases
/// 
/// This implements the functional programming Result pattern to handle
/// errors without throwing exceptions, making error handling explicit
/// and testable.
@immutable
sealed class Result<T> {
  const Result();

  /// Creates a success result
  const factory Result.success(T value) = Success<T>;

  /// Creates a failure result
  const factory Result.failure(Failure failure) = Failed<T>;

  /// Checks if the result is a success
  bool get isSuccess => this is Success<T>;

  /// Checks if the result is a failure
  bool get isFailure => this is Failed<T>;

  /// Gets the value if success, null otherwise
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failed() => null,
      };

  /// Gets the failure if failure, null otherwise
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Failed(:final failure) => failure,
      };

  /// Folds the result into a single value
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failed(:final failure) => onFailure(failure),
    };
  }

  /// Maps the success value
  Result<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      Success(:final value) => Result.success(mapper(value)),
      Failed(:final failure) => Result.failure(failure),
    };
  }

  /// Maps the failure
  Result<T> mapFailure(Failure Function(Failure failure) mapper) {
    return switch (this) {
      Success() => this,
      Failed(:final failure) => Result.failure(mapper(failure)),
    };
  }

  /// Flat maps the success value
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return switch (this) {
      Success(:final value) => mapper(value),
      Failed(:final failure) => Result.failure(failure),
    };
  }

  /// Gets the value or throws the failure
  T getOrThrow() {
    return switch (this) {
      Success(:final value) => value,
      Failed(:final failure) => throw failure,
    };
  }

  /// Gets the value or returns the default
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success(:final value) => value,
      Failed() => defaultValue,
    };
  }

  /// Performs an action if success
  Result<T> onSuccess(void Function(T value) action) {
    if (this is Success<T>) {
      action((this as Success<T>).value);
    }
    return this;
  }

  /// Performs an action if failure
  Result<T> onFailure(void Function(Failure failure) action) {
    if (this is Failed<T>) {
      action((this as Failed<T>).failure);
    }
    return this;
  }
}

/// Success case of Result
@immutable
final class Success<T> extends Result<T> {
  final T value;
  
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Failure case of Result
@immutable
final class Failed<T> extends Result<T> {
  final Failure failure;

  const Failed(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failed<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failed($failure)';
}

/// Extension for async Result operations
extension ResultFutureExtensions<T> on Future<Result<T>> {
  /// Maps the success value asynchronously
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) mapper) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => Result.success(await mapper(value)),
      Failed(:final failure) => Result.failure(failure),
    };
  }

  /// Flat maps the success value asynchronously
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) mapper,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => mapper(value),
      Failed(:final failure) => Result.failure(failure),
    };
  }
}