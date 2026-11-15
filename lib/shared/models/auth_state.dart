import 'package:equatable/equatable.dart';
import '../../core/errors/app_failure.dart';
import 'user_model.dart';

/// Status of the user's authentication
enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  sessionExpired,
  failure,
}

/// Comprehensive Authentication State Container
class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final AppFailure? failure;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.failure,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        token = null,
        failure = null;

  const AuthState.authenticating()
      : status = AuthStatus.authenticating,
        user = null,
        token = null,
        failure = null;

  const AuthState.authenticated({
    required UserModel user,
    required String token,
  })  : status = AuthStatus.authenticated,
        user = user,
        token = token,
        failure = null;

  const AuthState.unauthenticated({
    AppFailure? failure,
  })  : status = AuthStatus.unauthenticated,
        user = null,
        token = null,
        failure = failure;

  const AuthState.sessionExpired()
      : status = AuthStatus.sessionExpired,
        user = null,
        token = null,
        failure = const UnauthorizedFailure(
          message: 'Your session has expired. Please log in again to continue.',
        );

  const AuthState.failure(AppFailure failure)
      : status = AuthStatus.failure,
        user = null,
        token = null,
        failure = failure;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isCustomerAuthenticated => isAuthenticated && user != null && !user!.isGuest;
  bool get isGuest => user == null || (user?.isGuest ?? true);
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isSessionExpired => status == AuthStatus.sessionExpired;
  bool get isInitial => status == AuthStatus.initial;
  bool get hasFailure => failure != null;
  bool get mustChangePassword => isAuthenticated && (user?.mustChangePassword ?? false);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    AppFailure? failure,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, user, token, failure];
}
