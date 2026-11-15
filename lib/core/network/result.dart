import '../errors/app_failure.dart';

/// A type-safe Result container representing either a Success with data [T],
/// or a Failure with an [AppFailure].
sealed class Result<T, E extends AppFailure> {
  const Result();

  /// Creates a successful Result
  const factory Result.success(T data) = Success<T, E>;

  /// Creates a failed Result
  const factory Result.failure(E failure) = Failure<T, E>;

  /// Returns true if this is a Success
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this is a Failure
  bool get isFailure => this is Failure<T, E>;

  /// Returns data if Success, or null if Failure
  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  /// Returns failure if Failure, or null if Success
  E? get failureOrNull => switch (this) {
        Success() => null,
        Failure(failure: final f) => f,
      };

  /// Pattern matching handler
  R when<R>({
    required R Function(T data) success,
    required R Function(E failure) failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      Failure(failure: final f) => failure(f),
    };
  }

  /// Maps the success data to a new type
  Result<R, E> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final d) => Result.success(transform(d)),
      Failure(failure: final f) => Result.failure(f),
    };
  }

  /// Async mapping handler
  Future<Result<R, E>> asyncMap<R>(Future<R> Function(T data) transform) async {
    return switch (this) {
      Success(data: final d) => Result.success(await transform(d)),
      Failure(failure: final f) => Result.failure(f),
    };
  }
}

/// Concrete Success implementation
final class Success<T, E extends AppFailure> extends Result<T, E> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T, E> && other.data == data);

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Result.success($data)';
}

/// Concrete Failure implementation
final class Failure<T, E extends AppFailure> extends Result<T, E> {
  final E failure;
  const Failure(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Failure<T, E> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Result.failure($failure)';
}
