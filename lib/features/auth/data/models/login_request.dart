/// Data Transfer Object for User Login
class LoginRequest {
  final String email;
  final String password;
  final String? deviceId;

  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      if (deviceId != null) 'device_id': deviceId,
    };
  }
}
