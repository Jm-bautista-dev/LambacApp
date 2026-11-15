/// Data Transfer Object for Requesting Registration OTP
class RequestRegisterOtpRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;

  const RequestRegisterOtpRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
        'phone_number': phoneNumber!.trim(),
    };
  }
}

/// Response returned after registration OTP is generated and dispatched via email
class RequestRegisterOtpResponse {
  final String email;
  final String maskedEmail;
  final int expiresInSeconds;
  final int resendCooldownSeconds;
  final String message;
  final String? debugOtp;

  const RequestRegisterOtpResponse({
    required this.email,
    required this.maskedEmail,
    required this.expiresInSeconds,
    required this.resendCooldownSeconds,
    required this.message,
    this.debugOtp,
  });

  factory RequestRegisterOtpResponse.fromJson(Map<String, dynamic> json) {
    return RequestRegisterOtpResponse(
      email: json['email'] as String? ?? '',
      maskedEmail: json['masked_email'] as String? ?? '',
      expiresInSeconds: json['expires_in_seconds'] as int? ?? 300,
      resendCooldownSeconds: json['resend_cooldown_seconds'] as int? ?? 45,
      message: json['message'] as String? ?? 'Verification code sent to your email.',
      debugOtp: json['debug_otp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'masked_email': maskedEmail,
      'expires_in_seconds': expiresInSeconds,
      'resend_cooldown_seconds': resendCooldownSeconds,
      'message': message,
      if (debugOtp != null) 'debug_otp': debugOtp,
    };
  }
}
