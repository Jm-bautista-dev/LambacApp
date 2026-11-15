import 'package:equatable/equatable.dart';
import '../../../../shared/models/user_model.dart';

/// Authentication Response Data Model containing Access Token, Refresh Token, and User payload
class AuthResponseModel extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 86400,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return AuthResponseModel(
      accessToken: (json['access_token'] ?? json['token'] ?? '').toString(),
      refreshToken: json['refresh_token']?.toString(),
      tokenType: (json['token_type'] ?? 'Bearer').toString(),
      expiresIn: (json['expires_in'] ?? 86400) as int,
      user: UserModel.fromJson(userData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresIn, user];
}
