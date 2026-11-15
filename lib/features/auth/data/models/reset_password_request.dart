/// Payload DTO for resetting password with token
class ResetPasswordRequest {
  final String email;
  final String resetToken;
  final String newPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.resetToken,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'reset_token': resetToken.trim(),
      'new_password': newPassword,
    };
  }
}
