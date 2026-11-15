/// Data Transfer Object for Verifying Registration OTP
class VerifyRegisterOtpRequest {
  final String email;
  final String otp;

  const VerifyRegisterOtpRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
    };
  }
}

/// Response returned upon successful OTP verification
class VerifyRegisterOtpResponse {
  final String email;
  final String verificationToken;
  final String message;

  const VerifyRegisterOtpResponse({
    required this.email,
    required this.verificationToken,
    required this.message,
  });

  factory VerifyRegisterOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyRegisterOtpResponse(
      email: json['email'] as String? ?? '',
      verificationToken: json['verification_token'] as String? ?? '',
      message: json['message'] as String? ?? 'Email successfully verified.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'verification_token': verificationToken,
      'message': message,
    };
  }
}
