/// Data Transfer Object for User Registration
class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? verificationToken;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.verificationToken,
  });

  RegisterRequest copyWith({
    String? fullName,
    String? email,
    String? password,
    String? phoneNumber,
    String? verificationToken,
  }) {
    return RegisterRequest(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationToken: verificationToken ?? this.verificationToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
        'phone_number': phoneNumber!.trim(),
      if (verificationToken != null && verificationToken!.trim().isNotEmpty)
        'verification_token': verificationToken!.trim(),
    };
  }
}

