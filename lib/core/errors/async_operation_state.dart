import 'package:equatable/equatable.dart';
import 'app_failure.dart';

/// Phase of an asynchronous mutation or query
enum OperationPhase {
  initial,
  loading,
  success,
  failure,
  empty,
}

/// Standardized immutable state container for any asynchronous operation
class AsyncOperationState<T> extends Equatable {
  final OperationPhase phase;
  final T? data;
  final AppFailure? failure;
  final bool isPendingSync;

  /// 1. Initial State
  const AsyncOperationState.initial()
      : phase = OperationPhase.initial,
        data = null,
        failure = null,
        isPendingSync = false;

  /// 2. Loading / Submitting State (preserves previous data if available during refresh)
  const AsyncOperationState.loading({T? previousData, this.isPendingSync = false})
      : phase = OperationPhase.loading,
        data = previousData,
        failure = null;

  /// 3. Success State (Authoritatively completed with payload [data])
  const AsyncOperationState.success(this.data, {this.isPendingSync = false})
      : phase = OperationPhase.success,
        failure = null;

  /// 4. Failure State
  const AsyncOperationState.failure(this.failure, {T? previousData})
      : phase = OperationPhase.failure,
        data = previousData,
        isPendingSync = false;

  /// 5. Empty State
  const AsyncOperationState.empty()
      : phase = OperationPhase.empty,
        data = null,
        failure = null,
        isPendingSync = false;

  // Convenient Query Getters
  bool get isInitial => phase == OperationPhase.initial;
  bool get isLoading => phase == OperationPhase.loading;
  bool get isSuccess => phase == OperationPhase.success;
  bool get isFailure => phase == OperationPhase.failure;
  bool get isEmpty => phase == OperationPhase.empty;

  /// Distinguishes recoverable failures from permanent/critical ones
  bool get isRecoverableFailure => isFailure && (failure?.isRecoverable ?? false);
  bool get isValidationFailure => isFailure && failure is ValidationFailure;
  bool get canRetry => isFailure && (failure?.canRetry ?? false);

  T? get dataOrNull => data;
  AppFailure? get failureOrNull => failure;

  /// Pattern-matching callback handler
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
    required R Function() empty,
  }) {
    return switch (phase) {
      OperationPhase.initial => initial(),
      OperationPhase.loading => loading(data),
      OperationPhase.success => success(data as T),
      OperationPhase.failure => failure(this.failure!),
      OperationPhase.empty => empty(),
    };
  }

  /// Pattern-matching with fallbacks
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? success,
    R Function(AppFailure failure)? failure,
    R Function()? empty,
    required R Function() orElse,
  }) {
    return switch (phase) {
      OperationPhase.initial => initial?.call() ?? orElse(),
      OperationPhase.loading => loading?.call(data) ?? orElse(),
      OperationPhase.success => success?.call(data as T) ?? orElse(),
      OperationPhase.failure => failure?.call(this.failure!) ?? orElse(),
      OperationPhase.empty => empty?.call() ?? orElse(),
    };
  }

  @override
  List<Object?> get props => [phase, data, failure, isPendingSync];
}

/// Concurrency Guard preventing duplicate asynchronous submissions (e.g. double taps)
class OperationGate {
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  /// Executes [action] only if no other operation is currently in flight.
  /// Returns null if blocked by concurrent execution.
  Future<R?> run<R>(Future<R> Function() action) async {
    if (_isProcessing) return null;
    _isProcessing = true;
    try {
      return await action();
    } finally {
      _isProcessing = false;
    }
  }

  void reset() {
    _isProcessing = false;
  }
}
